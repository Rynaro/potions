#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"


# Function to install TMUX
install_package() {
  if command_exists tmux; then
    echo "TMUX is already installed."
  else
    echo "Installing TMUX..."
    if is_macos; then
      safe_source "$(dirname "$0")/packages/macos/tmux.sh"
    elif is_termux; then
      safe_source "$(dirname "$0")/packages/termux/tmux.sh"
    elif is_wsl; then
      safe_source "$(dirname "$0")/packages/wsl/tmux.sh"
    elif is_linux; then
      safe_source "$(dirname "$0")/packages/debian/tmux.sh"
    fi
  fi
}

configure_package() {
  git clone https://github.com/tmux-plugins/tpm ~/.potions/tmux/plugins/tpm
}

install_package
configure_package
