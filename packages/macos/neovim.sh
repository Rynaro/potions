#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

NEOVIM_INSTALLATION_FOLDER=$USER_HOME_FOLDER/.neovim

prepare_package() {
  brew install ninja cmake gettext curl ripgrep
}

install_package() {
  git clone https://github.com/neovim/neovim $NEOVIM_INSTALLATION_FOLDER/.neovim
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

