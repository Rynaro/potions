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
    STARTUP_SCRIPT="$HOME/.potions/potions-start.sh"

    cat > "$STARTUP_SCRIPT" << 'EOF'
#!/usr/bin/env bash

# Clear the terminal for a fresh start
clear

# Print welcome message
echo "🧪 Welcome to Potions! Your development environment is ready."
echo "This is a one-time initialization of your new environment."
echo "Future terminal sessions will start directly in Potions."
echo ""
echo "Starting Potions environment..."
echo ""

# Start a completely new Zsh process with proper environment
ZDOTDIR="$HOME/.potions" exec zsh -l
EOF

    chmod +x "$STARTUP_SCRIPT"

    # Let the user know what's happening
    log "To enter your Potions environment, please run:"
    log "  $STARTUP_SCRIPT"
    log ""
    log "After this first launch, new terminal sessions will automatically use Potions."

    # Option to run it immediately
    read -p "Would you like to start Potions now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      # Execute in a way that preserves context but doesn't affect the parent script
      sh "$STARTUP_SCRIPT"
    fi
  else
    log 'Zsh is not available. Please install Zsh and run: export ZDOTDIR=~/.potions && zsh'
  fi
fi
