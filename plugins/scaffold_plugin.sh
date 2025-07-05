#!/bin/bash

PLUGINS_DIR="downloaded-plugins"

# Function to create a new plugin scaffold
create_plugin() {
  local plugin_name=$1

  if [ -z "$plugin_name" ]; then
    echo "Usage: $0 create <plugin_name>"
    exit 1
  fi

  # Determine the script's directory for reliable path resolution
  local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Create the plugin directory structure
  local plugin_dir="$PLUGINS_DIR/$plugin_name"
  mkdir -p "$plugin_dir/packages"

  # Create the blank install.sh script
  cat "$SCRIPT_DIR/templates/install.sh" > "$plugin_dir/install.sh"

  # Create utilities.sh
  cat "$SCRIPT_DIR/utilities.sh" > "$plugin_dir/utilities.sh"

  # Create a blank package1.sh script
  cat "$SCRIPT_DIR/templates/package1.sh" > "$plugin_dir/packages/package1.sh"

  # Make the scripts executable
  chmod +x "$plugin_dir/install.sh"
  chmod +x "$plugin_dir/utilities.sh"
  chmod +x "$plugin_dir/packages/package1.sh"

  echo "Plugin $plugin_name has been created at $plugin_dir"
}
