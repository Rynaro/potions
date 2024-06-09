#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install PRoot Distro
install_package() {
  if command_exists proot-distro; then
    echo "PRoot Distro is already installed."
  else
    echo "Installing PRoot Distro..."
    if is_termux; then
      safe_source "$(dirname "$0")/packages/termux/proot-distro.sh"
    else
      echo "No PRoot outside Android"
    fi
  fi
}

install_package
