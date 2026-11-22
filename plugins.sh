#!/bin/bash

# Potions Plugin Manager CLI
# Manage Potions plugins: install, uninstall, activate, deactivate, update, etc.

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/packages/accessories.sh"

# Source core plugin modules
source "$SCRIPT_DIR/plugins/core/engine.sh"
source "$SCRIPT_DIR/plugins/core/loader.sh"

# Colors for output — Alchemists Orchid Papyrus palette (docs/color-palette.md)
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
MAGENTA=$'\033[0;35m'
CYAN=$'\033[0;36m'
WHITE=$'\033[1;37m'
BOLD=$'\033[1m'
NC=$'\033[0m'

# Check if terminal supports colors
if [ -t 1 ]; then
  HAS_COLOR=true
else
  HAS_COLOR=false
fi

if [ "$HAS_COLOR" = false ] || [ -n "${NO_COLOR:-}" ]; then
  HAS_COLOR=false
  RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' BOLD='' NC=''
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
bootstrap_default_plugins() {
  local name=word-navigation
  local marker="$INSTALLED_PLUGINS_DIR/.defaults/$name"
  # Bundle bytes change with runtime releases, while activation remains user-owned.
  if plugin_is_bundled "$name"; then
    local version
    version=$(get_plugin_version "$INSTALLED_PLUGINS_DIR/$name") || return 1
    if [ "$(lockfile_get_version "$name")" != "$version" ] ||
       [ "$(state_get "$name" | cut -d: -f3)" != "$version" ]; then
      plugin_install "bundled:$name" --force || return 1
      generate_plugin_init || return 1
    fi
  fi
  [ ! -f "$marker" ] || return 0
  # Existing names and records belong to the user, including dangling links.
  if [ ! -e "$INSTALLED_PLUGINS_DIR/$name" ] &&
     [ ! -L "$INSTALLED_PLUGINS_DIR/$name" ] &&
     [ -z "$(state_get "$name")" ] && ! lockfile_has "$name"; then
    plugin_install "bundled:$name" || return 1
  fi
  generate_plugin_init || return 1
  mkdir -p "$(dirname "$marker")" || return 1
  touch "$marker" || return 1
}

cmd_install() {
  local plugin_spec="" result=0 option
  local options=()
  for option in "$@"; do
    case "$option" in
      --trust|--force|--skip-security) options+=("$option") ;;
      -*) log_error "Unknown install option: $option"; return 2 ;;
      *)
        if [ -n "$plugin_spec" ]; then
          log_error "Install accepts one plugin source. Use a Potionfile for several plugins."
          return 2
        fi
        plugin_spec="$option"
        ;;
    esac
  done
  
  if [ -z "$plugin_spec" ]; then
    # Install from Potionfile
    log_info "Installing plugins from Potionfile..."
    plugin_install_from_potionfile "$POTIONS_HOME/Potionfile" "${options[@]}" || result=$?
  else
    # Install specific plugin
    plugin_install "$plugin_spec" "${options[@]}" || return 1
  fi
  
  # Successful entries from a partially failed Potionfile must load as recorded.
  generate_plugin_init || return 1
  return "$result"
}

# Command: uninstall
cmd_uninstall() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    log_error "Usage: $0 uninstall <plugin_name>"
    exit 1
  fi
  
  plugin_uninstall "$plugin_name" || return 1
  
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
  
  plugin_activate "$plugin_name" || return 1
  
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
  
  plugin_deactivate "$plugin_name" || return 1
  
  # Regenerate init script
  generate_plugin_init
}

# Command: update
cmd_update() {
  local plugin_name="${1:---all}"
  shift || true
  plugin_update "$plugin_name" "$@" || return 1
  generate_plugin_init
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
    return 1
  fi
  echo ""
}

# Command: search
cmd_search() {
  plugin_search "${1:-}"
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
  source "$SCRIPT_DIR/plugins/scaffold_plugin.sh"
  create_plugin "$@"
}

# Command: verify
cmd_verify() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    log_error "Usage: $0 verify <plugin_name>"
    exit 1
  fi
  
  local plugin_path="$INSTALLED_PLUGINS_DIR/$plugin_name" installed=true
  if is_local_plugin "$plugin_name"; then
    plugin_path="${plugin_name/#\~/$HOME}"
    installed=false
  elif ! valid_plugin_name "$plugin_name"; then
    log_error "Invalid plugin name: $plugin_name"
    return 1
  fi
  
  if [ ! -d "$plugin_path" ] && [ ! -L "$plugin_path" ]; then
    log_error "Plugin not found: $plugin_name"
    return 1
  fi
  
  if [ -L "$plugin_path" ]; then
    plugin_path=$(readlink "$plugin_path")
  fi
  
  local result=0
  security_audit "$plugin_path" || result=1
  if [ "$installed" = true ]; then
    lockfile_verify "$plugin_name" || result=1
  fi
  return "$result"
}

