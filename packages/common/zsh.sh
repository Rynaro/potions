#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Zsh
install_package() {
  if command_exists zsh; then
    echo "Zsh is already installed."
  else
    echo "Installing Zsh..."
    if is_macos; then
      safe_source "$(dirname "$0")/packages/macos/zsh.sh"
    elif is_termux; then
      safe_source "$(dirname "$0")/packages/termux/zsh.sh"
    elif is_wsl; then
      safe_source "$(dirname "$0")/packages/wsl/zsh.sh"
    elif is_linux; then
      safe_source "$(dirname "$0")/packages/debian/zsh.sh"
    fi
  fi
}

configure_package() {
  # Change the default shell to Zsh
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    cp .zshenv $USER_HOME_FOLDER
    source .zshenv
  fi

  chsh -s zsh
}

install_package
configure_package
