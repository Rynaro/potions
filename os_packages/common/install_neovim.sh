#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Function to install Neovim
install_neovim() {
  if command_exists nvim; then
    echo "Neovim is already installed."
  else
    echo "Installing Neovim..."
    if [ "$OS_TYPE" = "Darwin" ]; then
      brew install neovim
    elif [ -n "$(command -v apt-get)" ]; then
      sudo apt-get update
      sudo apt-get install -y neovim
    fi
  fi
}

install_neovim
