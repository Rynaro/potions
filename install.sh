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
  packages=(
    'curl'
    'wget'
    'git'
    'openvpn'
    'zsh'
    'neovim'
    'vim-plug'
    'antidote'
    'tmux'
    'proot-distro'
)

  for pkg in "${packages[@]}"; do
    unpack_it "$pkg"
  done
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

