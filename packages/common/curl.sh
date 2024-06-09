#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install curl
install_package() {
  if command_exists curl; then
    echo "curl is already installed."
  else
    echo "Installing curl..."
    if is_macos; then
      safe_source "$(dirname "$0")/packages/macos/curl.sh"
    elif is_termux; then
      safe_source "$(dirname "$0")/packages/termux/curl.sh"
    elif is_wsl; then
      safe_source "$(dirname "$0")/packages/wsl/curl.sh"
    elif is_linux; then
      safe_source "$(dirname "$0")/packages/debian/curl.sh"
    fi
  fi
}

install_package
