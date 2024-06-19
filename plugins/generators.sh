#!/bin/bash

# Function to scaffold a new plugin
scaffold_plugin() {
  local plugin_name=$1

  if [ -z "$plugin_name" ]; then
    echo "Usage: $0 create <plugin_name>"
    exit 1
  fi

  bash "$(dirname "$0")/scaffold_plugin.sh" "$plugin_name"
}

# Main function to manage plugins
manage_plugins() {
  local action=$1
  local plugin_name=$2

  case $action in
    create)
      scaffold_plugin "$plugin_name"
      ;;
    *)
      echo "Usage: $0 create <plugin_name>"
      ;;
  esac
}

# Execute the manage_plugins function with provided arguments
manage_plugins "$@"

