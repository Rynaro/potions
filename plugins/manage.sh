#!/bin/bash

# Potions Plugin Manager - Core Management Module
# This module provides the core plugin management functionality
# Used by plugins.sh CLI and can be sourced by other scripts

PLUGINS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

source "$REPO_ROOT/packages/accessories.sh"

# Source core modules
source "$PLUGINS_DIR/core/engine.sh"
source "$PLUGINS_DIR/core/loader.sh"

# Main function to manage plugins (legacy compatibility)
manage_plugins() {
  local action="$1"
  local plugin_name="$2"
  shift 2 || true
  
  case "$action" in
    install)
      if [ -z "$plugin_name" ]; then
        plugin_install_from_potionfile
      else
        plugin_install "$plugin_name" "$@"
      fi
      generate_plugin_init
      ;;
    uninstall|remove)
      plugin_uninstall "$plugin_name"
      generate_plugin_init
      ;;
    activate|enable)
      plugin_activate "$plugin_name"
      generate_plugin_init
      ;;
    deactivate|disable)
      plugin_deactivate "$plugin_name"
      generate_plugin_init
      ;;
    update)
      plugin_update "${plugin_name:---all}"
      ;;
    list)
      plugin_list "${plugin_name:---all}"
      ;;
    info)
      plugin_info "$plugin_name"
      ;;
    search)
      plugin_search "$plugin_name"
      ;;
    create|scaffold)
      source "$PLUGINS_DIR/scaffold_plugin.sh"
      create_plugin "$plugin_name"
      ;;
    verify)
      security_audit "$INSTALLED_PLUGINS_DIR/$plugin_name"
      ;;
    validate)
      validate_plugin "$INSTALLED_PLUGINS_DIR/$plugin_name"
      ;;
    status)
      loader_status
      ;;
    regenerate-init)
      generate_plugin_init
      ;;
    clean)
      loader_cleanup
      lockfile_clean
      ;;
    *)
      echo "Potions Plugin Manager"
      echo ""
      echo "Usage: manage_plugins <command> [plugin_name] [options]"
      echo ""
      echo "Commands:"
      echo "  install [plugin]     Install plugins from Potionfile or specific plugin"
      echo "  uninstall <plugin>   Uninstall a plugin"
      echo "  activate <plugin>    Activate an installed plugin"
      echo "  deactivate <plugin>  Deactivate a plugin"
      echo "  update [plugin]      Update plugins"
      echo "  list [filter]        List installed plugins"
      echo "  info <plugin>        Show plugin details"
      echo "  search [query]       Search available plugins"
      echo "  create <name>        Create a new plugin scaffold"
      echo "  verify <plugin>      Run security audit"
      echo "  validate <plugin>    Validate plugin structure"
      echo "  status               Show plugin system status"
      echo "  regenerate-init      Regenerate init script"
      echo "  clean                Clean up orphaned entries"
      ;;
  esac
}

# Export functions for use by other scripts
export -f manage_plugins
