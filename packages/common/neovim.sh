#!/bin/bash

source "$(dirname "$0")/../accessories.sh"

# Function to install Neovim
install_package() {
  if command_exists nvim; then
    echo "Neovim is already installed."
  else
    echo "Installing Neovim..."
    if [ "$OS_TYPE" = "Darwin" ]; then
      brew install neovim
    elif [ -n "$(command -v apt-get)" ]; then
      sudo apt-get install -y neovim
    fi
  fi
}

install_package
