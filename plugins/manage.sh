#!/bin/bash

PLUGINS_DIR="plugins"

source "$(dirname "$0")/packages/accessories.sh"


# Main function to manage plugins
manage_plugins() {
  local action=$1
  local plugin_name=$2

  case $action in
    install)
      safe_source "$(dirname "$0")/plugins/obtain.sh"
      safe_source "$(dirname "$0")/plugins/install.sh"
      obtain_plugins
      install_plugins
      ;;
    create)
      safe_source "$(dirname "$0")/plugins/generators.sh" create "$plugin_name"
      ;;
    *)
      echo "Usage: $0 {install|create <plugin_name>}"
      ;;
  esac
}

