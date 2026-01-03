#!/bin/bash

# Potions Registry Update Script
# This script is used by maintainers to update the verified plugins registry

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

source "$REPO_ROOT/packages/accessories.sh"

REGISTRY_FILE="$SCRIPT_DIR/verified.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# Show usage
usage() {
  cat << EOF
Potions Registry Update Script

Usage: $0 <command> [options]

Commands:
  add <owner/repo> <version> <description>   Add a plugin to the registry
  remove <owner/repo>                        Remove a plugin from the registry
  list                                       List all verified plugins
  verify <owner/repo>                        Verify a plugin before adding
  update-checksums                           Update checksums for all plugins

Examples:
  $0 add Rynaro/potions-docker 1.0.0 "Docker integration for Potions"
  $0 remove Rynaro/potions-docker
  $0 verify Rynaro/potions-docker
  $0 list

Note: This script is intended for Potions maintainers only.
EOF
}

# Add a plugin to the registry
add_plugin() {
  local repo="$1"
  local version="$2"
  local description="$3"
  
  if [ -z "$repo" ] || [ -z "$version" ] || [ -z "$description" ]; then
    log_error "Usage: $0 add <owner/repo> <version> <description>"
    exit 1
  fi
  
  # Check if already exists
  if grep -q "^${repo}|" "$REGISTRY_FILE" 2>/dev/null; then
    log_error "Plugin already in registry: $repo"
    log_warning "Use 'remove' first if you want to update it"
    exit 1
  fi
  
  # Generate checksum URL
  local checksum_url="https://raw.githubusercontent.com/${repo}/main/.checksums"
  
  # Add to registry
  echo "${repo}|${version}|${checksum_url}|${description}" >> "$REGISTRY_FILE"
  
  log_success "Added to registry: $repo v$version"
  log_warning "Remember to commit and push the updated registry"
}

# Remove a plugin from the registry
remove_plugin() {
  local repo="$1"
  
  if [ -z "$repo" ]; then
    log_error "Usage: $0 remove <owner/repo>"
    exit 1
  fi
  
  if ! grep -q "^${repo}|" "$REGISTRY_FILE" 2>/dev/null; then
    log_error "Plugin not found in registry: $repo"
    exit 1
  fi
  
  # Create temp file without the plugin
  local temp_file
  temp_file=$(mktemp)
  grep -v "^${repo}|" "$REGISTRY_FILE" > "$temp_file"
  mv "$temp_file" "$REGISTRY_FILE"
  
  log_success "Removed from registry: $repo"
}

# List all verified plugins
list_plugins() {
  echo ""
  echo "Verified Potions Plugins"
  echo "========================"
  echo ""
  
  while IFS='|' read -r repo version checksum_url description; do
    # Skip comments and empty lines
    [[ "$repo" =~ ^# ]] && continue
    [ -z "$repo" ] && continue
    
    printf "%-40s v%-8s %s\n" "$repo" "$version" "$description"
  done < "$REGISTRY_FILE"
  
  echo ""
}

# Verify a plugin before adding
verify_plugin() {
  local repo="$1"
  
  if [ -z "$repo" ]; then
    log_error "Usage: $0 verify <owner/repo>"
    exit 1
  fi
  
  echo ""
  echo "Verifying plugin: $repo"
  echo "========================"
  
  # Create temp directory
  local temp_dir
  temp_dir=$(mktemp -d)
  trap "rm -rf $temp_dir" EXIT
  
  # Clone the repository
  log "Cloning repository..."
  if ! git clone --depth=1 "https://github.com/${repo}.git" "$temp_dir/plugin" 2>/dev/null; then
    log_error "Failed to clone repository: $repo"
    exit 1
  fi
  
  local plugin_path="$temp_dir/plugin"
  
  # Check for required files
  log "Checking required files..."
  local required_files=("plugin.potions.json" "install.sh" "README.md")
  for file in "${required_files[@]}"; do
    if [ -f "$plugin_path/$file" ]; then
      log_success "Found: $file"
    else
      log_error "Missing: $file"
    fi
  done
  
  # Run security scan
  log "Running security scan..."
  source "$PLUGINS_DIR/core/scanner.sh"
  if scan_plugin_scripts "$plugin_path"; then
    log_success "Security scan passed"
  else
    log_error "Security scan found issues"
  fi
  
  # Validate manifest
  log "Validating manifest..."
  source "$PLUGINS_DIR/core/manifest.sh"
  if validate_plugin "$plugin_path"; then
    log_success "Manifest validation passed"
  else
    log_error "Manifest validation failed"
  fi
  
  echo ""
  log_success "Verification complete. Review results above before adding to registry."
}

# Main command router
main() {
  local command="${1:-}"
  shift || true
  
  case "$command" in
    add)
      add_plugin "$@"
      ;;
    remove)
      remove_plugin "$@"
      ;;
    list)
      list_plugins
      ;;
    verify)
      verify_plugin "$@"
      ;;
    update-checksums)
      log_warning "Checksum update not yet implemented"
      ;;
    help|--help|-h|"")
      usage
      ;;
    *)
      log_error "Unknown command: $command"
      usage
      exit 1
      ;;
  esac
}

main "$@"
