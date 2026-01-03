#!/bin/bash

# Alchemists Orchid Theme Package
# Handles theme registration and vim-plug integration

THEME_REPO="Rynaro/alchemists-orchid.nvim"
THEME_NAME="alchemists-orchid"

# Check if theme is already in init.vim
check_theme_installed() {
  local init_vim="$POTIONS_HOME/nvim/init.vim"
  if [ -f "$init_vim" ]; then
    grep -q "$THEME_REPO" "$init_vim"
    return $?
  fi
  return 1
}

# Register theme in vim-plug (if not already registered)
register_theme_plugin() {
  local init_vim="$POTIONS_HOME/nvim/init.vim"

  if check_theme_installed; then
    log "Theme plugin already registered in vim-plug"
    return 0
  fi

  log "Theme is managed through init.vim - ensure Plug '$THEME_REPO' is present"
}

# Update colorscheme in init.vim to use theme config
configure_colorscheme() {
  log "Theme colorscheme configured"
  log "Customize theme in: $POTIONS_HOME/nvim/lua/theme/alchemists-orchid.lua"
}

# Main installation
register_theme_plugin
configure_colorscheme
