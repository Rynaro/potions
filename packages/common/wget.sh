#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install wget
install_package() {
  if command_exists wget; then
    echo "wget is already installed."
  else
    echo "Installing wget..."
    if is_macos; then
      safe_source "$(dirname "$0")/packages/macos/wget.sh"
    elif is_termux; then
      safe_source "$(dirname "$0")/packages/termux/wget.sh"
    elif is_wsl; then
      safe_source "$(dirname "$0")/packages/wsl/wget.sh"
    elif is_linux; then
      safe_source "$(dirname "$0")/packages/debian/wget.sh"
    fi
  fi
}

install_package
