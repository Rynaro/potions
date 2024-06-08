#!/bin/bash

source "$(dirname "$0")/acessories.sh"

install_package() {
  if command_exists git; then
    echo "Git is already installed."
  else
    echo "Installing Git..."
    brew install git
  fi
}

install_package
