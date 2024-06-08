#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Git
install_package() {
  pkg install -y git
}

install_package
