#!/bin/bash

# Potions Plugin Manager CLI
# Manage Potions plugins: install, uninstall, activate, deactivate, update, etc.

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/packages/accessories.sh"

# Source core plugin modules
source "$SCRIPT_DIR/plugins/core/engine.sh"
source "$SCRIPT_DIR/plugins/core/loader.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Check if terminal supports colors
if [ -t 1 ]; then
  HAS_COLOR=true
else
  HAS_COLOR=false
fi

# Logging with colors
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
    echo "[OK] $1"
  fi
}

log_warning() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${YELLOW}${BOLD}⚠${NC} ${YELLOW}$1${NC}"
  else
    echo "[WARN] $1"
  fi
}

log_error() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${RED}${BOLD}✗${NC} ${RED}$1${NC}"
  else
    echo "[ERROR] $1"
  fi
}

# Show banner
show_banner() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${MAGENTA}${BOLD}"
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║       Potions Plugin Manager          ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo -e "${NC}"
  else
    echo ""
    echo "  Potions Plugin Manager"
    echo "  ======================"
    echo ""
  fi
}

# Command: install
cmd_install() {
  local plugin_spec="$1"
  shift || true
  
  if [ -z "$plugin_spec" ]; then
    # Install from Potionfile
    log_info "Installing plugins from Potionfile..."
    plugin_install_from_potionfile
  else
    # Install specific plugin
    plugin_install "$plugin_spec" "$@"
  fi
  
  # Regenerate init script
  generate_plugin_init
}

# Command: uninstall
cmd_uninstall() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    log_error "Usage: $0 uninstall <plugin_name>"
    exit 1
  fi
  
  plugin_uninstall "$plugin_name"
  
  # Regenerate init script
  generate_plugin_init
}

# Command: activate
cmd_activate() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    log_error "Usage: $0 activate <plugin_name>"
    exit 1
  fi
  
  plugin_activate "$plugin_name"
  
  # Regenerate init script
  generate_plugin_init
}

# Command: deactivate
cmd_deactivate() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    log_error "Usage: $0 deactivate <plugin_name>"
    exit 1
  fi
  
  plugin_deactivate "$plugin_name"
  
  # Regenerate init script
  generate_plugin_init
}

# Command: update
cmd_update() {
  local plugin_name="${1:---all}"
  plugin_update "$plugin_name"
}

# Command: list
cmd_list() {
  local filter="${1:---all}"
  plugin_list "$filter"
}

# Command: status
cmd_status() {
  show_banner
  loader_status
  
  # Show lockfile info
  echo "Lockfile Status"
  echo "==============="
  local lockfile_count
  lockfile_count=$(lockfile_count)
  echo "Entries: $lockfile_count"
  echo ""
  
  # Verify lockfile
  if lockfile_verify 2>/dev/null; then
    log_success "Lockfile verification passed"
  else
    log_warning "Lockfile verification found issues"
  fi
  echo ""
}

# Command: search
cmd_search() {
  local query="$1"
  
  if [ -z "$query" ]; then
    log_info "Available verified plugins:"
    list_verified_plugins
  else
    log_info "Searching for: $query"
    plugin_search "$query"
  fi
}

# Command: info
cmd_info() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    log_error "Usage: $0 info <plugin_name>"
    exit 1
  fi
  
  plugin_info "$plugin_name"
}

# Command: create (scaffold new plugin)
cmd_create() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    log_error "Usage: $0 create <plugin_name>"
    exit 1
  fi
  
  source "$SCRIPT_DIR/plugins/scaffold_plugin.sh"
  create_plugin "$plugin_name"
}

# Command: verify
cmd_verify() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    log_error "Usage: $0 verify <plugin_name>"
    exit 1
  fi
  
  local plugin_path="$INSTALLED_PLUGINS_DIR/$plugin_name"
  
  if [ ! -d "$plugin_path" ] && [ ! -L "$plugin_path" ]; then
    # Check if it's a path
    if [ -d "$plugin_name" ]; then
      plugin_path="$plugin_name"
    else
      log_error "Plugin not found: $plugin_name"
      exit 1
    fi
  fi
  
  if [ -L "$plugin_path" ]; then
    plugin_path=$(readlink "$plugin_path")
  fi
  
  security_audit "$plugin_path"
}

