#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Function to install Git
install_git() {
  if command_exists git; then
    echo "Git is already installed."
  else
    echo "Installing Git..."
    if [ "$OS_TYPE" = "Darwin" ]; then
      brew install git
    elif [ -n "$(command -v apt-get)" ]; then
      sudo apt-get install -y git
    fi
  fi
}

configure_git() {
  git config --global alias.ch checkout
  git config --global alias.cm commit
  git config --global alias.cmm 'commit -m'
  git config --global alias.cb 'checkout -b'
  git config --global alias.st status
  git config --global alias.pl pull
  git config --global alias.ps push
  git config --global alias.undo 'reset HEAD~1'
  git config --global alias.rs reset
  git config --global alias.hrs 'reset --hard'
  git config --global alias.fps 'push --force'
  git config --global core.editor vim
}

install_git
configure_git
