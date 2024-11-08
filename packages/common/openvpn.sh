#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install OpenVPN
install_package() {
  if command_exists openvpn; then
    log "OpenVPN is already installed."
  else
    log "Installing OpenVPN..."
    if is_macos; then
      unpack_it 'macos/openvpn'
    elif is_termux; then
      unpack_it 'termux/openvpn'
    elif is_wsl; then
      unpack_it 'wsl/openvpn'
    elif is_linux; then
      unpack_it 'debian/openvpn'
    fi
  fi
}

install_package
