#!/bin/bash

# Alchemists Orchid Theme - Activation Script

PLUGIN_NAME="alchemists-orchid"
PLUGIN_RELATIVE_FOLDER="$(dirname "$0")"

# Source utilities script
source "$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to activate the theme
activate() {
  log "Activating plugin: $PLUGIN_NAME..."
  
  # Ensure theme config exists
  setup_theme_config
  
  log "Theme is now active"
  log "The colorscheme will be applied when NeoVim starts"
}

# Function for post-activation tasks
post_activate() {
  log "Plugin $PLUGIN_NAME has been activated."
  log ""
  log "Customize your theme in:"
  log "  $THEME_CONFIG_FILE"
}

# Run activation pipeline
activate
post_activate
