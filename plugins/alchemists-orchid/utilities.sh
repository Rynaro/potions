#!/bin/bash

UTILITIES_VERSION=1.1.0

OS_TYPE="$(uname -s)"
POTIONS_HOME="${POTIONS_HOME:-$HOME/.potions}"
THEME_CONFIG_DIR="$POTIONS_HOME/nvim/lua/theme"
THEME_CONFIG_FILE="$THEME_CONFIG_DIR/alchemists-orchid.lua"

# Log function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Function to safely source a script if it exists
safe_source() {
  [ -f "$PLUGIN_RELATIVE_FOLDER/$1" ] && source "$PLUGIN_RELATIVE_FOLDER/$1"
}

# Function to check if a command exists
command_exists() {
  local cmd="$1"
  command -v "$cmd" &> /dev/null
}

# Function to check if the environment is macOS
is_macos() {
  [ "$OS_TYPE" = "Darwin" ]
}

# Function to check if the environment is WSL
is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

# Function to check if the environment is Termux
is_termux() {
  [ -n "$PREFIX" ] && [ -x "$PREFIX/bin/termux-info" ]
}

# Function to check if the environment is Linux-based kernel
is_linux() {
  [ "$OS_TYPE" = "Linux" ]
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
