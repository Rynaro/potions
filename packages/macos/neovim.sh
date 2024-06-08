#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Neovim
install_package() {
  brew install neovim
}

install_package
