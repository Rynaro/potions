#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Zsh
install_package() {
  if command_exists zsh; then
    echo "Zsh is already installed."
  else
    echo "Installing Zsh..."
    if is_macos; then
      safe_source "$(dirname "$0")/../macos/zsh.sh"
    elif is_termux; then
      safe_source "$(dirname "$0")/../termux/zsh.sh"
    elif is_wsl; then
      safe_source "$(dirname "$0")/../wsl/zsh.sh"
    fi
  fi
}

configure_package() {
  # Send the Zsh Stuff out!
  cp -r .potions ~/
  cp .zshenv ~/
  source .zshenv

  # Change the default shell to Zsh
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    if is_termux; then
      chsh -s zsh
    else
      echo "Changing the default shell to Zsh..."
      chsh -s "$(command -v zsh)"
    fi
  fi
}

install_package
configure_package
