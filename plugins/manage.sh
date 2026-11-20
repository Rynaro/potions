#!/bin/bash

# Potions Plugin Manager - Core Management Module
# This module provides the core plugin management functionality
# Used by plugins.sh CLI and can be sourced by other scripts

PLUGINS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

source "$REPO_ROOT/packages/accessories.sh"

# Source core modules
source "$PLUGINS_DIR/core/engine.sh"
source "$PLUGINS_DIR/core/loader.sh"

# Main function to manage plugins (legacy compatibility)
manage_plugins() {
  POTIONS_HOME="$POTIONS_HOME" bash "$PLUGINS_DIR/../plugins.sh" "$@"
}

# Export functions for use by other scripts
export -f manage_plugins
