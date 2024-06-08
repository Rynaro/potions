#!/bin/bash

source "$(dirname "$0")/../accessories.sh"

# Function to install NVM
install_package() {
  if [ -d "$HOME/.nvm" ]; then
    echo "NVM is already installed."
  else
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
}

install_package
