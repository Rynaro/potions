#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

prepare_package() {
  brew install ninja cmake gettext curl ripgrep
}

install_package() {
  PRESERVED_LEVEL=${pwd}
  git clone https://github.com/neovim/neovim $HOME/.neovim
  cd $HOME/.neovim
  git checkout stable
  rm -r build/  # clear the CMake cache
  sudo make install
  cd $PRESERVED_LEVEL
}

prepare_package
install_package

