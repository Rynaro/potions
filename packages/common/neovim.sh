#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

prepare_package() {
  if is_macos; then
    safe_source "$(dirname "$0")/packages/macos/neovim.sh"
  elif is_termux; then
    safe_source "$(dirname "$0")/packages/termux/neovim.sh"
  elif is_wsl; then
    safe_source "$(dirname "$0")/packages/wsl/neovim.sh"
  elif is_linux; then
    safe_source "$(dirname "$0")/packages/debian/neovim.sh"
  fi
}

# Function to install Neovim
install_package() {
  if command_exists nvim; then
    echo "Neovim is already installed."
  else
    echo "Installing Neovim..."
    PRESERVED_LEVEL=${pwd}
    git clone https://github.com/neovim/neovim $HOME/.neovim
    cd $HOME/.neovim
    git checkout stable
    rm -r build/  # clear the CMake cache
    make CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/.neovim"
    if is_termux; then
      make install
    else
      sudo make install
    fi
    cd $PRESERVED_LEVEL
  fi
}

prepare_package
install_package
