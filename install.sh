#!/bin/bash

# Detect the operating system
OS_TYPE="$(uname -s)"

# Function to safely source a script if it exists
safe_source() {
  [ -f "$1" ] && source "$1"
}

update_repositories() {
  safe_source "os_packages/common/update_repositories.sh"
}

# Common package installation
install_common_packages() {
  safe_source "os_packages/common/install_git.sh"
  safe_source "os_packages/common/install_rbenv.sh"
  safe_source "os_packages/common/install_neovim.sh"
  safe_source "os_packages/common/install_nvm.sh"
  safe_source "os_packages/common/install_zsh.sh"
  safe_source "os_packages/common/install_antidote.sh"
}

# macOS specific installations
install_macos_packages() {
  safe_source "os_packages/macos/install_homebrew.sh"
  safe_source "os_packages/macos/install_openvpn.sh"
}

# WSL specific installations
install_wsl_packages() {
  safe_source "os_packages/wsl/install_openvpn.sh"
}

update_repositories

# Install common packages
install_common_packages

# OS-specific installations
case "$OS_TYPE" in
  Darwin)
    install_macos_packages
    ;;
  Linux)
    if grep -qi microsoft /proc/version; then
      install_wsl_packages
    fi
    ;;
esac

echo "Setup completed."
