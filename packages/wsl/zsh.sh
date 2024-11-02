#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

install_package() {
  sudo apt install -y zsh
}

install_package

