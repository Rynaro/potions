#!/bin/bash

# Alchemists Orchid Theme - Uninstallation Script

PLUGIN_NAME="alchemists-orchid"
PLUGIN_RELATIVE_FOLDER="$(dirname "$0")"

# Source utilities script
source "$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to prepare for uninstallation
prepare() {
  log "Preparing to uninstall plugin: $PLUGIN_NAME..."
}

# Function to remove theme configuration
remove_theme_config() {
  log "Theme configuration handling..."
  
  # Note: We don't remove the user's theme config file as they may have customizations
  # Just inform the user
  if [ -f "$THEME_CONFIG_FILE" ]; then
    log "User theme configuration preserved at: $THEME_CONFIG_FILE"
    log "Remove manually if no longer needed"
  fi
}

# Function to cleanup vim-plug reference
cleanup_vimplug() {
  log "Note: Remove 'Plug Rynaro/alchemists-orchid.nvim' from init.vim if desired"
  log "Then run :PlugClean in NeoVim to remove the theme"
}

# Function for post-uninstallation tasks
post_uninstall() {
  log "Plugin $PLUGIN_NAME uninstallation complete."
  log ""
  log "To fully remove the theme:"
  log "  1. Edit ~/.potions/nvim/init.vim"
  log "  2. Remove the Plug 'Rynaro/alchemists-orchid.nvim' line"
  log "  3. Run :PlugClean in NeoVim"
  log "  4. Optionally remove: $THEME_CONFIG_FILE"
}

# Run uninstall pipeline
prepare
remove_theme_config
cleanup_vimplug
post_uninstall
