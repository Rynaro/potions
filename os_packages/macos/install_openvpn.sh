#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Function to install OpenVPN
install_openvpn() {
  if command_exists openvpn; then
    echo "OpenVPN is already installed."
  else
    echo "Installing OpenVPN..."
    brew install openvpn
  fi
}

install_openvpn
