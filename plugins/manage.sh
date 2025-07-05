#!/bin/bash

PLUGINS_DIR="plugins"

# Determine the script's directory for reliable sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utilities.sh"

# Main function to manage plugins
manage_plugins() {
  local action=$1
  local plugin_name=$2

  case $action in
    install)
      safe_source "$SCRIPT_DIR/obtain.sh"
      safe_source "$SCRIPT_DIR/install.sh"
      obtain_plugins
      install_plugins
      ;;
    create)
      safe_source "$SCRIPT_DIR/generators.sh"
      manage_plugins create $plugin_name
      ;;
    *)
      echo "Usage: $0 {install|create <plugin_name>}"
      ;;
  esac
}

