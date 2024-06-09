#!/bin/bash

source "$(dirname "$0")/../packages/accessories.sh"

# Function to install curl
install_package() {
  pkg install wget
}

install_package
