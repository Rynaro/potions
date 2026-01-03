#!/bin/bash

# Potions Plugin Generators
# Provides scaffolding and generation utilities for plugins

GENERATORS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$GENERATORS_DIR")"

source "$REPO_ROOT/packages/accessories.sh"

# Function to scaffold a new plugin
scaffold_plugin() {
  local plugin_name="$1"

  if [ -z "$plugin_name" ]; then
    echo "Usage: scaffold_plugin <plugin_name>"
    exit 1
  fi

  source "$GENERATORS_DIR/scaffold_plugin.sh"
  create_plugin "$plugin_name"
}

# Main function to manage plugin generation
manage_plugins() {
  local action="$1"
  local plugin_name="$2"

  case "$action" in
    create|scaffold|new)
      scaffold_plugin "$plugin_name"
      ;;
    *)
      echo "Potions Plugin Generators"
      echo ""
      echo "Usage: $0 <command> <plugin_name>"
      echo ""
      echo "Commands:"
      echo "  create <name>    Create a new plugin scaffold"
      echo "  scaffold <name>  Alias for create"
      echo "  new <name>       Alias for create"
      ;;
  esac
}

# Export for use by other scripts
export -f scaffold_plugin
export -f manage_plugins

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  manage_plugins "$@"
fi
