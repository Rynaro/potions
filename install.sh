#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

prepare_system() {
  if is_macos; then
    safe_source "packages/macos/homebrew.sh"
  fi

  update_repositories
  echo "Copying Potions to Home!"
  cp -r .potions ~/
}

install_packages() {
  safe_source "packages/common/curl.sh"
  safe_source "packages/common/wget.sh"
  safe_source "packages/common/zsh.sh"
  safe_source "packages/common/git.sh"
  safe_source "packages/common/openvpn.sh"
  safe_source "packages/common/ruby.sh"
  safe_source "packages/common/neovim.sh"
  safe_source "packages/common/vim-plug.sh"
  safe_source "packages/common/nvm.sh"
  safe_source "packages/common/antidote.sh"
  safe_source "packages/common/proot-distro.sh"
}

echo "Preparing System..."
prepare_system
echo "Installing Packages..."
install_packages

echo "Setup completed!"
