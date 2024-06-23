#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Vim-Plug
install_package() {
  if [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload" ]; then
    echo "Vim-Plug is already installed."
  else
    echo "Installing Vim-Plug..."
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  fi
}

configure_package() {
  mkdir -p $HOME/.config/nvim
  mkdir -p $HOME/.potions/plugged
  echo 'source ~/.potions/nvim/init.vim' > ~/.config/nvim/init.vim
}

if is_termux; then
  echo "Neovim will be configured inside the proot-distro"
elif
  install_package
  configure_package
fi

