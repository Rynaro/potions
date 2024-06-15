#!/bin/bash

PLUGINS_DIR="plugins"

# Function to install plugins
install_plugins() {
  for plugin_dir in $PLUGINS_DIR/*; do
    if [ -d "$plugin_dir" ]; then
      repo_name=$(basename "$plugin_dir")
      if [ -f "$plugin_dir/install.sh" ]; then
        bash "$plugin_dir/install.sh"
      else
        echo "No install.sh found for $repo_name"
      fi
    fi
  done
}

# Main function to manage plugins
manage_plugins() {
  local action=$1
  local plugin_name=$2

  case $action in
    install)
      install_plugins
      ;;
    create)
      bash "$(dirname "$0")/plugins/generators.sh" create "$plugin_name"
      ;;
    *)
      echo "Usage: $0 {install|create <plugin_name>}"
      ;;
  esac
}

