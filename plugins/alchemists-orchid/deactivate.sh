#!/bin/bash

# Alchemists Orchid Theme - Deactivation Script

PLUGIN_NAME="alchemists-orchid"
PLUGIN_RELATIVE_FOLDER="$(dirname "$0")"

# Source utilities script
source "$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to deactivate the theme
deactivate() {
  log "Deactivating plugin: $PLUGIN_NAME..."
  
  # Note: The theme will remain installed but won't be loaded
  # User can manually set a different colorscheme in their NeoVim config
  
  log "Theme deactivated"
  log "Your configuration file is preserved"
}

# Function for post-deactivation tasks
post_deactivate() {
  log "Plugin $PLUGIN_NAME has been deactivated."
  log ""
  log "To use a different colorscheme, add to your NeoVim config:"
  log "  colorscheme <your-preferred-theme>"
  log ""
  log "Plugin files are preserved. Use 'activate' to re-enable."
}

# Run deactivation pipeline
deactivate
post_deactivate
