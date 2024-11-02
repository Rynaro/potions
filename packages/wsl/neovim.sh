#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

NEOVIM_INSTALLATION_FOLDER=$USER_HOME_FOLDER/.neovim

# The script is similar to the Debian version (for obvious reasons)
# but I would like to keep it independent for each other.

prepare_package() {
  sudo apt install -y ninja-build gettext cmake \
    unzip curl build-essential ripgrep
}

install_package() {
  git clone https://github.com/neovim/neovim $NEOVIM_INSTALLATION_FOLDER
  cd $NEOVIM_INSTALLATION_FOLDER
  git checkout stable
  rm -r build/  # clear the CMake cache
  sudo make install
}

configure_package() {
  cd $USER_HOME_FOLDER
}

prepare_package
install_package
configure_package
