#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

install_package() {
  brew install zsh
}

install_package

