#!/bin/bash

source "$(dirname "$0")/../packages/accessories.sh"

# Function to install curl
install_package() {
  sudo apt install -y curl
}

install_package
