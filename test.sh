#!/bin/bash

# test.sh - Comprehensive test script for Potions
# Author: Henrique A. Lavezzo (Rynaro)
#
# This script validates Potions installation, configuration, and idempotency

set -eo pipefail

# Enable verbose mode when DEBUG is set
if [ "${DEBUG:-}" = "1" ]; then
  set -x
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if terminal supports colors
if [ -t 1 ]; then
  HAS_COLOR=true
else
  HAS_COLOR=false
fi

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging functions
log_info() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${CYAN}${BOLD}⟹${NC} ${WHITE}$1${NC}"
  else
    echo "==> $1"
  fi
}

log_success() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${GREEN}${BOLD}✓${NC} ${GREEN}$1${NC}"
  else
    echo "[PASS] $1"
  fi
}

log_failure() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${RED}${BOLD}✗${NC} ${RED}$1${NC}"
  else
    echo "[FAIL] $1"
  fi
}

log_skip() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${YELLOW}${BOLD}⊘${NC} ${YELLOW}$1${NC}"
  else
    echo "[SKIP] $1"
  fi
}

log_step() {
  if [ "$HAS_COLOR" = true ]; then
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  else
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
  fi
}

# Test assertion functions
assert_file_exists() {
  local file="$1"
  local description="${2:-File exists: $file}"

  if [ -f "$file" ]; then
    log_success "$description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    log_failure "$description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1"
  local description="${2:-Directory exists: $dir}"

  if [ -d "$dir" ]; then
    log_success "$description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    log_failure "$description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local description="${3:-File contains pattern}"

  if [ -f "$file" ] && grep -q "$pattern" "$file" 2>/dev/null; then
    log_success "$description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    log_failure "$description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_command_exists() {
  local cmd="$1"
  local description="${2:-Command exists: $cmd}"

  if command -v "$cmd" &> /dev/null; then
    log_success "$description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    log_failure "$description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_syntax_valid() {
  local file="$1"
  local description="${2:-Syntax valid: $file}"

  if bash -n "$file" 2>/dev/null; then
    log_success "$description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    log_failure "$description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test categories
test_repo_structure() {
  log_step "Repository Structure Tests"

  # Core files
  assert_file_exists "$SCRIPT_DIR/install.sh" "install.sh exists"
  assert_file_exists "$SCRIPT_DIR/upgrade.sh" "upgrade.sh exists"
  assert_file_exists "$SCRIPT_DIR/uninstall.sh" "uninstall.sh exists"
  assert_file_exists "$SCRIPT_DIR/migrate.sh" "migrate.sh exists"
  assert_file_exists "$SCRIPT_DIR/drink.sh" "drink.sh exists"
  assert_file_exists "$SCRIPT_DIR/.version" ".version exists"

  # Potions directory
  assert_dir_exists "$SCRIPT_DIR/.potions" ".potions directory exists"
  assert_file_exists "$SCRIPT_DIR/.potions/.zshrc" ".zshrc exists"
  assert_file_exists "$SCRIPT_DIR/.potions/.zsh_plugins.txt" ".zsh_plugins.txt exists"
  assert_file_exists "$SCRIPT_DIR/.potions/KEYMAPS.md" "KEYMAPS.md exists"

  # Config directory
  assert_dir_exists "$SCRIPT_DIR/.potions/config" "config directory exists"
  assert_file_exists "$SCRIPT_DIR/.potions/config/aliases.zsh" "config/aliases.zsh exists"
  assert_file_exists "$SCRIPT_DIR/.potions/config/secure.zsh" "config/secure.zsh exists"
  assert_file_exists "$SCRIPT_DIR/.potions/config/local.zsh" "config/local.zsh exists"

  # Neovim
  assert_dir_exists "$SCRIPT_DIR/.potions/nvim" "nvim directory exists"
  assert_file_exists "$SCRIPT_DIR/.potions/nvim/init.vim" "init.vim exists"
  assert_file_exists "$SCRIPT_DIR/.potions/nvim/user.vim" "user.vim exists"

  # Tmux
  assert_dir_exists "$SCRIPT_DIR/.potions/tmux" "tmux directory exists"
  assert_file_exists "$SCRIPT_DIR/.potions/tmux/tmux.conf" "tmux.conf exists"
  assert_file_exists "$SCRIPT_DIR/.potions/tmux/user.conf" "user.conf exists"

  # Terminal setup
  assert_dir_exists "$SCRIPT_DIR/.potions/terminal-setup" "terminal-setup directory exists"
  assert_file_exists "$SCRIPT_DIR/.potions/terminal-setup/TERMINAL_SETUP.md" "TERMINAL_SETUP.md exists"

  # Packages
  assert_dir_exists "$SCRIPT_DIR/packages" "packages directory exists"
  assert_file_exists "$SCRIPT_DIR/packages/accessories.sh" "accessories.sh exists"
  assert_dir_exists "$SCRIPT_DIR/packages/common" "packages/common exists"
  assert_dir_exists "$SCRIPT_DIR/packages/macos" "packages/macos exists"
  assert_dir_exists "$SCRIPT_DIR/packages/debian" "packages/debian exists"
  assert_dir_exists "$SCRIPT_DIR/packages/fedora" "packages/fedora exists"
}

test_bash_syntax() {
  log_step "Bash Syntax Validation"

  # Core scripts
  assert_syntax_valid "$SCRIPT_DIR/install.sh" "install.sh syntax"
  assert_syntax_valid "$SCRIPT_DIR/upgrade.sh" "upgrade.sh syntax"
  assert_syntax_valid "$SCRIPT_DIR/uninstall.sh" "uninstall.sh syntax"
  assert_syntax_valid "$SCRIPT_DIR/migrate.sh" "migrate.sh syntax"
  assert_syntax_valid "$SCRIPT_DIR/drink.sh" "drink.sh syntax"
  assert_syntax_valid "$SCRIPT_DIR/packages/accessories.sh" "accessories.sh syntax"

  # Common packages
  for script in "$SCRIPT_DIR"/packages/common/*.sh; do
    if [ -f "$script" ]; then
      local name=$(basename "$script")
      assert_syntax_valid "$script" "packages/common/$name syntax"
    fi
  done

  # Platform packages (spot check)
  for platform in macos debian fedora wsl termux; do
    if [ -d "$SCRIPT_DIR/packages/$platform" ]; then
      for script in "$SCRIPT_DIR/packages/$platform"/*.sh; do
        if [ -f "$script" ]; then
          local name=$(basename "$script")
          assert_syntax_valid "$script" "packages/$platform/$name syntax"
        fi
      done
    fi
  done
}

test_config_validity() {
  log_step "Configuration File Validation"

  # Check .zshrc sources safe_source
  assert_file_contains "$SCRIPT_DIR/.potions/.zshrc" "safe_source" ".zshrc uses safe_source"

  # Check .zshrc sources new config files
  assert_file_contains "$SCRIPT_DIR/.potions/.zshrc" "config/aliases.zsh" ".zshrc sources config/aliases.zsh"
  assert_file_contains "$SCRIPT_DIR/.potions/.zshrc" "config/secure.zsh" ".zshrc sources config/secure.zsh"
  assert_file_contains "$SCRIPT_DIR/.potions/.zshrc" "config/local.zsh" ".zshrc sources config/local.zsh"

  # Check tmux.conf has user extension
  assert_file_contains "$SCRIPT_DIR/.potions/tmux/tmux.conf" "user.conf" "tmux.conf sources user.conf"

  # Check init.vim has user extension
  assert_file_contains "$SCRIPT_DIR/.potions/nvim/init.vim" "user.vim" "init.vim sources user.vim"

  # Check no conflicting keybindings in tmux
  if grep -q "bind -n C-n" "$SCRIPT_DIR/.potions/tmux/tmux.conf" 2>/dev/null; then
    log_failure "tmux.conf still has conflicting C-n binding"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "tmux.conf has no conflicting C-n binding"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  if grep -q "bind -n C-p" "$SCRIPT_DIR/.potions/tmux/tmux.conf" 2>/dev/null; then
    log_failure "tmux.conf still has conflicting C-p binding"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "tmux.conf has no conflicting C-p binding"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi
}

test_install_script() {
  log_step "Install Script Tests"

  # Check install.sh has preflight_checks function
  assert_file_contains "$SCRIPT_DIR/install.sh" "preflight_checks" "install.sh has preflight_checks"

  # Check package order (curl before git)
  if grep -A20 "local packages=" "$SCRIPT_DIR/install.sh" | grep -q "'curl'" && \
     grep -A20 "local packages=" "$SCRIPT_DIR/install.sh" | grep -q "'git'"; then
    # Verify curl comes before git
    local curl_line=$(grep -n "'curl'" "$SCRIPT_DIR/install.sh" | head -1 | cut -d: -f1)
    local git_line=$(grep -n "'git'" "$SCRIPT_DIR/install.sh" | head -1 | cut -d: -f1)
    if [ "$curl_line" -lt "$git_line" ]; then
      log_success "Package order: curl before git"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "Package order: curl should come before git"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    log_skip "Could not verify package order"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
  fi
}

test_common_packages() {
  log_step "Common Package Tests"

  # Check tmux.sh is idempotent
  assert_file_contains "$SCRIPT_DIR/packages/common/tmux.sh" "if \[ -d" "tmux.sh has idempotent check"

  # Check zsh.sh uses REPO_ROOT
  assert_file_contains "$SCRIPT_DIR/packages/common/zsh.sh" "REPO_ROOT" "zsh.sh uses REPO_ROOT"
}

test_upgrade_script() {
  log_step "Upgrade Script Tests"

  # Check upgrade.sh preserves new config files
  assert_file_contains "$SCRIPT_DIR/upgrade.sh" "config/aliases.zsh" "upgrade.sh preserves config/aliases.zsh"
  assert_file_contains "$SCRIPT_DIR/upgrade.sh" "nvim/user.vim" "upgrade.sh preserves nvim/user.vim"
  assert_file_contains "$SCRIPT_DIR/upgrade.sh" "tmux/user.conf" "upgrade.sh preserves tmux/user.conf"
}

test_documentation() {
  log_step "Documentation Tests"

  assert_file_exists "$SCRIPT_DIR/README.md" "README.md exists"
  assert_file_exists "$SCRIPT_DIR/AGENTS.md" "AGENTS.md exists"

  # Check README mentions new config structure
  assert_file_contains "$SCRIPT_DIR/README.md" "config/aliases.zsh" "README.md documents new config structure"

  # Check AGENTS.md has key sections
  assert_file_contains "$SCRIPT_DIR/AGENTS.md" "Security-First" "AGENTS.md has security section"
  assert_file_contains "$SCRIPT_DIR/AGENTS.md" "Idempotency" "AGENTS.md documents idempotency"
}

test_platform_detection() {
  log_step "Platform Detection Tests"

  # Source accessories.sh and test detection
  source "$SCRIPT_DIR/packages/accessories.sh" 2>/dev/null || true

  if type is_macos &>/dev/null; then
    log_success "is_macos function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "is_macos function not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  if type is_linux &>/dev/null; then
    log_success "is_linux function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "is_linux function not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  if type is_wsl &>/dev/null; then
    log_success "is_wsl function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "is_wsl function not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  if type is_termux &>/dev/null; then
    log_success "is_termux function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "is_termux function not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  if type is_fedora &>/dev/null; then
    log_success "is_fedora function exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "is_fedora function not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_install_simulation() {
  log_step "Install Simulation (Test Mode)"

  # Run install.sh in test mode
  log_info "Running install.sh --test..."

  local output
  if output=$("$SCRIPT_DIR/install.sh" --test 2>&1); then
    log_success "install.sh --test completed successfully"
    TESTS_PASSED=$((TESTS_PASSED + 1))

    # Check test mode message in output
    if echo "$output" | grep -q "TEST MODE"; then
      log_success "Test mode detected in output"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "Test mode message not found in output"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    log_failure "install.sh --test failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Print summary
print_summary() {
  echo ""
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Test Summary${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "  ${RED}Failed:${NC}  $TESTS_FAILED"
    echo -e "  ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    echo ""
    local total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
    echo -e "  ${WHITE}Total:${NC}   $total"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
      echo -e "${GREEN}${BOLD}  ✓ All tests passed!${NC}"
    else
      echo -e "${RED}${BOLD}  ✗ Some tests failed${NC}"
    fi
    echo ""
  else
    echo "========================================"
    echo "  Test Summary"
    echo "========================================"
    echo ""
    echo "  Passed:  $TESTS_PASSED"
    echo "  Failed:  $TESTS_FAILED"
    echo "  Skipped: $TESTS_SKIPPED"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
      echo "  All tests passed!"
    else
      echo "  Some tests failed"
    fi
    echo ""
  fi

  # Return exit code based on failures
  return $TESTS_FAILED
}

# Main function
main() {
  echo ""
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${CYAN}${BOLD}  Potions Test Suite${NC}"
  else
    echo "  Potions Test Suite"
  fi

  # Run test categories
  test_repo_structure
  test_bash_syntax
  test_config_validity
  test_install_script
  test_common_packages
  test_upgrade_script
  test_documentation
  test_platform_detection

  # Run install simulation unless --no-simulate flag
  if [[ "$1" != "--no-simulate" ]]; then
    test_install_simulation
  else
    log_skip "Install simulation skipped (--no-simulate)"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
  fi

  # Print summary and exit
  print_summary
  exit $?
}

# Run main
main "$@"
