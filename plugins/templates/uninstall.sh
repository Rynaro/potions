#!/bin/bash

# Plugin uninstallation script
# This script is called when uninstalling the plugin

PLUGIN_NAME="PLUGIN_NAME"
PLUGIN_RELATIVE_FOLDER="$(dirname "$0")"

# Source utilities script
source "$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to prepare for uninstallation
prepare() {
  log "Preparing to uninstall plugin: $PLUGIN_NAME..."
}

# Function to remove installed files
remove_files() {
  log "Removing plugin files..."
  # Add commands to remove installed files
  # Example: rm -f "$POTIONS_HOME/nvim/lua/plugins/my-plugin.lua"
}

# Function to cleanup configurations
cleanup_config() {
  log "Cleaning up configuration..."
  # Add commands to cleanup any configurations
  # Be careful not to remove user customizations
}

# Function for post-uninstallation tasks
post_uninstall() {
  log "Plugin $PLUGIN_NAME has been uninstalled."
}

# Run uninstall pipeline
prepare
remove_files
cleanup_config
post_uninstall
