#!/bin/bash

# Source accessories.sh for utility functions
source "$(dirname "$0")/packages/accessories.sh"

update_potions() {
  echo "Updating Potions files..."
  cp -r .potions ~/
  echo "Potions files updated!"
}

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
  safe_source "packages/common/neovim.sh"
  safe_source "packages/common/vim-plug.sh"
  safe_source "packages/common/antidote.sh"
  safe_source "packages/common/tmux.sh"
  safe_source "packages/common/proot-distro.sh"
}

if [[ "$1" == "--only-dotfiles" ]]; then
  echo "Updating only dotfiles..."
  update_potions
else
  echo "Preparing System..."
  prepare_system
  echo "Installing Packages..."
  install_packages
fi

echo "Setup completed!"

