#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install OpenVPN
install_package() {
  if command_exists openvpn; then
    echo "OpenVPN is already installed."
  else
    if [ "$OS_TYPE" = "Darwin" ]; then
      safe_source "$(dirname "$0")/../macos/openvpn.sh"
    elif [ -n "$(command -v apt-get)" ]; then
      safe_source "$(dirname "$0")/../wsl/openvpn.sh"
    fi
  fi
}

install_package
