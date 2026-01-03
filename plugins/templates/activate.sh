#!/bin/bash

# Plugin activation script
# This script is called when activating the plugin

PLUGIN_NAME="PLUGIN_NAME"
PLUGIN_RELATIVE_FOLDER="$(dirname "$0")"

# Source utilities script
source "$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to activate the plugin
activate() {
  log "Activating plugin: $PLUGIN_NAME..."
  
  # Add activation commands here
  # This typically involves:
  # - Enabling configuration files
  # - Setting up shell aliases/functions
  # - Activating NeoVim plugins
  # - Enabling tmux configurations
}

# Function for post-activation tasks
post_activate() {
  log "Plugin $PLUGIN_NAME has been activated."
  log "You may need to restart your shell for changes to take effect."
}

# Run activation pipeline
activate
post_activate
