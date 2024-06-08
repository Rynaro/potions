#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

prepare_system() {
  if [ "$OS_TYPE" = "Darwin" ]; then
    safe_source "packages/macos/homebrew.sh"
  fi

  update_repositories
}

install_packages() {
  safe_source "packages/common/curl.sh"
  safe_source "packages/common/zsh.sh"
  safe_source "packages/common/git.sh"
  safe_source "packages/common/openvpn.sh"
  safe_source "packages/common/rbenv.sh"
  safe_source "packages/common/neovim.sh"
  safe_source "packages/common/nvm.sh"
  safe_source "packages/common/antidote.sh"
}

echo "Preparing System..."
prepare_system
echo "Installing Packages..."
install_packages

echo "Setup completed!"
