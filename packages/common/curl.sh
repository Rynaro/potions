#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install curl
install_package() {
  if command_exists curl; then
    log "curl is already installed."
  else
    log "Installing curl..."
    if is_macos; then
      unpack_it 'macos/curl'
    elif is_termux; then
      unpack_it 'termux/curl'
    elif is_wsl; then
      unpack_it 'wsl/curl'
    elif is_linux; then
      unpack_it 'debian/curl'
    fi
  fi
}

install_package
