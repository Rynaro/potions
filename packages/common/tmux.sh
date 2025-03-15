#!/bin/bash

prepare_package() {
  ensure_directory "$POTIONS_HOME/tmux/plugins"
}

configure_package() {
  git clone https://github.com/tmux-plugins/tpm $POTIONS_HOME/tmux/plugins/tpm
}

prepare_package
install_package tmux
configure_package
