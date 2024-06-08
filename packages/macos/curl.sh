#!/bin/bash

source "$(dirname "$0")/../packages/accessories.sh"

# Function to install curl
install_package() {
  brew install curl
}

install_package
