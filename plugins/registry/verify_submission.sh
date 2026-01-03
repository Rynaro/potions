#!/bin/bash

# Potions Plugin Submission Verification Script
# Used by maintainers to verify plugin submissions before adding to registry

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

source "$REPO_ROOT/packages/accessories.sh"
source "$PLUGINS_DIR/core/manifest.sh"
source "$PLUGINS_DIR/core/scanner.sh"
source "$PLUGINS_DIR/core/security.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
  echo -e "${BLUE}${BOLD}$1${NC}"
}

print_pass() {
  echo -e "  ${GREEN}✓${NC} $1"
}

print_fail() {
  echo -e "  ${RED}✗${NC} $1"
}

print_warn() {
  echo -e "  ${YELLOW}⚠${NC} $1"
}

print_info() {
  echo -e "  ${BLUE}ℹ${NC} $1"
}

# Verify a plugin submission
verify_submission() {
  local repo="$1"
  local passed=0
  local failed=0
  local warnings=0
  
  if [ -z "$repo" ]; then
    echo "Usage: $0 <owner/repo>"
    echo ""
    echo "Example: $0 Rynaro/potions-docker"
    exit 1
  fi
  
  echo ""
  echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}  Potions Plugin Verification: $repo${NC}"
  echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  
  # Create temp directory
  local temp_dir
  temp_dir=$(mktemp -d)
  trap "rm -rf $temp_dir" EXIT
  
  # Clone repository
  print_header "1. Repository Access"
  echo ""
  
  if git clone --depth=1 "https://github.com/${repo}.git" "$temp_dir/plugin" 2>/dev/null; then
    print_pass "Repository cloned successfully"
    passed=$((passed + 1))
  else
    print_fail "Failed to clone repository"
    failed=$((failed + 1))
    echo ""
    echo "Verification cannot continue. Please check:"
    echo "  - Repository exists and is public"
    echo "  - URL format is correct (owner/repo)"
    exit 1
  fi
  
  local plugin_path="$temp_dir/plugin"
  echo ""
  
  # Check required files
  print_header "2. Required Files"
  echo ""
  
  local required_files=("plugin.potions.json" "install.sh" "uninstall.sh" "README.md")
  for file in "${required_files[@]}"; do
    if [ -f "$plugin_path/$file" ]; then
      print_pass "$file exists"
      passed=$((passed + 1))
    else
      print_fail "$file missing (REQUIRED)"
      failed=$((failed + 1))
    fi
  done
  
  # Check optional files
  local optional_files=("activate.sh" "deactivate.sh")
  for file in "${optional_files[@]}"; do
    if [ -f "$plugin_path/$file" ]; then
      print_pass "$file exists (optional)"
    else
      print_info "$file not present (optional)"
    fi
  done
  echo ""
  
  # Validate manifest
  print_header "3. Manifest Validation"
  echo ""
  
  local manifest="$plugin_path/plugin.potions.json"
  if [ -f "$manifest" ]; then
    # Check JSON structure
    if validate_manifest_json "$manifest" 2>/dev/null; then
      print_pass "Valid JSON structure"
      passed=$((passed + 1))
    else
      print_fail "Invalid JSON structure"
      failed=$((failed + 1))
    fi
    
    # Check required fields
    if validate_manifest_fields "$manifest" 2>/dev/null; then
      print_pass "All required fields present"
      passed=$((passed + 1))
    else
      print_fail "Missing required fields"
      failed=$((failed + 1))
    fi
    
    # Display manifest info
    local name version author
    name=$(parse_manifest_field "$manifest" "name")
    version=$(parse_manifest_field "$manifest" "version")
    author=$(parse_manifest_field "$manifest" "author")
    
    print_info "Name: $name"
    print_info "Version: $version"
    print_info "Author: $author"
  else
    print_fail "Manifest file not found"
    failed=$((failed + 1))
  fi
  echo ""
  
  # Bash syntax validation
  print_header "4. Script Syntax Validation"
  echo ""
  
  for script in "$plugin_path"/*.sh; do
    if [ -f "$script" ]; then
      local script_name
      script_name=$(basename "$script")
      if bash -n "$script" 2>/dev/null; then
        print_pass "$script_name - valid syntax"
        passed=$((passed + 1))
      else
        print_fail "$script_name - syntax error"
        failed=$((failed + 1))
      fi
    fi
  done
  
  if [ -d "$plugin_path/packages" ]; then
    for script in "$plugin_path/packages"/*.sh; do
      if [ -f "$script" ]; then
        local script_name
        script_name=$(basename "$script")
        if bash -n "$script" 2>/dev/null; then
          print_pass "packages/$script_name - valid syntax"
          passed=$((passed + 1))
        else
          print_fail "packages/$script_name - syntax error"
          failed=$((failed + 1))
        fi
      fi
    done
  fi
  echo ""
  
  # Security scan
  print_header "5. Security Scan"
  echo ""
  
  # Quick scan for critical issues
  local security_issues=0
  
  # Check for dangerous patterns
  local critical_patterns=(
    'curl.*|.*bash:Remote code execution'
    'wget.*|.*bash:Remote code execution'
    'eval.*\$:Code injection risk'
    'rm -rf /:Dangerous rm command'
  )
  
  for pattern_desc in "${critical_patterns[@]}"; do
    local pattern="${pattern_desc%%:*}"
    local desc="${pattern_desc##*:}"
    
    if grep -rqE "$pattern" "$plugin_path"/*.sh 2>/dev/null; then
      print_fail "CRITICAL: $desc"
      security_issues=$((security_issues + 1))
      failed=$((failed + 1))
    fi
  done
  
  if [ $security_issues -eq 0 ]; then
    print_pass "No critical security issues found"
    passed=$((passed + 1))
  fi
  
  # Check for medium-risk patterns
  if grep -rq 'sudo' "$plugin_path"/*.sh 2>/dev/null; then
    print_warn "Uses sudo - verify necessity"
    warnings=$((warnings + 1))
  fi
  
  if grep -rqE '\$[A-Za-z_]+[^"]' "$plugin_path"/*.sh 2>/dev/null; then
    print_warn "May have unquoted variables - verify safety"
    warnings=$((warnings + 1))
  fi
  echo ""
  
  # Check for license
  print_header "6. License Check"
  echo ""
  
  if [ -f "$plugin_path/LICENSE" ] || [ -f "$plugin_path/LICENSE.md" ]; then
    print_pass "License file present"
    passed=$((passed + 1))
  else
    local license
    license=$(parse_manifest_field "$manifest" "license")
    if [ -n "$license" ]; then
      print_pass "License declared in manifest: $license"
      passed=$((passed + 1))
    else
      print_warn "No license file or declaration found"
      warnings=$((warnings + 1))
    fi
  fi
  echo ""
  
  # Summary
  echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}  Verification Summary${NC}"
  echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "  ${GREEN}Passed:${NC}   $passed"
  echo -e "  ${RED}Failed:${NC}   $failed"
  echo -e "  ${YELLOW}Warnings:${NC} $warnings"
  echo ""
  
  if [ $failed -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✓ VERIFICATION PASSED${NC}"
    echo ""
    echo "  This plugin can be added to the verified registry."
    echo "  Run: ./update_registry.sh add $repo <version> \"<description>\""
    return 0
  else
    echo -e "  ${RED}${BOLD}✗ VERIFICATION FAILED${NC}"
    echo ""
    echo "  Please fix the issues above before resubmitting."
    return 1
  fi
}

verify_submission "$@"
