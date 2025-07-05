#!/bin/bash

# Source accessories.sh for utility functions
POTIONS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$POTIONS_ROOT/packages/accessories.sh"

update_potions() {
  log 'Sending Potions files to HOME...'
  cp -r .potions ~/
  
  # Copy plugin management files to ~/.potions for user accessibility
  log 'Setting up plugin management in Potions environment...'
  cp plugins.sh ~/.potions/
  cp -r plugins ~/.potions/
  
  # Copy plugins.txt if it exists for plugin installation
  if [ -f "plugins.txt" ]; then
    cp plugins.txt ~/.potions/
  fi
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

  log 'Installation completed!'
  # Create a script that properly sets up the Potions environment
  POTIONS_SETUP="$HOME/.potions/activate.sh"
  cat > "$POTIONS_SETUP" << 'EOF'
#!/bin/bash
# Potions activation script

# Set Zsh directory
export ZDOTDIR="$HOME/.potions"

# Display welcome message
echo "🧪 Potions has been installed successfully!"
echo "Your development environment is now ready."
echo ""
echo "This terminal session is still using your original shell."
echo "You can either:"
echo "  1. Close this terminal and open a new one (recommended)"
echo "  2. Type 'zsh' to switch to Zsh with Potions now"
echo ""
echo "All new terminal sessions will automatically use Potions."
EOF

  chmod +x "$POTIONS_SETUP"

  log "To complete setup, I recommend closing this terminal and opening a new one."
  log "This will start a fresh session with your Potions environment."
  log ""
  log "If you want to explore Potions now, simply type 'zsh' to start a new shell session."

  # Source the activation script for immediate information
  source "$POTIONS_SETUP"
fi
