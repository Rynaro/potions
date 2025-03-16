#!/bin/bash

ensure_directory "$USER_HOME_FOLDER/.config/nvim"
ensure_directory "$POTIONS_HOME/plugged"
echo "source $POTIONS_HOME/nvim/init.vim" > ~/.config/nvim/init.vim

local target_dir="${XDG_DATA_HOME:-$USER_HOME_FOLDER/.local/share}/nvim/site/autoload"
local plug_file="$target_dir/plug.vim"

if [ -f "$plug_file" ]; then
  log "Vim-Plug is already installed."
else
  log "Installing Vim-Plug..."
  ensure_directory "$target_dir"
  curl -fLo "$plug_file" https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  log "Installing NeoVim plugins..."

  # Make sure nvim is available
  if ! command_exists nvim; then
    log "ERROR: NeoVim is not installed or not in PATH. Skipping plugin installation."
    return 1
  fi

  # Make sure init.vim is properly set up
  if [ ! -f "$POTIONS_HOME/nvim/init.vim" ]; then
    log "ERROR: NeoVim configuration file not found. Skipping plugin installation."
    return 1
  fi

  # Ensure configuration is linked properly
  if [ ! -f "$HOME/.config/nvim/init.vim" ]; then
    mkdir -p "$HOME/.config/nvim"
    echo "source $POTIONS_HOME/nvim/init.vim" > "$HOME/.config/nvim/init.vim"
  fi

  log "Installing plugins (this may take a minute)..."

  # Run vim in a way that doesn't require user input
  nvim --headless -c "PlugInstall --sync | qall" 2>/dev/null

  # Check if the plugin directory has content
  if [ -d "$HOME/.potions/plugged" ] && [ "$(ls -A "$HOME/.potions/plugged")" ]; then
    log "NeoVim plugins installed successfully."
    return 0
  else
    log "WARNING: NeoVim plugin installation appears to have failed."
    log "You may need to run ':PlugInstall' manually the first time you open NeoVim."
    return 1
  fi
fi
