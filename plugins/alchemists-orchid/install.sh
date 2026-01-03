#!/bin/bash

PLUGIN_NAME="alchemists-orchid"
PLUGIN_VERSION="1.0.0"
PLUGIN_RELATIVE_FOLDER="$(dirname "$0")"

# Source utilities script
source "$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to prepare installation
prepare() {
  log "Preparing Alchemists Orchid theme installation..."
}

# Function to install the theme
install_packages() {
  log "Installing Plugin: $PLUGIN_NAME..."
  safe_source "packages/theme.sh"
}

# Function to configure the theme
post_install() {
  log "Configuring Alchemists Orchid theme preferences..."
  setup_theme_config
}

# Run pipeline
prepare
install_packages
post_install
