#!/bin/bash

NEOVIM_INSTALLATION_FOLDER=$USER_HOME_FOLDER/.neovim

sudo apt install -y ninja-build gettext cmake unzip curl build-essential ripgrep

git clone https://github.com/neovim/neovim $NEOVIM_INSTALLATION_FOLDER
cd $NEOVIM_INSTALLATION_FOLDER
git checkout stable
rm -r build/  # clear the CMake cache
sudo make install

cd $USER_HOME_FOLDER

