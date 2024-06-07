#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Function to install Zsh
install_zsh() {
  if command_exists zsh; then
    echo "Zsh is already installed."
  else
    echo "Installing Zsh..."
    if [ "$OS_TYPE" = "Darwin" ]; then
      brew install zsh
    elif [ -n "$(command -v apt-get)" ]; then
      sudo apt-get update
      sudo apt-get install -y zsh
    fi
  fi

  # Send the Zsh Stuff out!
  cp -r .potions ~/
  cp .zshenv ~/
  source .zshenv

  # Change the default shell to Zsh
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    echo "Changing the default shell to Zsh..."
    chsh -s "$(command -v zsh)"
  fi
}

install_zsh
