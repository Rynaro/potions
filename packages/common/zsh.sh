#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Zsh
install_package() {
  if command_exists zsh; then
    log "Zsh is already installed."
  else
    log "Installing Zsh..."
    if is_macos; then
      unpack_it 'macos/zsh'
    elif is_termux; then
      unpack_it 'termux/zsh'
    elif is_wsl; then
      unpack_it 'wsl/zsh'
    elif is_linux; then
      unpack_it 'debian/zsh'
    fi
  fi
}

configure_package() {
  # Change the default shell to Zsh
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    cp .zshenv $USER_HOME_FOLDER
    source .zshenv
  fi

  if is_termux; then
    chsh -s zsh
  fi
}

install_package
configure_package
