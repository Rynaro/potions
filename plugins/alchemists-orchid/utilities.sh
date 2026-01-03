#!/bin/bash

# Alchemists Orchid Theme - Utilities
# Plugin utilities following Potions plugin system v2.0.0

UTILITIES_VERSION="2.0.0"
PLUGIN_RELATIVE_FOLDER="${PLUGIN_RELATIVE_FOLDER:-$(dirname "$0")}"

# Environment
OS_TYPE="$(uname -s)"
POTIONS_HOME="${POTIONS_HOME:-$HOME/.potions}"
THEME_CONFIG_DIR="$POTIONS_HOME/nvim/lua/theme"
THEME_CONFIG_FILE="$THEME_CONFIG_DIR/alchemists-orchid.lua"

# Logging
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [alchemists-orchid] $*"
}

# Function to safely source a script if it exists
safe_source() {
  local file="$1"
  if [ -f "$PLUGIN_RELATIVE_FOLDER/$file" ]; then
    source "$PLUGIN_RELATIVE_FOLDER/$file"
  elif [ -f "$file" ]; then
    source "$file"
  fi
}

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Platform detection functions
is_macos() {
  [ "$OS_TYPE" = "Darwin" ]
}

is_linux() {
  [ "$OS_TYPE" = "Linux" ]
}

is_termux() {
  [ -n "$PREFIX" ] && [ -x "$PREFIX/bin/termux-info" ]
}

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

# Ensure directory exists
ensure_directory() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    log "Created directory: $dir"
  fi
}

# Setup theme configuration
setup_theme_config() {
  ensure_directory "$THEME_CONFIG_DIR"

  # Only create if it doesn't exist (preserve user customizations)
  if [ ! -f "$THEME_CONFIG_FILE" ]; then
    log "Creating default theme configuration..."
    cp "$PLUGIN_RELATIVE_FOLDER/config/theme.lua" "$THEME_CONFIG_FILE"
    log "Theme configuration created at $THEME_CONFIG_FILE"
  else
    log "Theme configuration already exists, preserving user customizations"
  fi
}

# Remove theme configuration (for uninstall)
remove_theme_config() {
  if [ -f "$THEME_CONFIG_FILE" ]; then
    log "Theme configuration exists at: $THEME_CONFIG_FILE"
    log "Preserving user customizations - remove manually if desired"
  fi
}
