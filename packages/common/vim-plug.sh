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
fi
