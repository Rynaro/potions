#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install OpenVPN
install_package() {
  if command_exists openvpn; then
    echo "OpenVPN is already installed."
  else
    echo "Installing ..."
    if is_macos; then
      safe_source "$(dirname "$0")/packages/macos/openvpn.sh"
    elif is_termux; then
      safe_source "$(dirname "$0")/packages/termux/openvpn.sh"
    elif is_wsl; then
      safe_source "$(dirname "$0")/packages/wsl/openvpn.sh"
    fi
  fi
}

install_package
