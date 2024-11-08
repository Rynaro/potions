#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install TMUX
install_package() {
  if command_exists tmux; then
    log "TMUX is already installed."
  else
    log "Installing TMUX..."
    if is_macos; then
      unpack_it 'macos/tmux'
    elif is_termux; then
      unpack_it 'termux/tmux'
    elif is_wsl; then
      unpack_it 'wsl/tmux'
    elif is_linux; then
      unpack_it 'debian/tmux'
    fi
  fi
}

prepare_package() {
  ensure_directory "$POTIONS_HOME/tmux/plugins"
}

configure_package() {
  git clone https://github.com/tmux-plugins/tpm $POTIONS_HOME/tmux/plugins/tpm
}

install_package
configure_package
