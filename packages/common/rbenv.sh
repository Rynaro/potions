#!/bin/bash

source "$(dirname "$0")/../accessories.sh"

install_package() {
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

install_package
