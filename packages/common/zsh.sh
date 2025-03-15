#!/bin/bash

configure_package() {
  # Change the default shell to Zsh
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    cp .zshenv $USER_HOME_FOLDER
    source .zshenv
  fi

  if is_termux; then
    chsh -s zsh
  fi
}

install_package zsh
configure_package
