#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install wget
install_package() {
  if command_exists wget; then
    log "wget is already installed."
  else
    log "Installing wget..."
    if is_macos; then
      unpack_it 'macos/wget'
    elif is_termux; then
      unpack_it 'termux/wget'
    elif is_wsl; then
      unpack_it 'wsl/wget'
    elif is_linux; then
      unpack_it 'debian/wget'
    fi
  fi
}

install_package
