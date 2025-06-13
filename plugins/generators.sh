#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$SCRIPT_DIR")/packages/accessories.sh"

# Function to scaffold a new plugin
scaffold_plugin() {
  local plugin_name=$1

  if [ -z $plugin_name ]; then
    echo "Usage: $0 create <plugin_name>"
    exit 1
  fi

  safe_source "$SCRIPT_DIR/scaffold_plugin.sh"
  create_plugin $plugin_name
}

# Main function to manage plugins
manage_plugins() {
  local action=$1
  local plugin_name=$2

  case $action in
    create)
      scaffold_plugin $plugin_name
      ;;
    *)
      echo "Usage: $0 create <plugin_name>"
      ;;
  esac
}
