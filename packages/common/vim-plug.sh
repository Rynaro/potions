#!/bin/bash

if [ -d "${XDG_DATA_HOME:-$USER_HOME_FOLDER/.local/share}/nvim/site/autoload" ]; then
   log "Vim-Plug is already installed."
else
  log "Installing Vim-Plug..."
  sh -c 'curl -fLo "${XDG_DATA_HOME:-$USER_HOME_FOLDER/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
fi

ensure_directory "$USER_HOME_FOLDER/.config/nvim"
ensure_directory "$POTIONS_HOME/plugged"
echo "source $POTIONS_HOME/nvim/init.vim" > ~/.config/nvim/init.vim


