#!/bin/bash

NEOVIM_INSTALLATION_FOLDER=$USER_HOME_FOLDER/.neovim

brew install ninja cmake gettext curl ripgrep

git clone https://github.com/neovim/neovim $NEOVIM_INSTALLATION_FOLDER/.neovim
cd $NEOVIM_INSTALLATION_FOLDER
git checkout stable
rm -r build/  # clear the CMake cache
sudo make install

cd $USER_HOME_FOLDER
