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
  assert_file_contains "$tmp/nvim/generated/palette.vim" "alchemists-orchid-light" "nvim white uses light colorscheme"

  local st
  st=$(POTIONS_HOME="$tmp" bash -c '. "'"$theme_lib"'/state.sh"; theme_state_read')
  if [ "$st" = "alchemists-orchid:white" ]; then
    log_success "set: state updated to white"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    log_failure "set: state not updated ('$st')"
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
  test_install_script
  test_common_packages
  test_upgrade_script
  test_documentation
  test_platform_detection
  test_theme_system
  test_terminal_emulator_support

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

# Run main
main "$@"
