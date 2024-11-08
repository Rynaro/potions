#!/bin/bash

# Source accessories.sh for utility functions
source "$(dirname "$0")/packages/accessories.sh"

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
    'neovim'
    'vim-plug'
    'antidote'
    'tmux'
  )

  for pkg in "${packages[@]}"; do
    unpack_it "$pkg"
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