# Command: validate
cmd_validate() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    log_error "Usage: $0 validate <plugin_name>"
    exit 1
  fi
  
  local plugin_path="$INSTALLED_PLUGINS_DIR/$plugin_name"
  
  if [ ! -d "$plugin_path" ] && [ ! -L "$plugin_path" ]; then
    # Check if it's a path
    if [ -d "$plugin_name" ]; then
      plugin_path="$plugin_name"
    else
      log_error "Plugin not found: $plugin_name"
      exit 1
    fi
  fi
  
  if [ -L "$plugin_path" ]; then
    plugin_path=$(readlink "$plugin_path")
  fi
  
  if validate_plugin "$plugin_path"; then
    log_success "Plugin validation passed"
  else
    log_error "Plugin validation failed"
    exit 1
  fi
}

# Command: regenerate-init
cmd_regenerate_init() {
  log_info "Regenerating plugin initialization script..."
  generate_plugin_init
  log_success "Init script regenerated"
}

# Command: clean
cmd_clean() {
  log_info "Cleaning up plugin system..."
  loader_cleanup
  lockfile_clean
  log_success "Cleanup complete"
}

# Command: help
cmd_help() {
  show_banner
  
  cat << EOF
${BOLD}USAGE:${NC}
    ./plugins.sh <command> [options]

${BOLD}COMMANDS:${NC}
    ${CYAN}install${NC} [plugin]          Install plugins from Potionfile or specific plugin
                             Options: --force, --skip-security
    
    ${CYAN}uninstall${NC} <plugin>        Uninstall a plugin
    
    ${CYAN}activate${NC} <plugin>         Activate an installed plugin
    
    ${CYAN}deactivate${NC} <plugin>       Deactivate a plugin (without uninstalling)
    
    ${CYAN}update${NC} [plugin|--all]     Update specific plugin or all plugins
    
    ${CYAN}list${NC} [--all|--active|--inactive]
                             List installed plugins
    
    ${CYAN}status${NC}                    Show plugin system status
    
    ${CYAN}search${NC} [query]            Search available plugins
    
    ${CYAN}info${NC} <plugin>             Show plugin details
    
    ${CYAN}create${NC} <name>             Scaffold a new plugin
    
    ${CYAN}verify${NC} <plugin>           Run security audit on a plugin
    
    ${CYAN}validate${NC} <plugin>         Validate plugin structure and manifest
    
    ${CYAN}regenerate-init${NC}           Regenerate the plugin init script
    
    ${CYAN}clean${NC}                     Clean up orphaned entries
    
    ${CYAN}help${NC}                      Show this help message

${BOLD}EXAMPLES:${NC}
    # Install all plugins from Potionfile
    ./plugins.sh install
    
    # Install a specific verified plugin
    ./plugins.sh install Rynaro/potions-docker
    
    # Install a local plugin
    ./plugins.sh install ~/my-plugins/custom-theme
    
    # Install with specific version
    ./plugins.sh install 'Rynaro/potions-docker, tag: v1.0.0'
    
    # Create a new plugin
    ./plugins.sh create my-awesome-plugin
    
    # List active plugins only
    ./plugins.sh list --active

${BOLD}CONFIGURATION:${NC}
    Potionfile: ~/.potions/Potionfile
    Plugins:    ~/.potions/plugins/
    
${BOLD}For more information:${NC}
    https://github.com/Rynaro/potions/blob/main/plugins/README.md

EOF
}

# Main command router
main() {
  local command="${1:-help}"
  shift || true
  
  case "$command" in
    install)
      cmd_install "$@"
      ;;
    uninstall|remove)
      cmd_uninstall "$@"
      ;;
    activate|enable)
      cmd_activate "$@"
      ;;
    deactivate|disable)
      cmd_deactivate "$@"
      ;;
    update|upgrade)
      cmd_update "$@"
      ;;
    list|ls)
      cmd_list "$@"
      ;;
    status)
      cmd_status
      ;;
    search|find)
      cmd_search "$@"
      ;;
    info|show)
      cmd_info "$@"
      ;;
    create|new|scaffold)
      cmd_create "$@"
      ;;
    verify|audit)
      cmd_verify "$@"
      ;;
    validate|check)
      cmd_validate "$@"
      ;;
    regenerate-init|regen)
      cmd_regenerate_init
      ;;
    clean|cleanup)
      cmd_clean
      ;;
    help|--help|-h)
      cmd_help
      ;;
    *)
      log_error "Unknown command: $command"
      echo ""
      cmd_help
      exit 1
      ;;
  esac
}

main "$@"