# Command: validate
cmd_validate() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    log_error "Usage: $0 validate <plugin_name>"
    exit 1
  fi
  
  local plugin_path="$INSTALLED_PLUGINS_DIR/$plugin_name"
  if is_local_plugin "$plugin_name"; then
    plugin_path="${plugin_name/#\~/$HOME}"
  elif ! valid_plugin_name "$plugin_name"; then
    log_error "Invalid plugin name: $plugin_name"
    return 1
  fi
  
  if [ ! -d "$plugin_path" ] && [ ! -L "$plugin_path" ]; then
    log_error "Plugin not found: $plugin_name"
    return 1
  fi
  
  if [ -L "$plugin_path" ]; then
    plugin_path=$(readlink "$plugin_path")
  fi
  
  if validate_plugin "$plugin_path" --require-zsh; then
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

# Command: registry-sync
cmd_registry_sync() {
  # Source registry module
  if [ -z "$REGISTRY_SOURCED" ]; then
    source "$SCRIPT_DIR/plugins/core/registry.sh" 2>/dev/null || {
      log_error "Registry module not available"
      return 1
    }
  fi
  
  if command -v registry_sync > /dev/null 2>&1; then
    registry_sync
  else
    log_error "Registry sync function not available"
    return 1
  fi
}

# Command: registry-status
cmd_registry_status() {
  # Source registry module
  if [ -z "$REGISTRY_SOURCED" ]; then
    source "$SCRIPT_DIR/plugins/core/registry.sh" 2>/dev/null || {
      log_error "Registry module not available"
      return 1
    }
  fi
  
  if command -v registry_status > /dev/null 2>&1; then
    registry_status
  else
    log_error "Registry status function not available"
    return 1
  fi
}

# Command: help
cmd_help() {
  show_banner
  
  cat << EOF
${BOLD}USAGE:${NC}
    potions plugin <command> [options]

${BOLD}COMMANDS:${NC}
    ${CYAN}menu${NC}                      Open the interactive plugin menu
    ${CYAN}install${NC} [plugin]          Install plugins from Potionfile or specific plugin
                             Options: --trust, --force, --skip-security
                             bundled:word-navigation restores the offline default
    
    ${CYAN}uninstall${NC} <plugin>        Uninstall a plugin
    
    ${CYAN}activate${NC} <plugin>         Activate an installed plugin
    
    ${CYAN}deactivate${NC} <plugin>       Deactivate a plugin (without uninstalling)
    
    ${CYAN}update${NC} [plugin|--all]     Update specific plugin or all plugins
    
    ${CYAN}list${NC} [--all|--active|--inactive]
                             List installed plugins
    
    ${CYAN}status${NC}                    Show plugin system status
    
    ${CYAN}search${NC} [query]            Search available plugins
    
    ${CYAN}info${NC} <plugin>             Show plugin details
    
    ${CYAN}create${NC} <name> [--potion]  Create a minimal plugin in the current directory (--potion for YAML)
    
    ${CYAN}verify${NC} <plugin>           Run security audit on a plugin
    
    ${CYAN}validate${NC} <plugin>         Validate plugin structure and manifest
    
    ${CYAN}regenerate-init${NC}           Regenerate the plugin init script
    
    ${CYAN}clean${NC}                     Clean up orphaned entries
    
    ${CYAN}registry-sync${NC}             Sync plugin registry cache
    ${CYAN}registry-status${NC}           Show registry connection status
    
    ${CYAN}help${NC}                      Show this help message

${BOLD}EXAMPLES:${NC}
    # Install all plugins from Potionfile
    potions plugin install
    
    # Review and install a GitHub plugin
    potions plugin install owner/my-plugin@v1.0.0
    
    # Install a local plugin
    potions plugin install ~/my-plugins/custom-theme
    
    # Review and explicitly trust a GitHub repository in scripts
    potions plugin install owner/my-plugin@v1.0.0 --trust

    # Discover and inspect a Shelf package
    potions plugin search
    potions plugin info plugin-hello-world
    potions plugin install plugin-hello-world
    
    # Create a new plugin
    potions plugin create my-awesome-plugin
    
    # List active plugins only
    potions plugin list --active

${BOLD}CONFIGURATION:${NC}
    Potionfile: $POTIONS_HOME/Potionfile
    Plugins:    $POTIONS_HOME/plugins/
    
${BOLD}For more information:${NC}
    https://github.com/Rynaro/potions/blob/main/plugins/README.md

EOF
}

