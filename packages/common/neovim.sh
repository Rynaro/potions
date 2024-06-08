#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Neovim
install_package() {
  if command_exists nvim; then
    echo "Neovim is already installed."
  else
    echo "Installing Neovim..."
    if is_macos; then
      safe_source "$(dirname "$0")/../macos/zsh.sh"
    elif is_wsl; then
      safe_source "$(dirname "$0")/../wsl/zsh.sh"
    elif is_termux; then
      safe_source "$(dirname "$0")/../termux/zsh.sh"
    fi
  fi
}

install_package
