#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Neovim
install_package() {
  sudo apt-get install -y neovim
}

install_package
