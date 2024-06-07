#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Function to install rbenv and ruby-build from git
install_rbenv() {
  if [ -d "$HOME/.rbenv" ]; then
    echo "rbenv is already installed."
  else
    echo "Installing rbenv..."
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  fi

  if [ -d "$HOME/.rbenv/plugins/ruby-build" ]; then
    echo "ruby-build is already installed."
  else
    echo "Installing ruby-build..."
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  fi
}

install_rbenv
