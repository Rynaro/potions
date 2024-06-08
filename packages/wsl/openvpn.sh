#!/bin/bash

# Function to install OpenVPN
install_package() {
  echo "Installing OpenVPN..."
  sudo apt-get install -y openvpn
}

install_package
