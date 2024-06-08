#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Zsh
install_package() {
  pkg install -y zsh
}

install_package

