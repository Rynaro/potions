#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Vim-Plug
install_package() {
  if [ -d "${XDG_DATA_HOME:-$USER_HOME_FOLDER/.local/share}/nvim/site/autoload" ]; then
    echo "Vim-Plug is already installed."
  else
    echo "Installing Vim-Plug..."
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$USER_HOME_FOLDER/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  fi
}

configure_package() {
  mkdir -p $USER_HOME_FOLDER/.config/nvim
  mkdir -p $POTIONS_HOME/plugged
  echo "source $POTIONS_HOME/nvim/init.vim" > ~/.config/nvim/init.vim
}

install_package
configure_package

