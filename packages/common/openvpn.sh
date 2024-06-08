#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install OpenVPN
install_package() {
  if command_exists openvpn; then
    echo "OpenVPN is already installed."
  else
    if is_macos; then
      safe_source "$(dirname "$0")/../macos/openvpn.sh"
    elif is_wsl; then
      safe_source "$(dirname "$0")/../wsl/openvpn.sh"
    elif is_termux; then
      safe_source "$(dirname "$0")/../termux/openvpn.sh"
    fi
  fi
}

install_package
