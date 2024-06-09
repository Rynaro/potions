#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

prepare_package() {
  if is_macos; then
    safe_source "$(dirname "$0")/packages/macos/rbenv.sh"
  elsif is_linux; then
    safe_source "$(dirname "$0")/packages/debian/rbenv.sh"
  elsif is_wsl; then
    safe_source "$(dirname "$0")/packages/wsl/rbenv.sh"
  fi
}

install_package() {
  if is_termux; then
    pkg install ruby
  else
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
  fi
}

prepare_package
install_package
