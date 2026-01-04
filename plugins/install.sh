#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install plugins
install_plugins() {
  for plugin_dir in $PLUGINS_DIR/*; do
    if [ -d "$plugin_dir" ]; then
      repo_name=$(basename "$plugin_dir")
      if [ -f "$plugin_dir/install.sh" ]; then
        source "$plugin_dir/install.sh" $plugin_dir
      else
        echo "No install.sh found for $repo_name"
      fi
    fi
  done
}
