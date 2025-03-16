#!/bin/bash

# Source accessories.sh for utility functions
POTIONS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$POTIONS_ROOT/packages/accessories.sh"

update_potions() {
  log 'Sending Potions files to HOME...'
  cp -r .potions ~/
}

prepare_system() {
  if is_macos; then
    unpack_it 'macos/homebrew'
  fi

  update_repositories
  update_potions
}

install_packages() {
  local packages=(
    'curl'
    'wget'
    'git'
    'openvpn'
    'zsh'
    'antidote'
    'tmux'
    'neovim'
    'vim-plug'
  )

  for pkg in "${packages[@]}"; do
    unpack_it "common/$pkg"
  done
}

if [[ "$1" == "--only-dotfiles" ]]; then
  log 'Updating only dotfiles...'
  update_potions
else
  log 'Preparing System...'
  prepare_system
  log 'Installing Packages...'
  install_packages
fi

log 'Setup completed!'
