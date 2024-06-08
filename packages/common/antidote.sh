#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

# Function to install Antidote
install_package() {
  if [ -d "${ZDOTDIR:-$HOME}/.antidote" ]; then
    echo "Antidote is already installed."
  else
    echo "Installing Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-$HOME}/.antidote
  fi
}

install_package
