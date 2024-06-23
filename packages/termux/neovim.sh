#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

install_package() {
  echo "*********"
  echo "We recommend use neovim inside the proot distro there you will handle a better compiled version of it!"
  echo "But if you want to have it here in Termux environment, use: pkg install neovim"
  echo "We do not guarantee the plugins support in this package"
  echo "*********"
}

install_package

