#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Git
install_package() {
  brew install git
}

install_package
