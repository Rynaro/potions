#!/bin/bash

source "$(dirname "$0")/acessories.sh"

# Function to install HomeBrew
install_package() {
  if command_exists brew; then
    echo "Homebrew is already installed."
  else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

install_package
