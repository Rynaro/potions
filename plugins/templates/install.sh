#!/bin/bash

PLUGIN_NAME="$plugin_name"
PLUGIN_VERSION="0.0.1"
PLUGIN_RELATIVE_FOLDER='$(dirname "$0")/"$1"'

# Source utilities script
source "$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to prepare to install packages
prepare() {
  # update_repositories
}

# Function to install packages
install_packages() {
  echo "Installing Plugin: $plugin_name..."
  safe_source "packages/package1.sh"
}

# Function to consolidate post-installation scripts
post_install() {
  # Add your post install scripts
}

# Run pipeline
configure
install_packages
post_install
