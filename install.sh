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
  install_package 'curl'
  install_package 'wget'
  install_package 'git'
  install_package 'openvpn'
  install_package 'zsh'
  install_package 'neovim'
  install_package 'vim-plug'
  install_package 'antidote'
  install_package 'tmux'
  install_package 'proot-distro'
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

