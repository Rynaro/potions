#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Zsh
install_package() {
  brew install zsh
}

install_package

