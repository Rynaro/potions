#!/bin/bash

# Plugin deactivation script
# This script is called when deactivating the plugin (without uninstalling)

PLUGIN_NAME="PLUGIN_NAME"
PLUGIN_RELATIVE_FOLDER="$(dirname "$0")"

# Source utilities script
source "$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to deactivate the plugin
deactivate() {
  log "Deactivating plugin: $PLUGIN_NAME..."
  
  # Add deactivation commands here
  # This typically involves:
  # - Disabling configuration files (without removing)
  # - Removing shell aliases/functions from current session
  # - Disabling NeoVim plugins
  # - Disabling tmux configurations
}

# Function for post-deactivation tasks
post_deactivate() {
  log "Plugin $PLUGIN_NAME has been deactivated."
  log "Plugin files are preserved. Use 'activate' to re-enable."
}

# Run deactivation pipeline
deactivate
post_deactivate