# Menu shares the CLI operations so terminal and scripted behavior stay aligned.
cmd_menu() {
  if [ ! -t 0 ] || [ ! -t 1 ]; then cmd_help; return; fi
  local choice name action
  while true; do
    plugin_list
    printf 'Plugins\n  1 Install Shelf name, GitHub repository or local path\n  2 Enable plugin\n  3 Disable plugin\n  4 Update plugin\n  5 Remove plugin\n  6 Create plugin\n  7 Browse Potions Shelf\n  8 Search Potions Shelf\n  9 Inspect plugin details\n  q Quit\n> '
    IFS= read -r choice || return 0
    case "$choice" in
      q|Q|'') return 0 ;;
      1) action=install ;;
      2) action=activate ;;
      3) action=deactivate ;;
      4) action=update ;;
      5) action=uninstall ;;
      6) action=create ;;
      7) cmd_search || printf 'Catalog browsing failed. Review the message above.\n'; continue ;;
      8) action=search ;;
      9) action=info ;;
      *) printf 'Choose an action from the menu.\n'; continue ;;
    esac
    if [ "$action" = search ]; then
      printf 'Search query> '
    else
      printf 'Plugin %s> ' "$action"
    fi
    IFS= read -r name || return 0
    [ -n "$name" ] || continue
    if [ "$action" = uninstall ]; then
      printf 'Remove %s and run its uninstall hook? [y/N] ' "$name"
      local answer
      IFS= read -r answer || return 0
      case "$answer" in y|Y|yes) ;; *) continue ;; esac
    fi
    # Child processes share validation, mutation locking and error propagation.
    POTIONS_HOME="$POTIONS_HOME" bash "$SCRIPT_DIR/plugins.sh" "$action" "$name" || printf 'Action failed. Review the message above.\n'
  done
}

# Serialize mutations across CLI processes without a platform-specific lock tool.
lock_plugin_operation() {
  ensure_plugin_dirs
  local operation_lock="$INSTALLED_PLUGINS_DIR/.operation-lock"
  if ! mkdir "$operation_lock" 2>/dev/null; then
    local owner=""
    [ ! -f "$operation_lock/pid" ] || IFS= read -r owner < "$operation_lock/pid"
    if [[ "$owner" =~ ^[0-9]+$ ]] && ! kill -0 "$owner" 2>/dev/null; then
      # Only one contender may recover a stale lock. Re-read its owner after
      # acquiring recovery so a newly started operation cannot be removed.
      mkdir "$operation_lock/recovery" 2>/dev/null || return 1
      owner=""
      [ ! -f "$operation_lock/pid" ] || IFS= read -r owner < "$operation_lock/pid"
      if ! [[ "$owner" =~ ^[0-9]+$ ]] || kill -0 "$owner" 2>/dev/null; then
        rmdir "$operation_lock/recovery" 2>/dev/null || true
        return 1
      fi
      rm -f "$operation_lock/pid"
      rmdir "$operation_lock/recovery" || return 1
      rmdir "$operation_lock" 2>/dev/null || return 1
      mkdir "$operation_lock" 2>/dev/null || return 1
    else
      printf 'Another plugin operation is running. If it was interrupted, remove %s after checking.\n' "$operation_lock" >&2
      return 1
    fi
  fi
  printf '%s\n' "$$" > "$operation_lock/pid"
  trap 'rm -f "$INSTALLED_PLUGINS_DIR/.operation-lock/pid"; rmdir "$INSTALLED_PLUGINS_DIR/.operation-lock" 2>/dev/null || true' EXIT
}

# Main command router
main() {
  local command="${1:-menu}"
  shift || true
  
  case "$command" in
    install|uninstall|remove|activate|enable|deactivate|disable|update|upgrade|clean|cleanup|regenerate-init|regen|bootstrap-defaults)
      lock_plugin_operation || return 1 ;;
  esac

  case "$command" in
    bootstrap-defaults) bootstrap_default_plugins ;;
    menu) cmd_menu ;;
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
    registry-sync|sync)
      cmd_registry_sync
      ;;
    registry-status|registry)
      cmd_registry_status
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
