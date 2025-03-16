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

  if command_exists zsh; then
    # Create a temporary script to be used for the exec command
    TMP_SCRIPT=$(mktemp)
    echo "#!/bin/zsh
    # Source Potions environment
    source ~/.potions/.zshrc

    # Welcome message
    echo \"\"
    echo \"🧪 Welcome to Potions! Your development environment is ready.\"
    echo \"Type 'exit' to return to your previous shell.\"
    echo \"\"

    # Start an interactive Zsh session
    exec zsh -i" > "$TMP_SCRIPT"

    chmod +x "$TMP_SCRIPT"

    exec "$TMP_SCRIPT"
  else
    log 'Zsh is not available. Please install Zsh and run: export ZDOTDIR=~/.potions && zsh'
  fi
fi
