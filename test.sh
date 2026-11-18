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

assert_no_local_outside_function() {
  local file="$1"
  local description="${2:-No local outside functions: $file}"

  local violations
  violations=$(awk '
    /[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\).*\{/ || /^function[[:space:]].*\{/ { depth++ }
    /^[[:space:]]*\}[[:space:]]*$/ { if (depth > 0) depth-- }
    /^[[:space:]]*local[[:space:]]/ { if (depth == 0) print NR ": " $0 }
  ' "$file")

  if [ -z "$violations" ]; then
    log_success "$description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    log_failure "$description"
    echo "$violations"
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

  # Zellij
  assert_dir_exists "$SCRIPT_DIR/.potions/zellij" "zellij directory exists"
  assert_file_exists "$SCRIPT_DIR/.potions/zellij/config.kdl" "config.kdl exists"
  assert_file_exists "$SCRIPT_DIR/.potions/zellij/user.kdl" "user.kdl exists"

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
  assert_syntax_valid "$SCRIPT_DIR/.potions/lib/door.sh" "door.sh syntax"
  assert_syntax_valid "$SCRIPT_DIR/.potions/lib/help.sh" "help.sh syntax"
  assert_syntax_valid "$SCRIPT_DIR/.potions/bin/potions" "potions CLI syntax"

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

test_no_local_outside_functions() {
  log_step "No local Outside Functions"

  # Core scripts
  assert_no_local_outside_function "$SCRIPT_DIR/drink.sh" "drink.sh: no local outside functions"
  assert_no_local_outside_function "$SCRIPT_DIR/install.sh" "install.sh: no local outside functions"
  assert_no_local_outside_function "$SCRIPT_DIR/upgrade.sh" "upgrade.sh: no local outside functions"
  assert_no_local_outside_function "$SCRIPT_DIR/plugins.sh" "plugins.sh: no local outside functions"
  assert_no_local_outside_function "$SCRIPT_DIR/packages/accessories.sh" "accessories.sh: no local outside functions"

  # Common packages
  for script in "$SCRIPT_DIR"/packages/common/*.sh; do
    if [ -f "$script" ]; then
      local name
      name=$(basename "$script")
      assert_no_local_outside_function "$script" "packages/common/$name: no local outside functions"
    fi
  done

  # Platform packages
  for platform in macos debian fedora wsl termux; do
    if [ -d "$SCRIPT_DIR/packages/$platform" ]; then
      for script in "$SCRIPT_DIR/packages/$platform"/*.sh; do
        if [ -f "$script" ]; then
          local name
          name=$(basename "$script")
          assert_no_local_outside_function "$script" "packages/$platform/$name: no local outside functions"
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

  # Check zellij config.kdl has tmux mode keybindings
  assert_file_contains "$SCRIPT_DIR/.potions/zellij/config.kdl" "Tmux" "config.kdl has tmux mode"

  # Check init.vim has user extension
  assert_file_contains "$SCRIPT_DIR/.potions/nvim/init.vim" "user.vim" "init.vim sources user.vim"
  assert_file_contains "$SCRIPT_DIR/.potions/nvim/init.vim" "xterm-ghostty" "init.vim enables termguicolors for xterm-ghostty"
  assert_file_contains "$SCRIPT_DIR/.potions/.zshrc" "CLAUDECODE" ".zshrc treats Claude Code as an AI editor"

  # Check zellij config uses clear-defaults
  assert_file_contains "$SCRIPT_DIR/.potions/zellij/config.kdl" "clear-defaults=true" "config.kdl uses clear-defaults"

  # Check alchemical session naming function exists
  assert_file_contains "$SCRIPT_DIR/.potions/.zshrc" "_potions_zellij_session_name" ".zshrc has alchemical session name function"

  # Check both word lists are present
  assert_file_contains "$SCRIPT_DIR/.potions/.zshrc" "_materials" ".zshrc has material/adjective word list"
  assert_file_contains "$SCRIPT_DIR/.potions/.zshrc" "_alchemical_words" ".zshrc has alchemical word list"

  # Check attach --create is used so dead sessions resurrect on reopen
  assert_file_contains "$SCRIPT_DIR/.potions/.zshrc" "attach --create" ".zshrc uses attach --create for session resurrection"

  # Functional: verify generated name matches the expected format and uses words from both lists
  if command -v zsh &>/dev/null; then
    _materials_list="golden silver copper iron obsidian azure crimson verdant pale molten frozen ethereal arcane vivid tarnished radiant"
    _alchemical_list="cauldron elixir alembic crucible tincture phlogiston azoth vitriol philosopher quintessence transmutation reagent catalyst retort sublimate athanor"

    _session_name_result=$(ZELLIJ=1 zsh -c '
      source "$1/.potions/.zshrc" 2>/dev/null || true
      _potions_zellij_session_name
    ' _ "$SCRIPT_DIR")

    if echo "$_session_name_result" | grep -qE '^[a-z]+-[a-z]+$'; then
      log_success "Session name format: two hyphen-joined lowercase words"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "Session name format invalid: '$_session_name_result'"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    _w1="${_session_name_result%%-*}"
    _w2="${_session_name_result##*-}"
    if echo " $_materials_list " | grep -q " $_w1 " && echo " $_alchemical_list " | grep -q " $_w2 "; then
      log_success "Session name words from expected lists: $_w1 / $_w2"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "Session name words not from expected lists: '$_session_name_result'"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Non-determinism: 50 invocations should produce >1 distinct name
    _distinct_count=$(ZELLIJ=1 zsh -c '
      source "$1/.potions/.zshrc" 2>/dev/null || true
      for _ in {1..50}; do _potions_zellij_session_name; done
    ' _ "$SCRIPT_DIR" | sort -u | wc -l | tr -d " ")
    if [ "$_distinct_count" -gt 1 ]; then
      log_success "Session name randomness: $_distinct_count distinct names across 50 calls"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "Session name not random: only $_distinct_count distinct names across 50 calls"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    log_success "Session naming functional test: skipped (zsh not in PATH)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  # Check hardcoded potions-main session name is gone
  if grep -q "potions-main" "$SCRIPT_DIR/.potions/.zshrc"; then
    log_failure ".zshrc must not contain hardcoded 'potions-main' session name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success ".zshrc does not contain hardcoded 'potions-main'"
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

  # Check zellij.sh exists and ensures directory
  assert_file_contains "$SCRIPT_DIR/packages/common/zellij.sh" "ensure_directory" "zellij.sh uses ensure_directory"

  # Check zsh.sh uses REPO_ROOT
  assert_file_contains "$SCRIPT_DIR/packages/common/zsh.sh" "REPO_ROOT" "zsh.sh uses REPO_ROOT"
}

test_upgrade_script() {
  log_step "Upgrade Script Tests"

  # Check upgrade.sh preserves new config files
  assert_file_contains "$SCRIPT_DIR/upgrade.sh" "config/aliases.zsh" "upgrade.sh preserves config/aliases.zsh"
  assert_file_contains "$SCRIPT_DIR/upgrade.sh" "nvim/user.vim" "upgrade.sh preserves nvim/user.vim"
  assert_file_contains "$SCRIPT_DIR/upgrade.sh" "zellij/user.kdl" "upgrade.sh preserves zellij/user.kdl"
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

test_termux_shell_setup() {
  log_step "Termux Shell Setup Tests"

  # Source accessories.sh to get is_termux function
  source "$SCRIPT_DIR/packages/accessories.sh" 2>/dev/null || true

  # Only run if in Termux environment
  if ! is_termux; then
    log_skip "Not running in Termux environment"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    return 0
  fi

  # ~/.termux/shell MUST be a symlink to the shell binary — Termux execs it
  # directly. A regular file (even with a valid path inside) makes Termux
  # unusable with "exec: Permission denied" on next launch.
  if [ -L "$HOME/.termux/shell" ]; then
    log_success "Termux shell configuration is a symlink"
    TESTS_PASSED=$((TESTS_PASSED + 1))

    local shell_target
    shell_target=$(readlink -f "$HOME/.termux/shell" 2>/dev/null || echo "")
    if [ -n "$shell_target" ] && [ -x "$shell_target" ]; then
      log_success "Termux shell symlink resolves to an executable ($shell_target)"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "Termux shell symlink does not resolve to an executable"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  elif [ -e "$HOME/.termux/shell" ]; then
    log_failure "Termux shell configuration exists but is not a symlink — this locks the user out of Termux"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_skip "Termux shell configuration not found (may be normal if zsh already default)"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
  fi
}

test_termux_package_manager() {
  log_step "Termux Package Manager Tests"

  # Source accessories.sh to get is_termux function
  source "$SCRIPT_DIR/packages/accessories.sh" 2>/dev/null || true

  # Only run if in Termux environment
  if ! is_termux; then
    log_skip "Not running in Termux environment"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    return 0
  fi

  # Check if pkg command exists
  if command -v pkg &> /dev/null; then
    log_success "pkg command available"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "pkg command not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

test_termux_environment() {
  log_step "Termux Environment Tests"

  # Source accessories.sh to get is_termux function
  source "$SCRIPT_DIR/packages/accessories.sh" 2>/dev/null || true

  # Only run if in Termux environment
  if ! is_termux; then
    log_skip "Not running in Termux environment"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    return 0
  fi

  # Check PREFIX environment variable
  if [ -n "$PREFIX" ]; then
    log_success "PREFIX environment variable is set"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    
    # Verify PREFIX/bin/termux-info exists
    if [ -x "$PREFIX/bin/termux-info" ]; then
      log_success "termux-info command exists and is executable"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "termux-info command not found or not executable"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    log_failure "PREFIX environment variable not set"
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

test_theme_system() {
  log_step "Theme System Tests (Phase 0)"

  local theme_lib="$SCRIPT_DIR/.potions/lib/theme"
  local theme_dir="$SCRIPT_DIR/.potions/themes/alchemists-orchid"

  # Structure
  assert_file_exists "$theme_lib/resolver.sh" "theme/resolver.sh exists"
  assert_file_exists "$theme_lib/state.sh" "theme/state.sh exists"
  assert_file_exists "$theme_lib/registry.sh" "theme/registry.sh exists"
  assert_file_exists "$theme_lib/generator.sh" "theme/generator.sh exists"
  assert_file_exists "$theme_lib/manager.sh" "theme/manager.sh exists"
  assert_file_exists "$SCRIPT_DIR/scripts/compile-themes.sh" "compile-themes.sh exists"
  assert_file_exists "$theme_dir/manifest" "orchid manifest exists"
  assert_file_exists "$theme_dir/base.tokens.json" "orchid base.tokens.json exists"
  assert_file_exists "$theme_dir/base.theme" "orchid base.theme exists"
  assert_file_exists "$theme_dir/dark.theme" "orchid dark.theme exists"
  assert_file_exists "$theme_dir/white.theme" "orchid white.theme exists"

  # Syntax + discipline for every theme module
  local f
  for f in "$theme_lib"/*.sh; do
    [ -f "$f" ] || continue
    assert_syntax_valid "$f" "theme/$(basename "$f") syntax"
    assert_no_local_outside_function "$f" "theme/$(basename "$f"): no local outside functions"
  done
  assert_syntax_valid "$SCRIPT_DIR/scripts/compile-themes.sh" "compile-themes.sh syntax"

  # manager.sh must be executable (the potions bin exec's it)
  if [ -x "$theme_lib/manager.sh" ]; then
    log_success "theme/manager.sh is executable"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "theme/manager.sh must be executable"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # potions bin wires the theme command
  assert_file_contains "$SCRIPT_DIR/.potions/bin/potions" "cmd_theme" "potions bin has cmd_theme"
  assert_file_contains "$SCRIPT_DIR/.potions/lib/theme/manager.sh" "owns the window background" "theme apply tells the truth about Ghostty reload"
  assert_file_contains "$SCRIPT_DIR/.potions/lib/theme/manager.sh" "owns pane colors until then" "theme apply tells the truth about Zellij pane colors"

  # VG-PAIR: every HEX token has a matching CTERM in each .theme
  local pair_ok=true tf hexes cterms
  for tf in "$theme_dir"/*.theme; do
    [ -f "$tf" ] || continue
    hexes=$(grep -Eo '^(COLOR|COMPONENT)_[A-Z0-9_]+_HEX' "$tf" | sed 's/_HEX$//' | sort)
    cterms=$(grep -Eo '^(COLOR|COMPONENT)_[A-Z0-9_]+_CTERM' "$tf" | sed 's/_CTERM$//' | sort)
    [ "$hexes" = "$cterms" ] || pair_ok=false
  done
  if [ "$pair_ok" = true ]; then
    log_success "VG-PAIR: every token has both HEX and CTERM"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "VG-PAIR: HEX/CTERM mismatch in a .theme file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Compiler drift gate: committed .theme files in sync with sources (needs jq)
  if command -v jq > /dev/null 2>&1; then
    if "$SCRIPT_DIR/scripts/compile-themes.sh" --check > /dev/null 2>&1; then
      log_success "compiler drift check: .theme files in sync with sources"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "compiler drift: run scripts/compile-themes.sh and commit"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    log_skip "compiler drift check skipped (jq not installed)"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
  fi

  local tmp
  tmp=$(mktemp -d)

  # Functional: variant overrides base; un-overridden base tokens stay shared.
  # (Light variants override brand accents/error for legibility, so secondary —
  # which no variant overrides — is the stable witness that inheritance works.)
  if REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash -c '
      . "'"$theme_lib"'/generator.sh"
      theme_generate "'"$theme_dir"'" dark "'"$tmp"'/dark" > /dev/null 2>&1 || exit 1
      theme_generate "'"$theme_dir"'" white "'"$tmp"'/white" > /dev/null 2>&1 || exit 1
      ds=$(grep "^COLOR_SURFACE_HEX=" "'"$tmp"'/dark/resolved.env")
      ws=$(grep "^COLOR_SURFACE_HEX=" "'"$tmp"'/white/resolved.env")
      de=$(grep "^COLOR_SECONDARY_HEX=" "'"$tmp"'/dark/resolved.env")
      we=$(grep "^COLOR_SECONDARY_HEX=" "'"$tmp"'/white/resolved.env")
      [ "$ds" != "$ws" ] && [ "$de" = "$we" ]
    '; then
    log_success "resolver: variant overrides base; base tokens shared"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "resolver: base/variant merge incorrect"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Security VG-BYO-SAFE: hostile theme rejected, never executed
  local pwn="$tmp/pwned" rc=0
  printf 'COLOR_X_HEX=$(touch %s)\n' "$pwn" > "$tmp/evil.theme"
  if REPO_ROOT="$SCRIPT_DIR" bash -c '
      . "'"$theme_lib"'/resolver.sh"
      theme_resolver_load "'"$tmp"'/evil.theme"
    ' > /dev/null 2>&1; then
    rc=0
  else
    rc=1
  fi
  if [ "$rc" -ne 0 ] && [ ! -e "$pwn" ]; then
    log_success "VG-BYO-SAFE: hostile theme rejected, no side effect"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "VG-BYO-SAFE: hostile theme not safely rejected (rc=$rc)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # State: legacy single-token form migrates to default variant
  mkdir -p "$tmp/config"
  printf 'alchemists-orchid\n' > "$tmp/config/theme.conf"
  local legacy
  legacy=$(POTIONS_HOME="$tmp" bash -c '. "'"$theme_lib"'/state.sh"; theme_state_read')
  if [ "$legacy" = "alchemists-orchid:dark" ]; then
    log_success "state: legacy single-token form migrates to default variant"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "state: legacy migration wrong ('$legacy')"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # CLI: theme current renders the active theme name
  local cur
  cur=$(REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash "$theme_lib/manager.sh" current 2>/dev/null)
  if echo "$cur" | grep -q "Alchemist's Orchid"; then
    log_success "CLI: theme current renders the active theme"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "CLI: theme current output unexpected ('$cur')"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # --- Phase 1: adapters, set/cycle, config wiring, VG-SOT, VG-DOCS ---

  # set regenerates all four target artifacts under POTIONS_HOME
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash "$theme_lib/manager.sh" \
    set alchemists-orchid white > /dev/null 2>&1 || true
  assert_file_exists "$tmp/zellij/themes/potions-active.kdl" "adapter: zellij theme generated"
  assert_file_exists "$tmp/nvim/generated/palette.vim" "adapter: nvim palette generated"
  assert_file_exists "$tmp/config/generated/ansi-map.sh" "adapter: shell ansi-map generated"
  assert_file_exists "$tmp/config/generated/alacritty-colors.toml" "adapter: terminal colors generated"
  assert_file_contains "$tmp/zellij/themes/potions-active.kdl" '#fafbfc' "zellij white bg correct"
  assert_file_contains "$tmp/config/generated/ansi-map.sh" '033]4;1;' "shell ansi-map emits OSC palette"
  assert_file_contains "$tmp/nvim/generated/palette.vim" "mode = 'light'" "nvim white drives the plugin light mode"
  assert_file_contains "$tmp/nvim/generated/palette.vim" "bg = '#fafbfc'" "nvim white pins surface bg via plugin overrides"
  # The plugin's plugin/*.lua eagerly applies its dark default AFTER init.vim;
  # the palette must re-assert the variant on VimEnter or the body reverts to
  # dark while only the tabline tracks the variant (regression guard).
  assert_file_contains "$tmp/nvim/generated/palette.vim" "PotionsApplyOrchid" "nvim palette exposes a re-callable variant apply"
  assert_file_contains "$tmp/nvim/generated/palette.vim" "autocmd VimEnter \\* lua PotionsApplyOrchid()" "nvim palette re-asserts variant after plugin/ scripts load"

  local st
  st=$(POTIONS_HOME="$tmp" bash -c '. "'"$theme_lib"'/state.sh"; theme_state_read')
  if [ "$st" = "alchemists-orchid:white" ]; then
    log_success "set: state updated to white"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "set: state not updated ('$st')"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # nvim variant -> plugin palette mode: dark=dark; white/sepia ride the plugin's
  # light mode (Potions' sepia is light parchment, the plugin's own sepia is dark)
  # and each pins the editor surface to the active variant's bg via overrides.
  if REPO_ROOT="$SCRIPT_DIR" bash -c '
      . "'"$theme_lib"'/generator.sh"
      ( export POTIONS_HOME="'"$tmp"'/nd"; theme_generate "'"$theme_dir"'" dark )  > /dev/null 2>&1 || exit 1
      ( export POTIONS_HOME="'"$tmp"'/ns"; theme_generate "'"$theme_dir"'" sepia ) > /dev/null 2>&1 || exit 1
      grep -q "mode = .dark."  "'"$tmp"'/nd/nvim/generated/palette.vim" || exit 1
      grep -q "bg = .#2e3440."  "'"$tmp"'/nd/nvim/generated/palette.vim" || exit 1
      grep -q "mode = .light." "'"$tmp"'/ns/nvim/generated/palette.vim" || exit 1
      grep -q "bg = .#f5f0e6."  "'"$tmp"'/ns/nvim/generated/palette.vim" || exit 1
    '; then
    log_success "nvim: variant maps to plugin mode (dark->dark, sepia->light parchment)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "nvim: variant->plugin-mode mapping incorrect"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # cycle advances and wraps from the last variant back to the first
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash "$theme_lib/manager.sh" set alchemists-orchid sepia > /dev/null 2>&1 || true
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash "$theme_lib/manager.sh" cycle > /dev/null 2>&1 || true
  local cyc
  cyc=$(POTIONS_HOME="$tmp" bash -c '. "'"$theme_lib"'/state.sh"; theme_state_variant')
  if [ "$cyc" = "dark" ]; then
    log_success "cycle: sepia -> dark wraps to first variant"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "cycle: did not wrap to first variant ('$cyc')"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # VG-SOT: no palette hex / inline themes block in tracked tool configs
  if ! grep -qE '#[0-9A-Fa-f]{6}' "$SCRIPT_DIR/.potions/zellij/config.kdl" \
     && ! grep -q 'themes {' "$SCRIPT_DIR/.potions/zellij/config.kdl"; then
    log_success "VG-SOT: config.kdl free of palette hex and inline themes block"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "VG-SOT: config.kdl still contains hex or a themes block"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  if ! grep -qE 'gui(fg|bg)=#[0-9A-Fa-f]{6}' "$SCRIPT_DIR/.potions/nvim/init.vim"; then
    log_success "VG-SOT: init.vim free of hardcoded gui hex"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "VG-SOT: init.vim still has hardcoded gui hex"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Config wiring (includes/references point at generated artifacts)
  assert_file_contains "$SCRIPT_DIR/.potions/zellij/config.kdl" 'potions-active' "config.kdl references generated theme"
  assert_file_contains "$SCRIPT_DIR/.potions/nvim/init.vim" "generated/palette.vim" "init.vim sources generated nvim palette"
  assert_file_contains "$SCRIPT_DIR/.potions/.zshrc" "config/generated/ansi-map.sh" ".zshrc sources generated ansi-map"
  assert_file_contains "$SCRIPT_DIR/.potions/terminal-setup/alacritty.toml" "alacritty-colors.toml" "alacritty.toml imports generated colors"
  assert_file_contains "$SCRIPT_DIR/install.sh" "manager.sh.* regen" "install.sh regenerates theme artifacts"
  assert_file_contains "$SCRIPT_DIR/upgrade.sh" "manager.sh.* regen" "upgrade.sh regenerates theme artifacts"

  # dead parallel nvim mechanism removed
  if [ ! -f "$SCRIPT_DIR/.potions/nvim/theme.vim" ]; then
    log_success "nvim/theme.vim (dead parallel mechanism) removed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "nvim/theme.vim should be removed (folded into potions theme)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # VG-DOCS: docs/color-palette.md in sync with token sources
  if command -v jq > /dev/null 2>&1; then
    cp "$SCRIPT_DIR/docs/color-palette.md" "$tmp/doc.before" 2>/dev/null || true
    "$SCRIPT_DIR/scripts/compile-themes.sh" --docs > /dev/null 2>&1 || true
    if diff -q "$tmp/doc.before" "$SCRIPT_DIR/docs/color-palette.md" > /dev/null 2>&1; then
      log_success "VG-DOCS: color-palette.md in sync with token sources"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "VG-DOCS: color-palette.md drift — run scripts/compile-themes.sh --docs"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    log_skip "VG-DOCS check skipped (jq not installed)"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
  fi

  # --- Phase 2: sepia variant, terminal breadth, BYO verify/install ---

  # sepia variant compiles and resolves to parchment surfaces
  assert_file_exists "$theme_dir/sepia.theme" "sepia variant compiled"
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash "$theme_lib/manager.sh" \
    set alchemists-orchid sepia > /dev/null 2>&1 || true
  assert_file_contains "$tmp/zellij/themes/potions-active.kdl" '#f5f0e6' "sepia parchment bg generated"
  assert_file_contains "$tmp/zellij/themes/potions-active.kdl" 'text_unselected' "zellij sepia defines compact-bar text"
  assert_file_contains "$tmp/zellij/themes/potions-active.kdl" 'background "#f5f0e6"' "zellij sepia bar fill is the parchment surface"
  assert_file_contains "$tmp/zellij/themes/potions-active.kdl" 'ribbon_selected' "zellij sepia defines the selected ribbon"

  # all four terminal emulator color files generated
  assert_file_exists "$tmp/config/generated/alacritty-colors.toml" "terminal: alacritty colors generated"
  assert_file_exists "$tmp/config/generated/kitty-colors.conf" "terminal: kitty colors generated"
  assert_file_exists "$tmp/config/generated/ghostty-colors" "terminal: ghostty colors generated"
  assert_file_exists "$tmp/config/generated/wezterm-colors.lua" "terminal: wezterm colors generated"

  # BYO: a valid theme verifies, installs into themes-user, and lists as byo
  local byo="$tmp/byo-src"
  mkdir -p "$byo"
  printf 'META_ID=tester\nMETA_NAME=Tester\nMETA_VARIANTS=dark\n' > "$byo/manifest"
  printf 'META_ID=tester\nMETA_VARIANT=dark\nCOLOR_PRIMARY_HEX=#88C0D0\nCOLOR_PRIMARY_CTERM=110\nCOLOR_SURFACE_HEX=#2E3440\nCOLOR_SURFACE_CTERM=237\nCOLOR_ON_SURFACE_HEX=#ECEFF4\nCOLOR_ON_SURFACE_CTERM=255\n' > "$byo/dark.theme"
  if REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash "$theme_lib/manager.sh" verify "$byo" > /dev/null 2>&1; then
    log_success "BYO: valid theme passes verification"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "BYO: valid theme failed verification"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash "$theme_lib/manager.sh" install "$byo" > /dev/null 2>&1 || true
  assert_file_exists "$tmp/themes-user/tester/dark.theme" "BYO: install copies into themes-user"
  if REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash "$theme_lib/manager.sh" list 2>/dev/null | grep -q 'byo'; then
    log_success "BYO: installed theme listed with byo trust"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "BYO: installed theme not listed as byo"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # BYO: hostile theme rejected at install — not copied, no side effect
  local hbyo="$tmp/byo-evil" pwn2="$tmp/PWNED2"
  mkdir -p "$hbyo"
  printf 'META_ID=evil\n' > "$hbyo/manifest"
  printf 'COLOR_X_HEX=$(touch %s)\n' "$pwn2" > "$hbyo/dark.theme"
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash "$theme_lib/manager.sh" install "$hbyo" > /dev/null 2>&1 || true
  if [ ! -e "$pwn2" ] && [ ! -d "$tmp/themes-user/evil" ]; then
    log_success "BYO: hostile theme rejected at install (no copy, no side effect)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "BYO: hostile theme not safely rejected at install"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # BYO: uninstall removes it
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash "$theme_lib/manager.sh" uninstall tester > /dev/null 2>&1 || true
  if [ ! -d "$tmp/themes-user/tester" ]; then
    log_success "BYO: uninstall removes the theme"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "BYO: uninstall did not remove the theme"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # --- Phase 3: explicit ANSI-16 + cursor/selection, Ghostty/Termux ---
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" bash "$theme_lib/manager.sh" \
    set alchemists-orchid dark > /dev/null 2>&1 || true

  # Token SoT carries the explicit ANSI layer + cursor/selection, byte-faithful
  # to upstream alchemists-orchid.ghostty (dark ANSI red is the brand pink).
  assert_file_contains "$theme_dir/dark.theme" "COLOR_ANSI_1_HEX=#e8a4cc" "tokens: dark ANSI red is brand pink"
  assert_file_contains "$theme_dir/dark.theme" "COLOR_CURSOR_HEX=#d9a8dd" "tokens: dark cursor present"
  assert_file_contains "$theme_dir/dark.theme" "COLOR_SELECTION_BG_HEX=#4c566a" "tokens: dark selection present"

  # Ghostty palette file: cursor + selection + byte-faithful ANSI
  assert_file_contains "$tmp/config/generated/ghostty-colors" "cursor-color = #d9a8dd" "ghostty: cursor-color emitted"
  assert_file_contains "$tmp/config/generated/ghostty-colors" "selection-background = #4c566a" "ghostty: selection emitted"
  assert_file_contains "$tmp/config/generated/ghostty-colors" "palette = 1=#e8a4cc" "ghostty: ANSI palette byte-faithful"

  # Ghostty managed fragment: palette include + QoL companion settings
  assert_file_exists "$tmp/config/generated/ghostty.conf" "ghostty: managed config fragment generated"
  assert_file_contains "$tmp/config/generated/ghostty.conf" "ghostty-colors" "ghostty.conf includes the palette file"
  assert_file_contains "$tmp/config/generated/ghostty.conf" "macos-option-as-alt" "ghostty.conf sets QoL keys"
  assert_file_contains "$tmp/config/generated/ghostty.conf" "shell-integration-features = sudo,title,ssh-terminfo" "ghostty.conf uses sudo,title,ssh-terminfo features"
  assert_file_contains "$tmp/config/generated/ghostty.conf" "ssh-terminfo" "ghostty.conf enables ssh terminfo integration"
  assert_file_contains "$tmp/config/generated/ghostty.conf" "keybind = cmd+d=esc:d" "ghostty.conf forwards cmd+d to alt+d"
  assert_file_contains "$tmp/config/generated/ghostty.conf" "keybind = cmd+t=esc:t" "ghostty.conf forwards cmd+t to alt+t"
  assert_file_contains "$tmp/config/generated/ghostty.conf" "keybind = cmd+w=esc:w" "ghostty.conf forwards cmd+w to alt+w"
  assert_file_contains "$tmp/config/generated/ghostty.conf" "keybind = cmd+n=esc:n" "ghostty.conf forwards cmd+n to alt+n"
  assert_file_contains "$tmp/config/generated/ghostty.conf" "keybind = cmd+p=esc:p" "ghostty.conf forwards cmd+p to alt+p"
  assert_file_contains "$tmp/config/generated/ghostty.conf" "keybind = cmd+enter=esc:\\r" "ghostty.conf forwards cmd+enter to alt+enter"
  _ghostty_feat=$(grep -E '^shell-integration-features =' "$tmp/config/generated/ghostty.conf" || true)
  if [ "$_ghostty_feat" = "shell-integration-features = sudo,title,ssh-terminfo" ]; then
    log_success "ghostty.conf feature line is exact (no ssh-env, no cursor)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "ghostty.conf feature line unexpected: '$_ghostty_feat'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Zellij + shell now consume the explicit ANSI tokens
  assert_file_contains "$tmp/zellij/themes/potions-active.kdl" '#e8a4cc' "zellij red uses explicit ANSI token"
  assert_file_contains "$tmp/config/generated/ansi-map.sh" '#e8a4cc' "shell ansi-map uses explicit ANSI token"

  # Termux adapter writes a faithful colors.properties when the gate is on
  local thome="$tmp/thome"
  mkdir -p "$thome"
  HOME="$thome" bash -c '
      . "'"$theme_lib"'/resolver.sh"; . "'"$theme_lib"'/adapters.sh"
      _theme_is_termux() { return 0; }
      theme_resolve "'"$theme_dir"'" dark >/dev/null 2>&1 || exit 1
      theme_gen_adapter_termux "" >/dev/null 2>&1
    '
  if grep -q '^color1=#e8a4cc' "$thome/.termux/colors.properties" 2>/dev/null \
     && grep -q '^background=#2e3440' "$thome/.termux/colors.properties" 2>/dev/null; then
    log_success "termux: colors.properties written with faithful palette"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "termux: colors.properties not written correctly"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Termux adapter is a strict no-op when the gate is off (deterministic)
  local nhome="$tmp/nothome"
  mkdir -p "$nhome"
  HOME="$nhome" bash -c '
      . "'"$theme_lib"'/resolver.sh"; . "'"$theme_lib"'/adapters.sh"
      _theme_is_termux() { return 1; }
      theme_resolve "'"$theme_dir"'" dark >/dev/null 2>&1
      theme_gen_adapter_termux "" >/dev/null 2>&1
    '
  if [ ! -f "$nhome/.termux/colors.properties" ]; then
    log_success "termux: adapter is a no-op off-Termux"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "termux: adapter wrote colors.properties off-Termux"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  rm -rf "$tmp"
}

test_terminal_emulator_support() {
  log_step "Terminal Emulator Support Tests"

  local term_lib="$SCRIPT_DIR/.potions/lib/terminal"

  assert_file_exists "$term_lib/manager.sh" "terminal/manager.sh exists"
  assert_syntax_valid "$term_lib/manager.sh" "terminal/manager.sh syntax"
  assert_no_local_outside_function "$term_lib/manager.sh" "terminal/manager.sh: no local outside functions"

  # potions bin wires the terminal command; install/upgrade auto-run setup
  assert_file_contains "$SCRIPT_DIR/.potions/bin/potions" "cmd_terminal" "potions bin has cmd_terminal"
  assert_file_contains "$SCRIPT_DIR/.potions/bin/potions" "potions terminal setup ghostty" "doctor suggests potions terminal setup ghostty"
  assert_file_contains "$SCRIPT_DIR/install.sh" "terminal/manager.sh.* setup" "install.sh wires terminal setup"
  assert_file_contains "$SCRIPT_DIR/upgrade.sh" "terminal/manager.sh.* setup" "upgrade.sh wires terminal setup"

  # generator dispatches the termux adapter target
  assert_file_contains "$SCRIPT_DIR/.potions/lib/theme/generator.sh" "termux" "generator targets include termux"

  local tmp
  tmp=$(mktemp -d)

  # Ghostty wiring: backs up an existing config, appends the include exactly once
  local ghome="$tmp/ghome"
  mkdir -p "$ghome/.config/ghostty" "$ghome/.potions/config/generated"
  printf '# managed fragment\n' > "$ghome/.potions/config/generated/ghostty.conf"
  printf 'font-size = 14\n' > "$ghome/.config/ghostty/config"
  # Pin XDG_CONFIG_HOME so the manager resolves the config to the test fixture
  # regardless of the runner's environment (Ubuntu CI presets XDG_CONFIG_HOME).
  local gxdg="$ghome/.config"
  HOME="$ghome" XDG_CONFIG_HOME="$gxdg" POTIONS_HOME="$ghome/.potions" REPO_ROOT="$SCRIPT_DIR" \
    bash "$term_lib/manager.sh" setup ghostty > /dev/null 2>&1 || true
  HOME="$ghome" XDG_CONFIG_HOME="$gxdg" POTIONS_HOME="$ghome/.potions" REPO_ROOT="$SCRIPT_DIR" \
    bash "$term_lib/manager.sh" setup ghostty > /dev/null 2>&1 || true
  local inc_count
  inc_count=$(grep -Fc "config/generated/ghostty.conf" "$ghome/.config/ghostty/config" 2>/dev/null || true)
  inc_count=${inc_count:-0}
  if [ "$inc_count" = "1" ] && [ -f "$ghome/.config/ghostty/config.bak" ]; then
    log_success "terminal: Ghostty include added once, original backed up"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "terminal: Ghostty wiring not idempotent or no backup (count=$inc_count)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  assert_file_contains "$ghome/.config/ghostty/config" "font-size = 14" "terminal: Ghostty original config preserved"

  # Ghostty setup is a no-op when Ghostty is absent (no config dir, not on PATH)
  local ahome="$tmp/absent"
  mkdir -p "$ahome"
  HOME="$ahome" XDG_CONFIG_HOME="$ahome/.config" POTIONS_HOME="$ahome/.potions" REPO_ROOT="$SCRIPT_DIR" \
    PATH="/usr/bin:/bin" bash "$term_lib/manager.sh" setup ghostty > /dev/null 2>&1 || true
  if [ ! -e "$ahome/.config/ghostty/config" ]; then
    log_success "terminal: Ghostty setup no-ops when emulator absent"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "terminal: Ghostty setup created config when emulator absent"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # status renders without error
  if HOME="$ghome" XDG_CONFIG_HOME="$gxdg" POTIONS_HOME="$ghome/.potions" REPO_ROOT="$SCRIPT_DIR" \
       bash "$term_lib/manager.sh" status > /dev/null 2>&1; then
    log_success "terminal: status runs cleanly"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "terminal: status errored"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Doctor fixtures must keep coreutils on PATH. Termux ships them in
  # $PREFIX/bin, not /usr/bin; Fedora's container image has no git.
  local fixture_path="/usr/bin:/bin"
  if [ -n "${PREFIX:-}" ] && [ -d "${PREFIX}/bin" ]; then
    fixture_path="${PREFIX}/bin:${fixture_path}"
  fi

  # doctor: skip Ghostty include check when Ghostty is absent
  local dabs="$tmp/doctor-absent" dabs_out
  mkdir -p "$dabs/.potions"
  dabs_out=$(HOME="$dabs" XDG_CONFIG_HOME="$dabs/.config" POTIONS_HOME="$dabs/.potions" \
    PATH="$fixture_path" bash "$SCRIPT_DIR/.potions/bin/potions" doctor 2>&1 || true)
  if echo "$dabs_out" | grep -qi ghostty; then
    log_failure "doctor: mentioned Ghostty when emulator is absent"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "doctor: skips Ghostty include check when emulator is absent"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  # doctor: warn (not a hard failure of unrelated checks) when include is missing
  local dmiss="$tmp/doctor-miss" dmiss_out dmiss_rc=0
  mkdir -p "$dmiss/.potions/bin" "$dmiss/.config/ghostty"
  printf '0.0.0\n' > "$dmiss/.potions/.version"
  printf '# zshrc\n' > "$dmiss/.potions/.zshrc"
  printf '# aliases\n' > "$dmiss/.potions/.zsh_aliases"
  # Stub git so doctor does not fail on images that omit it (Fedora CI).
  printf '#!/bin/sh\nexit 0\n' > "$dmiss/.potions/bin/git"
  chmod +x "$dmiss/.potions/bin/git"
  local dmiss_path="$dmiss/.potions/bin:${fixture_path}"
  dmiss_out=$(HOME="$dmiss" XDG_CONFIG_HOME="$dmiss/.config" POTIONS_HOME="$dmiss/.potions" \
    PATH="$dmiss_path" NO_COLOR=1 \
    bash "$SCRIPT_DIR/.potions/bin/potions" doctor 2>&1) || dmiss_rc=$?
  if echo "$dmiss_out" | grep -q "potions terminal setup ghostty"; then
    log_success "doctor: warns to run potions terminal setup ghostty when include is missing"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "doctor: missing Ghostty include did not suggest setup"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  if [ "$dmiss_rc" -eq 0 ]; then
    log_success "doctor: missing Ghostty include is not a hard failure"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "doctor: missing Ghostty include failed unrelated checks (rc=$dmiss_rc)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # doctor: reports the include when wired
  local dwire="$tmp/doctor-wire" dwire_out
  mkdir -p "$dwire/.potions" "$dwire/.config/ghostty"
  printf 'config-file = ?%s/.potions/config/generated/ghostty.conf\n' "$dwire" \
    > "$dwire/.config/ghostty/config"
  dwire_out=$(HOME="$dwire" XDG_CONFIG_HOME="$dwire/.config" POTIONS_HOME="$dwire/.potions" \
    PATH="$fixture_path" NO_COLOR=1 bash "$SCRIPT_DIR/.potions/bin/potions" doctor 2>&1 || true)
  if echo "$dwire_out" | grep -q "Ghostty config includes the managed fragment" \
     && ! echo "$dwire_out" | grep -q "managed include is missing"; then
    log_success "doctor: reports Ghostty managed include when present"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "doctor: did not report wired Ghostty include"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  rm -rf "$tmp"
}

test_reload_system() {
  log_step "Reload System Tests"

  local reload_lib="$SCRIPT_DIR/.potions/lib/reload"
  local theme_lib="$SCRIPT_DIR/.potions/lib/theme"
  local theme_dir="$SCRIPT_DIR/.potions/themes/alchemists-orchid"

  # Structure: reload manager exists
  assert_file_exists "$reload_lib/manager.sh" "reload/manager.sh exists"

  # Syntax valid
  assert_syntax_valid "$reload_lib/manager.sh" "reload/manager.sh syntax"

  # No local outside functions
  assert_no_local_outside_function "$reload_lib/manager.sh" "reload/manager.sh: no local outside functions"

  # bin/potions wires the reload command
  assert_file_contains "$SCRIPT_DIR/.potions/bin/potions" "cmd_reload" "potions bin has cmd_reload"
  assert_file_contains "$SCRIPT_DIR/.potions/bin/potions" "reload)" "potions bin router has reload case"

  # lib/help.sh mentions reload
  assert_file_contains "$SCRIPT_DIR/.potions/lib/help.sh" "reload" "lib/help.sh mentions reload"

  local tmp
  tmp=$(mktemp -d)

  # Set up a minimal temp POTIONS_HOME with config/theme.conf and themes dir.
  # Mirrors the setup pattern from test_theme_system.
  mkdir -p "$tmp/config"
  printf 'alchemists-orchid:dark\n' > "$tmp/config/theme.conf"

  # Functional: TERM=dumb reload all in temp home exits 0 and regenerates.
  local reload_rc=0
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" TERM=dumb \
    bash "$reload_lib/manager.sh" all > /dev/null 2>&1 || reload_rc=$?
  if [ "$reload_rc" -eq 0 ]; then
    log_success "reload all: exits 0 with TERM=dumb"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "reload all: expected exit 0, got $reload_rc"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Regeneration produced ansi-map.sh
  assert_file_exists "$tmp/config/generated/ansi-map.sh" "reload: ansi-map.sh generated (regen happened)"

  # reload_bounded_exec sanity: sleep 5 with timeout 1 -> returns 124
  local be_rc=0
  bash -c '
    . "'"$reload_lib"'/manager.sh"
    reload_bounded_exec 1 sleep 5
  ' > /dev/null 2>&1 || be_rc=$?
  if [ "$be_rc" -eq 124 ]; then
    log_success "reload_bounded_exec: sleep 5 with 1s timeout returns 124"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "reload_bounded_exec: expected 124 (timeout), got $be_rc"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # reload_bounded_exec sanity: true with timeout 2 -> returns 0
  local be_rc2=0
  bash -c '
    . "'"$reload_lib"'/manager.sh"
    reload_bounded_exec 2 true
  ' > /dev/null 2>&1 || be_rc2=$?
  if [ "$be_rc2" -eq 0 ]; then
    log_success "reload_bounded_exec: true with 2s timeout returns 0"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "reload_bounded_exec: expected 0, got $be_rc2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Idempotency: run reload twice, both should exit 0
  local idem_rc1=0 idem_rc2=0
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" TERM=dumb \
    bash "$reload_lib/manager.sh" all > /dev/null 2>&1 || idem_rc1=$?
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" TERM=dumb \
    bash "$reload_lib/manager.sh" all > /dev/null 2>&1 || idem_rc2=$?
  if [ "$idem_rc1" -eq 0 ] && [ "$idem_rc2" -eq 0 ]; then
    log_success "reload idempotency: two consecutive runs both exit 0"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "reload idempotency: rc1=$idem_rc1 rc2=$idem_rc2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Unknown target exits 2 (usage error)
  local bad_rc=0
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" TERM=dumb \
    bash "$reload_lib/manager.sh" badtarget > /dev/null 2>&1 || bad_rc=$?
  if [ "$bad_rc" -eq 2 ]; then
    log_success "reload: unknown target exits 2"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "reload: expected exit 2 for bad target, got $bad_rc"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  rm -rf "$tmp"
}

test_terminal_reload() {
  log_step "Terminal Reload Tests"

  local reload_lib="$SCRIPT_DIR/.potions/lib/reload"
  local term_lib="$SCRIPT_DIR/.potions/lib/terminal"

  # terminal/manager.sh mentions reload
  assert_file_contains "$term_lib/manager.sh" "reload" "terminal/manager.sh mentions reload"

  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/config"
  printf 'alchemists-orchid:dark\n' > "$tmp/config/theme.conf"

  # `potions terminal reload` (= reload terminal scope) exits 0
  local trl_rc=0
  REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" TERM=dumb \
    bash "$term_lib/manager.sh" reload > /dev/null 2>&1 || trl_rc=$?
  if [ "$trl_rc" -eq 0 ]; then
    log_success "terminal reload: exits 0"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "terminal reload: expected exit 0, got $trl_rc"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # terminal scope matrix must NOT contain NeoVim or Zellij lines
  local trl_out
  trl_out=$(REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" TERM=dumb \
    bash "$term_lib/manager.sh" reload 2>&1 || true)
  if echo "$trl_out" | grep -q "NeoVim"; then
    log_failure "terminal reload: matrix must not contain NeoVim"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "terminal reload: matrix does not contain NeoVim"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi
  if echo "$trl_out" | grep -q "Zellij"; then
    log_failure "terminal reload: matrix must not contain Zellij"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "terminal reload: matrix does not contain Zellij"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  # Equivalence: `reload terminal` matrix == `terminal reload` matrix
  local rel_out trl_out2
  rel_out=$(REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" TERM=dumb \
    bash "$reload_lib/manager.sh" terminal 2>&1 || true)
  trl_out2=$(REPO_ROOT="$SCRIPT_DIR" POTIONS_HOME="$tmp" TERM=dumb \
    bash "$term_lib/manager.sh" reload 2>&1 || true)
  # Compare matrix lines only (strip leading info/success log lines that may differ).
  local rel_matrix trl_matrix
  rel_matrix=$(echo "$rel_out" | grep -E '^\s+(Shell|Termux|Alacritty|WezTerm|Kitty|Ghostty|Zellij|NeoVim)' || true)
  trl_matrix=$(echo "$trl_out2" | grep -E '^\s+(Shell|Termux|Alacritty|WezTerm|Kitty|Ghostty|Zellij|NeoVim)' || true)
  if [ "$rel_matrix" = "$trl_matrix" ]; then
    log_success "terminal reload equivalence: reload terminal == terminal reload matrix"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "terminal reload equivalence: matrix differs"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  rm -rf "$tmp"
}

test_door() {
  log_step "Potions Door"

  local tmp fix out living action notice mintfile log stub
  local saved_path saved_session had_session saved_zellij had_zellij
  local saved_color_home saved_has_color
  tmp=$(mktemp -d)
  fix="$tmp/sessions"
  mintfile="$tmp/mint"
  log="$tmp/zellij.log"
  stub="$tmp/bin"
  mkdir -p "$stub"

  saved_path="$PATH"
  had_session=0
  if [ -n "${POTIONS_SESSION+x}" ]; then
    had_session=1
    saved_session="$POTIONS_SESSION"
  fi
  had_zellij=0
  if [ -n "${ZELLIJ+x}" ]; then
    had_zellij=1
    saved_zellij="$ZELLIJ"
  fi
  unset POTIONS_SESSION POTIONS_DOOR_LIST_FIXTURE POTIONS_DOOR_NOTICE POTIONS_DOOR_ZSHRC

  # shellcheck source=/dev/null
  . "$SCRIPT_DIR/.potions/lib/door.sh"

  # Verbatim `zellij list-sessions --no-formatting` lines (0.44), plus one
  # living line in the same "[Created …]" grammar. No session was current
  # on the machine that captured the exited rows.
  cat > "$fix" << 'EOF'
copper-tincture [Created 4months 22days 9h 16m 11s ago] (EXITED - attach to resurrect)
vivid-sublimate [Created 4months 21days 6h 24m 10s ago] (EXITED - attach to resurrect)
azure-elixir [Created 4months 18days 7h 31m 1s ago] (EXITED - attach to resurrect)
golden-cauldron [Created 2s ago] (current)
silver-elixir [Created 1s ago]
EOF

  living=$(potions_door_select_living < "$fix" || true)
  if [ "$living" = "golden-cauldron" ]; then
    log_success "Living mood prefers the current session over a later one"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Living mood: expected golden-cauldron, got '${living}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  cat > "$fix" << 'EOF'
copper-tincture [Created 4months 22days 9h 16m 11s ago] (EXITED - attach to resurrect)
vivid-sublimate [Created 4months 21days 6h 24m 10s ago] (EXITED - attach to resurrect)
azure-elixir [Created 4months 18days 7h 31m 1s ago] (EXITED - attach to resurrect)
EOF
  living=$(potions_door_select_living < "$fix" || true)
  if [ -z "$living" ]; then
    log_success "Exited sessions are not a living mood"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Exited sessions were treated as living: '${living}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  printf '\033[32;1mcopper-tincture\033[m [Created 4months 22days 9h 16m 11s ago] (\033[31;1mEXITED\033[m - attach to resurrect)\n' > "$fix"
  living=$(potions_door_select_living < "$fix" || true)
  if [ -z "$living" ]; then
    log_success "ANSI exited rows are not a living mood"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "ANSI exited row was treated as living: '${living}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  printf '%s\n' 'No active zellij sessions found' > "$fix"
  living=$(potions_door_select_living < "$fix" || true)
  if [ -z "$living" ]; then
    log_success "Prose from Zellij is not a session name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Prose was treated as a session: '${living}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  cat > "$fix" << 'EOF'
silver-elixir [Created 2s ago]
golden-cauldron [Created 1s ago]
EOF
  living=$(potions_door_select_living < "$fix" || true)
  if [ "$living" = "golden-cauldron" ]; then
    log_success "With no current marker, the newest living mood is shown"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Newest living mood: expected golden-cauldron, got '${living}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  POTIONS_SESSION=azure-elixir
  cat > "$fix" << 'EOF'
azure-elixir [Created 4months 18days 7h 31m 1s ago] (EXITED - attach to resurrect)
golden-cauldron [Created 1s ago] (current)
EOF
  living=$(potions_door_select_living < "$fix" || true)
  if [ -z "$living" ]; then
    log_success "A dead POTIONS_SESSION pin does not resume a different mood"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Dead pin still selected a mood: '${living}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  unset POTIONS_SESSION
  cat > "$fix" << 'EOF'
potions [Created 1s ago] (current)
golden-cauldron [Created 3s ago]
EOF
  living=$(potions_door_select_living < "$fix" || true)
  if [ "$living" = "golden-cauldron" ]; then
    log_success "The potions lobby is not a mood"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Lobby was treated as a mood: '${living}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  cat > "$fix" << 'EOF'
potions [Created 1s ago] (current)
EOF
  living=$(potions_door_select_living < "$fix" || true)
  if [ -z "$living" ]; then
    log_success "A lobby alone does not offer Resume"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Lobby alone selected '${living}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  cat > "$fix" << 'EOF'
golden-cauldron [Created 1s ago] (current)
EOF
  POTIONS_SESSION=golden-cauldron
  living=$(potions_door_select_living < "$fix" || true)
  if [ "$living" = "golden-cauldron" ]; then
    log_success "POTIONS_SESSION pins Resume when that mood is alive"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Pin was not honored: '${living}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  unset POTIONS_SESSION

  cat > "$stub/zellij" << 'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "${DOOR_LOG:?}"
exit 0
EOF
  chmod +x "$stub/zellij"

  cat > "$fix" << 'EOF'
golden-cauldron [Created 2s ago] (current)
EOF
  : > "$log"
  DOOR_LOG="$log"
  export DOOR_LOG
  POTIONS_DOOR_LIST_FIXTURE="$fix"
  PATH="$stub:$saved_path"
  living=$(potions_door_living_name || true)
  PATH="$saved_path"
  unset POTIONS_DOOR_LIST_FIXTURE
  if [ "$living" = "golden-cauldron" ] && ! grep -q . "$log" 2>/dev/null; then
    log_success "Detecting the living mood does not mint a name or call Zellij"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Living detection minted or invoked a command: '${living}' log=$(cat "$log" 2>/dev/null)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  if [ "$(potions_door_classify_key "" || true)" = "enter" ] && [ "$(potions_door_classify_key "$(printf '\r')" || true)" = "enter" ]; then
    log_success "Enter is recognized when read drops the newline"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Enter was not classified"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  action=$(potions_door_key_action q "golden-cauldron" || true)
  if [ "$action" = "quit" ]; then
    log_success "q quits the door"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "q action was '${action}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  action=$(potions_door_key_action b "" || true)
  if [ "$action" = "begin" ]; then
    log_success "b is Begin"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "b action was '${action}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  action=$(potions_door_key_action r "" || true)
  if [ "$action" = "noop" ]; then
    log_success "Resume is inert when nothing is alive"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Resume without a mood was '${action}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  action=$(potions_door_key_action r "golden-cauldron" || true)
  if [ "$action" = "resume" ]; then
    log_success "Resume is offered when a mood is alive"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Resume with a mood was '${action}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  action=$(potions_door_key_action n "golden-cauldron" || true)
  if [ "$action" = "notes" ]; then
    log_success "n opens Notes"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "n action was '${action}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  out=$(potions_door_render "golden-cauldron" || true)
  if printf '%s\n' "$out" | grep -q "golden-cauldron" && printf '%s\n' "$out" | grep -q "Resume"; then
    log_success "The door shows the living mood and Resume"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Door render missed the living mood"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  plain=$(potions_door_strip_ansi "$out")
  if printf '%s\n' "$plain" | grep -q '/___\\' \
    && printf '%s\n' "$plain" | grep -q 'j k move    enter open' \
    && ! printf '%s\n' "$plain" | grep -q 'q quit' \
    && printf '%s\n' "$plain" | grep -q 'Resume  *rejoin golden-cauldron  *r'; then
    log_success "The door wears the bottle, a short hint, and a key on the row"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Door frame missed the bottle, the short hint, or the row key"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  # Light variants must ink the body with on-surface, not ANSI white.
  saved_color_home="${POTIONS_HOME:-}"
  saved_has_color="${POTIONS_HAS_COLOR:-}"
  POTIONS_HOME="$tmp/theme-home"
  mkdir -p "$POTIONS_HOME/config"
  printf '%s\n' 'alchemists-orchid:white' > "$POTIONS_HOME/config/theme.conf"
  ln -s "$SCRIPT_DIR/.potions/themes" "$POTIONS_HOME/themes"
  POTIONS_HAS_COLOR=true
  _potions_apply_palette
  case "$POTIONS_COLOR_VALUE" in
    *'38;5;236'*)
      log_success "White palette uses on-surface ink"
      TESTS_PASSED=$((TESTS_PASSED + 1))
      ;;
    *)
      log_failure "White palette ink was '${POTIONS_COLOR_VALUE}'"
      TESTS_FAILED=$((TESTS_FAILED + 1))
      ;;
  esac
  case "$POTIONS_COLOR_VALUE" in
    *'1;37'*)
      log_failure "White palette still uses bold white"
      TESTS_FAILED=$((TESTS_FAILED + 1))
      ;;
    *)
      log_success "White palette does not use bold white"
      TESTS_PASSED=$((TESTS_PASSED + 1))
      ;;
  esac
  printf '%s\n' 'alchemists-orchid:sepia' > "$POTIONS_HOME/config/theme.conf"
  _potions_apply_palette
  case "$POTIONS_COLOR_VALUE" in
    *'38;5;236'*)
      log_success "Sepia palette uses on-surface ink"
      TESTS_PASSED=$((TESTS_PASSED + 1))
      ;;
    *)
      log_failure "Sepia palette ink was '${POTIONS_COLOR_VALUE}'"
      TESTS_FAILED=$((TESTS_FAILED + 1))
      ;;
  esac
  if [ -n "$saved_color_home" ]; then
    POTIONS_HOME="$saved_color_home"
  else
    unset POTIONS_HOME
  fi
  if [ -n "$saved_has_color" ]; then
    POTIONS_HAS_COLOR="$saved_has_color"
  else
    unset POTIONS_HAS_COLOR
  fi

  out=$(potions_door_render "" || true)
  if printf '%s\n' "$out" | grep -q "Begin" && ! printf '%s\n' "$out" | grep -q "Resume"; then
    log_success "With no living mood, Begin is the path and Resume is absent"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Empty-door render still offered Resume or hid Begin"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  mkdir -p "$tmp/empty-bin"
  PATH="$tmp/empty-bin"
  hash -r 2>/dev/null || true
  potions_door_notes || true
  notice="${POTIONS_DOOR_NOTICE:-}"
  PATH="$saved_path"
  hash -r 2>/dev/null || true
  POTIONS_DOOR_NOTICE=""
  if [ "$notice" = "Neovim is not installed. Staying on the door." ]; then
    log_success "Missing Neovim stays on the door"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Missing Neovim notice was '${notice}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  potions_door_mint_name() {
    echo x >> "$mintfile"
    printf '%s' 'golden-cauldron'
  }
  : > "$log"
  : > "$mintfile"
  DOOR_LOG="$log"
  PATH="$stub:$saved_path"
  ZELLIJ=1
  unset POTIONS_SESSION
  potions_door_begin || true
  if [ "$(wc -l < "$mintfile" | tr -d ' ')" -eq 1 ] && grep -q 'attach --create-background golden-cauldron' "$log" && grep -q 'action switch-session golden-cauldron' "$log"; then
    log_success "Inside a mood, Begin mints once and switches without nesting"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Inside Begin mint/switch failed: mint=$(cat "$mintfile" 2>/dev/null) log=$(cat "$log" 2>/dev/null)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  : > "$log"
  : > "$mintfile"
  POTIONS_SESSION=obsidian-athanor
  potions_door_begin || true
  if ! grep -q . "$mintfile" 2>/dev/null && grep -q 'attach --create-background obsidian-athanor' "$log"; then
    log_success "Inside a mood, a pin Begins without minting"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Pinned inside Begin minted or missed the pin: $(cat "$log" 2>/dev/null)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  PATH="$saved_path"
  unset ZELLIJ POTIONS_SESSION

  if command -v zsh >/dev/null 2>&1; then
    if zsh -n "$SCRIPT_DIR/.potions/.zshrc" 2>"$tmp/zsh-n.err"; then
      log_success "zshrc syntax"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "zshrc syntax: $(cat "$tmp/zsh-n.err")"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    DOOR_ZSHRC="$SCRIPT_DIR/.potions/.zshrc"
    DOOR_STUB="$stub"
    DOOR_LOG="$log"
    DOOR_MINT="$tmp/name-mint"
    export DOOR_ZSHRC DOOR_STUB DOOR_LOG DOOR_MINT
    : > "$log"
    : > "$DOOR_MINT"
    zsh --no-rcs -c '
      source "$DOOR_ZSHRC" >/dev/null 2>&1 || true
      HISTFILE=/dev/null
      unset POTIONS_SESSION
      export PATH="$DOOR_STUB:$PATH"
      _potions_zellij_session_name() { print x >> "$DOOR_MINT"; print -r -- minted-athanor; }
      _potions_resume_mood silver-elixir
      if [ -s "$DOOR_MINT" ]; then print -r -- "MINT_AFTER_RESUME"; exit 1; fi
      if grep -q "attach --create " "$DOOR_LOG"; then print -r -- "RESUME_CREATED"; exit 1; fi
      if ! grep -q "attach silver-elixir" "$DOOR_LOG"; then print -r -- "RESUME_MISSED"; exit 1; fi
      : > "$DOOR_LOG"
      _potions_begin_mood
      _n=0
      while IFS= read -r _; do _n=$((_n + 1)); done < "$DOOR_MINT"
      if [ "$_n" -ne 1 ]; then print -r -- "MINT_AFTER_BEGIN=$_n"; exit 1; fi
      if ! grep -q "attach --create minted-athanor" "$DOOR_LOG"; then print -r -- "BEGIN_MISSED"; exit 1; fi
      : > "$DOOR_LOG"
      POTIONS_SESSION=obsidian-athanor _potions_begin_mood
      _n=0
      while IFS= read -r _; do _n=$((_n + 1)); done < "$DOOR_MINT"
      if [ "$_n" -ne 1 ]; then print -r -- "PIN_MINTED=$_n"; exit 1; fi
      if ! grep -q "attach --create obsidian-athanor" "$DOOR_LOG"; then print -r -- "PIN_MISSED"; exit 1; fi
      : > "$DOOR_LOG"
      POTIONS_SESSION="bad name" _potions_begin_mood
      _n=0
      while IFS= read -r _; do _n=$((_n + 1)); done < "$DOOR_MINT"
      if [ "$_n" -ne 2 ]; then print -r -- "UNSAFE_PIN=$_n"; exit 1; fi
      if grep -q "bad name" "$DOOR_LOG"; then print -r -- "UNSAFE_PASSED"; exit 1; fi
      unset POTIONS_SESSION CURSOR_TERMINAL VSCODE_INJECTION VSCODE_PID INTELLIJ_TERMINAL CLAUDECODE
      TERM_PROGRAM=potions-test
      if is_ai_code_editor; then print -r -- "CLEAN_AI"; exit 1; fi
      CURSOR_TERMINAL=1
      if ! is_ai_code_editor; then print -r -- "CURSOR_MISSED"; exit 1; fi
      unset CURSOR_TERMINAL
      CLAUDECODE=1
      if ! is_ai_code_editor; then print -r -- "CLAUDE_MISSED"; exit 1; fi
      unset ZELLIJ CLAUDECODE
      TERM_PROGRAM=potions-test
      if _potions_personal_shell_should_enter_door; then print -r -- "NONINTERACTIVE_OPEN"; exit 1; fi
      print -r -- DOOR_ZSH_OK
    ' >"$tmp/zsh.out" 2>"$tmp/zsh.err" || true
    if grep -q DOOR_ZSH_OK "$tmp/zsh.out"; then
      log_success "Begin is the only mint; Resume attaches; AI editors and non-TTY shells skip"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "zsh door decisions: $(cat "$tmp/zsh.out" "$tmp/zsh.err" 2>/dev/null)"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    mkdir -p "$tmp/home/bin" "$tmp/home/zellij"
    cat > "$tmp/home/bin/potions" << 'EOF'
#!/bin/bash
printf '%s\n' "door" >> "${DOOR_LOG:?}"
exit 0
EOF
    chmod +x "$tmp/home/bin/potions"
    cat > "$stub/zellij" << 'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "${DOOR_LOG:?}"
case "$*" in
  *"attach golden-cauldron"*)
    printf '%s\n' "Session attached to another client. Use --force flag to force connect." >&2
    exit 1
    ;;
esac
exit 0
EOF
    : > "$log"
    DOOR_HOME="$tmp/home"
    export DOOR_HOME
    zsh --no-rcs -c '
      source "$DOOR_ZSHRC" >/dev/null 2>&1 || true
      HISTFILE=/dev/null
      export PATH="$DOOR_STUB:$PATH"
      export POTIONS_HOME="$DOOR_HOME"
      _potions_living_mood() { print -r -- golden-cauldron; }
      _potions_open_door
    ' >"$tmp/busy.out" 2>"$tmp/busy.err" || true
    if grep -q "door" "$log" && grep -q "attach golden-cauldron" "$log" && ! grep -q -- "--force" "$log"; then
      log_success "A mood already open in another terminal gets the door, not a second client"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "Occupied mood still forced a client: $(cat "$log" "$tmp/busy.err" 2>/dev/null)"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    cat > "$stub/zellij" << 'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "${DOOR_LOG:?}"
exit 0
EOF
    chmod +x "$stub/zellij"
  else
    log_skip "zsh door decisions skipped (zsh not in PATH)"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
  fi

  : > "$log"
  DOOR_LOG="$log"
  door_status=0
  PATH="$stub:$saved_path" DOOR_LOG="$log" bash "$SCRIPT_DIR/.potions/bin/potions" door </dev/null >"$tmp/door.out" 2>"$tmp/door.err" || door_status=$?
  PATH="$saved_path"
  if [ "$door_status" -eq 0 ] && ! grep -q . "$log" 2>/dev/null; then
    log_success "Non-TTY door does not attach"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "Non-TTY door status=${door_status} log=$(cat "$log" 2>/dev/null) err=$(cat "$tmp/door.err" 2>/dev/null)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  if command -v python3 >/dev/null 2>&1 && command -v zsh >/dev/null 2>&1; then
    DOOR_REPO="$SCRIPT_DIR"
    export DOOR_REPO DOOR_LOG DOOR_STUB
    : > "$log"
    door_pty_status=0
    if python3 - "$tmp" << 'PY'
import os, pty, select, subprocess, sys, time

repo = os.environ["DOOR_REPO"]
log = os.environ["DOOR_LOG"]
stub = os.environ["DOOR_STUB"]
mode = sys.argv[1]

def run(argv, env, payload, timeout):
    try:
        master, slave = pty.openpty()
    except OSError:
        sys.stderr.write("SKIP_NO_PTY\n")
        sys.exit(10)
    proc = subprocess.Popen(argv, stdin=slave, stdout=slave, stderr=slave, env=env)
    os.close(slave)
    if payload:
        time.sleep(0.3)
        os.write(master, payload)
    buf = b""
    deadline = time.time() + timeout
    while time.time() < deadline:
        if proc.poll() is not None:
            break
        ready, _, _ = select.select([master], [], [], 0.2)
        if master in ready:
            try:
                chunk = os.read(master, 4096)
            except OSError:
                break
            if not chunk:
                break
            buf += chunk
            if b"SHELL_OPEN" in buf and b"AI_SKIP" in buf:
                break
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=2)
    try:
        os.close(master)
    except OSError:
        pass
    return proc.returncode, buf

env = os.environ.copy()
if mode == "quit":
    env["PATH"] = stub + os.pathsep + env.get("PATH", "")
    env["DOOR_LOG"] = log
    code, _buf = run(["bash", os.path.join(repo, ".potions/bin/potions"), "door"], env, b"rq", 6)
    text = open(log, encoding="utf-8", errors="replace").read()
    if code not in (0, None) and code != 0:
        sys.stderr.write("quit exit %s\n%s\n" % (code, text))
        sys.exit(1)
    if "attach" in text or "zsh " in text:
        sys.stderr.write(text)
        sys.exit(1)
    if "list-sessions" not in text:
        sys.stderr.write("expected list-sessions, got:\n" + text)
        sys.exit(1)
    sys.exit(0)

env["PATH"] = stub + os.pathsep + env.get("PATH", "")
env["DOOR_ZSHRC"] = os.path.join(repo, ".potions/.zshrc")
script = r'''
ZELLIJ=1
source "$DOOR_ZSHRC" >/dev/null 2>&1 || true
HISTFILE=/dev/null
unset ZELLIJ
unset CURSOR_TERMINAL VSCODE_INJECTION VSCODE_PID INTELLIJ_TERMINAL CLAUDECODE
TERM_PROGRAM=potions-test
CURSOR_TERMINAL=1
if _potions_personal_shell_should_enter_door; then
  print -r -- AI_OPEN
else
  print -r -- AI_SKIP
fi
unset CURSOR_TERMINAL
TERM_PROGRAM=potions-test
if _potions_personal_shell_should_enter_door; then
  print -r -- SHELL_OPEN
else
  print -r -- SHELL_SKIP
fi
'''
code, buf = run(["zsh", "--no-rcs", "-i", "-c", script], env, b"", 25)
text = buf.decode("utf-8", "replace")
if "AI_SKIP" not in text or "SHELL_OPEN" not in text:
    sys.stderr.write(text[-2000:])
    sys.exit(1)
sys.exit(0)
PY
    then
      door_pty_status=0
    else
      door_pty_status=$?
    fi
    if [ "$door_pty_status" -eq 10 ]; then
      log_skip "AI-editor terminal probe skipped (no pty)"
      TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    elif [ "$door_pty_status" -eq 0 ]; then
      log_success "An interactive AI editor skips the door; a personal shell would open it"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "AI-editor terminal probe failed"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  else
    log_skip "Terminal door probe skipped (python3 or zsh missing)"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
  fi

  # The python block above expects a mode argument. Drive both probes explicitly.
  if command -v python3 >/dev/null 2>&1; then
    : > "$log"
    quit_pty_status=0
    if DOOR_REPO="$SCRIPT_DIR" DOOR_LOG="$log" DOOR_STUB="$stub" python3 - quit << 'PY'
import os, pty, select, subprocess, sys, time
repo = os.environ["DOOR_REPO"]
log = os.environ["DOOR_LOG"]
stub = os.environ["DOOR_STUB"]
env = os.environ.copy()
env["PATH"] = stub + os.pathsep + env.get("PATH", "")
env["DOOR_LOG"] = log
try:
    master, slave = pty.openpty()
except OSError:
    sys.stderr.write("SKIP_NO_PTY\n")
    sys.exit(10)
proc = subprocess.Popen(
    ["bash", os.path.join(repo, ".potions/bin/potions"), "door"],
    stdin=slave, stdout=slave, stderr=slave, env=env,
)
os.close(slave)
sent = False
deadline = time.time() + 6
while time.time() < deadline and proc.poll() is None:
    ready, _, _ = select.select([master], [], [], 0.1)
    if master in ready:
        try:
            os.read(master, 4096)
        except OSError:
            break
    if not sent and "list-sessions" in open(log, encoding="utf-8", errors="replace").read():
        os.write(master, b"q")
        sent = True
if proc.poll() is None:
    proc.kill()
    proc.wait(timeout=2)
text = open(log, encoding="utf-8", errors="replace").read()
try:
    os.close(master)
except OSError:
    pass
if not sent or proc.returncode != 0 or "attach" in text or "list-sessions" not in text:
    sys.stderr.write("code=%s sent=%s\n%s\n" % (proc.returncode, sent, text))
    sys.exit(1)
sys.exit(0)
PY
    then
      quit_pty_status=0
    else
      quit_pty_status=$?
    fi
    if [ "$quit_pty_status" -eq 10 ]; then
      log_skip "Quit terminal probe skipped (no pty)"
      TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    elif [ "$quit_pty_status" -eq 0 ]; then
      log_success "Quit and inert Resume on a terminal do not attach"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      log_failure "Quit on a terminal attached or never listed sessions"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  fi

  unset POTIONS_SESSION POTIONS_DOOR_LIST_FIXTURE POTIONS_DOOR_NOTICE POTIONS_DOOR_ZSHRC DOOR_LOG DOOR_ZSHRC DOOR_STUB DOOR_REPO
  if [ "$had_session" -eq 1 ]; then
    POTIONS_SESSION="$saved_session"
  fi
  if [ "$had_zellij" -eq 1 ]; then
    ZELLIJ="$saved_zellij"
  else
    unset ZELLIJ
  fi
  PATH="$saved_path"
  rm -rf "$tmp"
}

test_help_frame() {
  log_step "Help Frame"

  local tmp out plain top line header zellij zsh neovim footer note keybind
  local saved_path saved_term saved_home saved_has_color saved_has_unicode
  local saved_width saved_color_key saved_color_dim saved_color_brand
  local saved_color_value saved_color_muted saved_color_warm saved_nc
  local saved_cterm_primary saved_cterm_surface saved_cterm_select_fg
  local had_term had_home over xs faint hint_line sub door_out
  local living_name="golden-cauldron"

  tmp=$(mktemp -d)
  saved_path="$PATH"
  had_term=0
  if [ -n "${TERM+x}" ]; then
    had_term=1
    saved_term="$TERM"
  fi
  had_home=0
  if [ -n "${POTIONS_HOME+x}" ]; then
    had_home=1
    saved_home="$POTIONS_HOME"
  fi
  saved_has_color="${POTIONS_HAS_COLOR:-}"
  saved_has_unicode="${POTIONS_HAS_UNICODE:-}"
  saved_width="${POTIONS_DISPLAY_WIDTH:-}"
  saved_color_key="${POTIONS_COLOR_KEY:-}"
  saved_color_dim="${POTIONS_COLOR_DIM:-}"
  saved_color_brand="${POTIONS_COLOR_BRAND:-}"
  saved_color_value="${POTIONS_COLOR_VALUE:-}"
  saved_color_muted="${POTIONS_COLOR_MUTED:-}"
  saved_color_warm="${POTIONS_COLOR_WARM:-}"
  saved_nc="${POTIONS_NC:-}"
  saved_cterm_primary="${POTIONS_CTERM_PRIMARY:-}"
  saved_cterm_surface="${POTIONS_CTERM_SURFACE:-}"
  saved_cterm_select_fg="${POTIONS_CTERM_SELECT_FG:-}"

  # shellcheck source=/dev/null
  . "$SCRIPT_DIR/.potions/lib/door.sh"

  POTIONS_COLOR_BRAND='\033[0;35m'
  POTIONS_COLOR_DIM='\033[0;36m'
  POTIONS_COLOR_KEY='\033[1;33m'
  POTIONS_COLOR_WARM='\033[33m'
  POTIONS_COLOR_VALUE='\033[1;37m'
  POTIONS_COLOR_MUTED='\033[2;37m'
  POTIONS_NC='\033[0m'
  unset POTIONS_CTERM_PRIMARY POTIONS_CTERM_SURFACE POTIONS_CTERM_SELECT_FG

  _help_first_plain() {
    local stripped
    stripped=$(potions_door_strip_ansi "$1")
    printf '%s\n' "$stripped" | sed '/^$/d' | head -1
  }

  _help_plain_nth() {
    local stripped
    stripped=$(potions_door_strip_ansi "$1")
    printf '%s\n' "$stripped" | sed '/^$/d' | sed -n "$2p"
  }

  # AC-001, AC-002, AC-003
  POTIONS_HAS_UNICODE=true
  POTIONS_HAS_COLOR=false
  POTIONS_DISPLAY_WIDTH=72
  TERM=linux
  header=$(render_popup_header "" || true)
  top=$(_help_first_plain "$header")
  if printf '%s\n' "$top" | grep -qE '^\+-{1,}\+$'; then
    log_success "AC-001 Linux-console help top rule is plus and hyphens"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-001 help top rule was '${top}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  if printf '%s\n' "$top" | grep -q '='; then
    log_failure "AC-002 Linux-console help top rule contained an equals sign"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "AC-002 Linux-console help top rule has no equals sign"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi
  if printf '%s\n' "$header" | grep -qF '╭'; then
    log_failure "AC-003 Linux-console help header still has a rounded corner"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "AC-003 Linux-console help header has no rounded corner"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  # AC-004
  TERM=xterm-256color
  POTIONS_HAS_UNICODE=true
  POTIONS_HAS_COLOR=false
  header=$(render_popup_header "" || true)
  if printf '%s\n' "$header" | grep -qF '╭'; then
    log_success "AC-004 Unicode help header keeps the rounded corner"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-004 Unicode help header missed the rounded corner"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # AC-005, AC-006, AC-007
  POTIONS_HAS_COLOR=true
  POTIONS_COLOR_KEY='[KEY]'
  POTIONS_COLOR_DIM='[DIM]'
  header=$(render_popup_header "" || true)
  if printf '%s\n' "$header" | grep -qF '[KEY]potions'; then
    log_success "AC-005 help title uses the warm key color"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-005 help title missed [KEY]potions"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  if printf '%s\n' "$header" | grep -qF '[DIM]your cozy dev environment'; then
    log_success "AC-006 help tagline uses the cool color"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-006 help tagline missed [DIM]your cozy dev environment"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  header=$(render_popup_header "1.2.3" || true)
  plain=$(potions_door_strip_ansi "$header")
  if printf '%s\n' "$plain" | grep -q 'v1.2.3'; then
    log_success "AC-007 passed version appears on the help subtitle"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-007 subtitle missed v1.2.3"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # AC-008
  POTIONS_COLOR_BRAND='[BRAND]'
  POTIONS_HAS_COLOR=true
  line=$(render_section_header "Zellij - Multiplexer" || true)
  if printf '%s\n' "$line" | grep -qF '[BRAND]'; then
    log_success "AC-008 section rules use the brand color"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-008 section header missed [BRAND]"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # AC-009
  POTIONS_HAS_COLOR=false
  POTIONS_HAS_UNICODE=true
  TERM=xterm-256color
  line=$(render_section_header "Zellij - Multiplexer" || true)
  plain=$(potions_door_strip_ansi "$line")
  if printf '%s\n' "$plain" | grep -qF -- '--'; then
    log_failure "AC-009 colorless Unicode section rule used an ASCII hyphen pair"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "AC-009 colorless Unicode section rule is not an ASCII hyphen pair"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  POTIONS_COLOR_BRAND='\033[0;35m'
  POTIONS_COLOR_DIM='\033[0;36m'
  POTIONS_COLOR_KEY='\033[1;33m'

  # AC-010, AC-011, AC-012, AC-013, AC-014
  POTIONS_DISPLAY_WIDTH=72
  POTIONS_HAS_COLOR=false
  POTIONS_HAS_UNICODE=true
  TERM=xterm-256color
  header=$(render_popup_header "1.2.3" || true)
  zellij=$(help_section_zellij || true)
  zsh=$(help_section_zsh || true)
  neovim=$(help_section_neovim || true)
  footer=$(render_popup_footer || true)
  plain=$(potions_door_strip_ansi "${header}
${zellij}
${zsh}
${neovim}
${footer}")
  over=0
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "${#line}" -gt 72 ]; then
      over=1
      break
    fi
  done <<EOF
$plain
EOF
  if [ "$over" -eq 0 ]; then
    log_success "AC-010 at width 72 every rendered help line is at most 72 columns"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-010 a help line exceeded 72 columns: '${line}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  if printf '%s\n' "$plain" | grep -qF '…'; then
    log_failure "AC-011 help text contained an ellipsis"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "AC-011 help text contains no ellipsis"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi
  plain=$(potions_door_strip_ansi "$zellij")
  if printf '%s\n' "$plain" | grep -qF 'The Ctrl+a prefix works on every platform. Prefer it.'; then
    log_success "AC-012 prefix note is the short sentence that fits"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-012 zellij section missed the short prefix note"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  if printf '%s\n' "$plain" | grep -qF 'Alt is Option. It needs Option as Meta, or use Ctrl+a.'; then
    log_success "AC-013 macOS note keeps Option-as-Meta and Ctrl+a"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-013 zellij section missed the macOS note"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  if printf '%s\n' "$plain" | grep -qF 'Terminal.app does not forward Ctrl+Tab. Use Alt+n or Alt+p.'; then
    log_success "AC-014 tab note keeps Alt+n and Alt+p"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-014 zellij section missed the Terminal.app note"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # AC-015
  POTIONS_DISPLAY_WIDTH=72
  footer=$(render_popup_footer || true)
  plain=$(potions_door_strip_ansi "$footer")
  if printf '%s\n' "$plain" | grep -qF 'Customize: ~/.potions/zellij/user.kdl | ~/.potions/config/aliases.zsh'; then
    log_success "AC-015 footer keeps both config paths with a single-space separator"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-015 footer missed the single-space path separator"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # AC-016
  POTIONS_HAS_COLOR=true
  POTIONS_COLOR_MUTED=$'\033[2;37m'
  footer=$(render_popup_footer || true)
  faint=$'\033[2;'
  hint_line=$(printf '%s\n' "$footer" | grep 'user.kdl' | head -1 || true)
  if printf '%s\n' "$hint_line" | grep -qF "$faint"; then
    log_failure "AC-016 faint muted sequence was used as the footer hint color"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "AC-016 a faint muted sequence is not the footer hint color"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  # AC-017
  POTIONS_HAS_COLOR=true
  POTIONS_COLOR_MUTED=$'\033[38;5;188m'
  note=$(render_note_row "themed note" || true)
  if printf '%s\n' "$note" | grep -qF '38;5;188'; then
    log_success "AC-017 a themed muted note still uses 38;5;188"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-017 themed note missed 38;5;188"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # AC-018, AC-019
  POTIONS_COLOR_MUTED=$'\033[2;37m'
  note=$(render_note_row "No living mood to resume." || true)
  plain=$(potions_door_strip_ansi "$note")
  if [ "$plain" = "    # No living mood to resume." ]; then
    log_success "AC-018 a door notice keeps the     #  prefix"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-018 notice line was '${plain}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  POTIONS_HAS_COLOR=true
  note=$(render_note_row "No living mood to resume." || true)
  if printf '%s\n' "$note" | grep -qF "$faint"; then
    log_failure "AC-019 faint muted sequence was used as the note color"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "AC-019 a faint muted sequence is not the note color"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  # AC-020, AC-021
  POTIONS_DISPLAY_WIDTH=72
  xs=$(_potions_repeat x 200)
  note=$(render_note_row "$xs" || true)
  plain=$(potions_door_strip_ansi "$note")
  if [ "${#plain}" -eq 72 ]; then
    log_success "AC-020 an overlong note is cut to 72 columns"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-020 overlong note length was ${#plain}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  case "$plain" in
    "    # "*)
      log_success "AC-021 that cut note still starts with     # "
      TESTS_PASSED=$((TESTS_PASSED + 1))
      ;;
    *)
      log_failure "AC-021 cut note prefix was '${plain}'"
      TESTS_FAILED=$((TESTS_FAILED + 1))
      ;;
  esac

  # AC-022
  POTIONS_DISPLAY_WIDTH=72
  keybind=$(render_keybind_row "Ctrl+a" "$xs" || true)
  plain=$(potions_door_strip_ansi "$keybind")
  if [ "${#plain}" -eq 72 ]; then
    log_success "AC-022 an overlong keybind row is cut to 72 columns"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-022 overlong keybind length was ${#plain}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # AC-023
  POTIONS_DISPLAY_WIDTH=72
  POTIONS_HAS_COLOR=false
  POTIONS_HAS_UNICODE=false
  header=$(render_popup_header "$xs" || true)
  sub=$(_help_plain_nth "$header" 3)
  if [ "${#sub}" -eq 72 ]; then
    log_success "AC-023 an overlong subtitle is cut to the frame width"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-023 overlong subtitle length was ${#sub} ('${sub}')"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Theme home for selection ink (AC-024 through AC-028)
  POTIONS_HOME="$tmp/theme-home"
  mkdir -p "$POTIONS_HOME/config"
  ln -s "$SCRIPT_DIR/.potions/themes" "$POTIONS_HOME/themes"

  _help_door_colored() {
    local variant="$1"
    printf '%s\n' "alchemists-orchid:${variant}" > "$POTIONS_HOME/config/theme.conf"
    (
      detect_terminal_capabilities() {
        POTIONS_HAS_COLOR=true
        POTIONS_HAS_UNICODE=true
        POTIONS_DISPLAY_WIDTH=72
        _potions_apply_palette
      }
      tput() {
        case "$1" in
          cols) echo 100 ;;
          lines) echo 40 ;;
          *) echo 0 ;;
        esac
      }
      potions_door_render "$living_name" 0
    )
  }

  door_out=$(_help_door_colored white || true)
  if printf '%s\n' "$door_out" | grep -qF $'\033[1;48;5;91;38;5;236m'; then
    log_success "AC-024 white selection is 1;48;5;91;38;5;236"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-024 white selection sequence was missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  if printf '%s\n' "$door_out" | grep -qF '38;5;255'; then
    log_failure "AC-025 white selection used paper index 255"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "AC-025 white selection does not use paper index 255"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  door_out=$(_help_door_colored sepia || true)
  if printf '%s\n' "$door_out" | grep -qF $'\033[1;48;5;90;38;5;236m'; then
    log_success "AC-026 sepia selection is 1;48;5;90;38;5;236"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-026 sepia selection sequence was missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  if printf '%s\n' "$door_out" | grep -qF '38;5;254'; then
    log_failure "AC-027 sepia selection used paper index 254"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "AC-027 sepia selection does not use paper index 254"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  door_out=$(_help_door_colored dark || true)
  if printf '%s\n' "$door_out" | grep -qF $'\033[1;48;5;176;38;5;236m'; then
    log_success "AC-028 dark selection stays 1;48;5;176;38;5;236"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-028 dark selection sequence was missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # AC-029, AC-030
  door_out=$(
    detect_terminal_capabilities() {
      POTIONS_HAS_COLOR=false
      POTIONS_HAS_UNICODE=true
      POTIONS_DISPLAY_WIDTH=72
    }
    tput() {
      case "$1" in
        cols) echo 100 ;;
        lines) echo 40 ;;
        *) echo 0 ;;
      esac
    }
    potions_door_render "$living_name" 0
  ) || true
  plain=$(potions_door_strip_ansi "$door_out")
  top=$(printf '%s\n' "$plain" | sed '/^$/d' | head -1)
  if [ "${#top}" -eq 66 ]; then
    log_success "AC-029 the default door top rule is 66 columns"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-029 door top rule length was ${#top} ('${top}')"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  if printf '%s\n' "$plain" | grep -qF '~  v'; then
    log_failure "AC-030 the door render contained a version marker"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "AC-030 the door render has no version marker"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  # AC-031
  door_out=$(
    TERM=linux
    detect_terminal_capabilities() {
      POTIONS_HAS_COLOR=false
      POTIONS_HAS_UNICODE=true
      POTIONS_DISPLAY_WIDTH=72
    }
    tput() {
      case "$1" in
        cols) echo 100 ;;
        lines) echo 40 ;;
        *) echo 0 ;;
      esac
    }
    potions_door_render "$living_name" 0
  ) || true
  plain=$(potions_door_strip_ansi "$door_out")
  top=$(printf '%s\n' "$plain" | sed '/^$/d' | head -1)
  if printf '%s\n' "$top" | grep -qE '^\+=+\+$'; then
    log_success "AC-031 Linux-console door rule stays plus and equals"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-031 Linux-console door top rule was '${top}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # AC-032, AC-033
  mkdir -p "$tmp/tput40" "$tmp/tput140"
  printf '%s\n' '#!/bin/bash' 'if [ "$1" = cols ]; then echo 40; exit 0; fi' 'echo 0' > "$tmp/tput40/tput"
  printf '%s\n' '#!/bin/bash' 'if [ "$1" = cols ]; then echo 140; exit 0; fi' 'echo 0' > "$tmp/tput140/tput"
  chmod +x "$tmp/tput40/tput" "$tmp/tput140/tput"
  PATH="$tmp/tput40:$saved_path"
  detect_terminal_capabilities || true
  if [ "${POTIONS_DISPLAY_WIDTH:-}" = "72" ]; then
    log_success "AC-032 help width clamps 40 columns up to 72"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-032 width at 40 cols was '${POTIONS_DISPLAY_WIDTH:-}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  PATH="$tmp/tput140:$saved_path"
  detect_terminal_capabilities || true
  if [ "${POTIONS_DISPLAY_WIDTH:-}" = "100" ]; then
    log_success "AC-033 help width clamps 140 columns down to 100"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-033 width at 140 cols was '${POTIONS_DISPLAY_WIDTH:-}'"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  PATH="$saved_path"

  # AC-034, AC-035
  POTIONS_HAS_COLOR=true
  POTIONS_COLOR_MUTED=$'\033[2;37m'
  door_out=$(
    detect_terminal_capabilities() {
      POTIONS_HAS_COLOR=true
      POTIONS_HAS_UNICODE=true
      POTIONS_DISPLAY_WIDTH=72
    }
    tput() {
      case "$1" in
        cols) echo 100 ;;
        lines) echo 40 ;;
        *) echo 0 ;;
      esac
    }
    potions_door_render "$living_name" 0
  ) || true
  plain=$(potions_door_strip_ansi "$door_out")
  if printf '%s\n' "$plain" | grep -qF 'j k move    enter open'; then
    log_success "AC-034 the door hint text survives the shared quiet-color helper"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "AC-034 door hint text was missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  hint_line=$(printf '%s\n' "$door_out" | grep 'j k move' | head -1 || true)
  if printf '%s\n' "$hint_line" | grep -qF "$faint"; then
    log_failure "AC-035 the door hint was faint when muted is SGR 2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  else
    log_success "AC-035 the door hint is not faint when muted is SGR 2"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi

  unset -f _help_first_plain _help_plain_nth _help_door_colored

  if [ "$had_term" -eq 1 ]; then
    TERM="$saved_term"
    export TERM
  else
    unset TERM
  fi
  if [ "$had_home" -eq 1 ]; then
    POTIONS_HOME="$saved_home"
  else
    unset POTIONS_HOME
  fi
  if [ -n "$saved_has_color" ]; then
    POTIONS_HAS_COLOR="$saved_has_color"
  else
    unset POTIONS_HAS_COLOR
  fi
  if [ -n "$saved_has_unicode" ]; then
    POTIONS_HAS_UNICODE="$saved_has_unicode"
  else
    unset POTIONS_HAS_UNICODE
  fi
  if [ -n "$saved_width" ]; then
    POTIONS_DISPLAY_WIDTH="$saved_width"
  else
    unset POTIONS_DISPLAY_WIDTH
  fi
  if [ -n "$saved_color_key" ]; then POTIONS_COLOR_KEY="$saved_color_key"; else unset POTIONS_COLOR_KEY; fi
  if [ -n "$saved_color_dim" ]; then POTIONS_COLOR_DIM="$saved_color_dim"; else unset POTIONS_COLOR_DIM; fi
  if [ -n "$saved_color_brand" ]; then POTIONS_COLOR_BRAND="$saved_color_brand"; else unset POTIONS_COLOR_BRAND; fi
  if [ -n "$saved_color_value" ]; then POTIONS_COLOR_VALUE="$saved_color_value"; else unset POTIONS_COLOR_VALUE; fi
  if [ -n "$saved_color_muted" ]; then POTIONS_COLOR_MUTED="$saved_color_muted"; else unset POTIONS_COLOR_MUTED; fi
  if [ -n "$saved_color_warm" ]; then POTIONS_COLOR_WARM="$saved_color_warm"; else unset POTIONS_COLOR_WARM; fi
  if [ -n "$saved_nc" ]; then POTIONS_NC="$saved_nc"; else unset POTIONS_NC; fi
  if [ -n "$saved_cterm_primary" ]; then POTIONS_CTERM_PRIMARY="$saved_cterm_primary"; else unset POTIONS_CTERM_PRIMARY; fi
  if [ -n "$saved_cterm_surface" ]; then POTIONS_CTERM_SURFACE="$saved_cterm_surface"; else unset POTIONS_CTERM_SURFACE; fi
  if [ -n "$saved_cterm_select_fg" ]; then POTIONS_CTERM_SELECT_FG="$saved_cterm_select_fg"; else unset POTIONS_CTERM_SELECT_FG; fi
  PATH="$saved_path"
  rm -rf "$tmp"
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
  test_no_local_outside_functions
  test_config_validity
  test_door
  test_help_frame
  test_install_script
  test_common_packages
  test_upgrade_script
  test_documentation
  test_platform_detection
  test_theme_system
  test_terminal_emulator_support
  test_reload_system
  test_terminal_reload

  # Run Termux-specific tests if in Termux environment
  source "$SCRIPT_DIR/packages/accessories.sh" 2>/dev/null || true
  if is_termux; then
    test_termux_shell_setup
    test_termux_package_manager
    test_termux_environment
  fi

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

# Run main unless a caller sourced this file to invoke one group.
if [ "${POTIONS_TEST_LIBRARY:-}" != 1 ]; then
  main "$@"
fi
