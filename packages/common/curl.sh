#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install curl
install_package() {
  if command_exists curl; then
    echo "curl is already installed."
  else
    echo "Installing curl..."
    if is_macos; then
      safe_source "$(dirname "$0")/../macos/curl.sh"
    elif is_termux; then
      safe_source "$(dirname "$0")/../termux/curl.sh"
    elif is_wsl; then
      safe_source "$(dirname "$0")/../wsl/curl.sh"
    fi
  fi
}

install_package
