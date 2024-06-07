#!/bin/bash

# Detect the operating system
OS_TYPE="$(uname -s)"

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Function to install Git
install_git() {
  if command_exists git; then
    echo "Git is already installed."
  else
    echo "Installing Git..."
    if [ "$OS_TYPE" = "Darwin" ]; then
      brew install git
    elif [ -n "$(command -v apt-get)" ]; then
      sudo apt-get update
      sudo apt-get install -y git
    fi
  fi
}

# Function to install Antidote
install_antidote() {
  if [ -d "${ZDOTDIR:-$HOME}/.antidote" ]; then
    echo "Antidote is already installed."
  else
    echo "Installing Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "${ZDOTDIR:-$HOME}/.antidote"
  fi
}

# Function to install OpenVPN
install_openvpn() {
  if command_exists openvpn; then
    echo "OpenVPN is already installed."
  else
    echo "Installing OpenVPN..."
    if [ "$OS_TYPE" = "Darwin" ]; then
      brew install openvpn
    elif [ -n "$(command -v apt-get)" ]; then
      sudo apt-get update
      sudo apt-get install -y openvpn
    fi
  fi
}

# Function to install Homebrew (macOS only)
install_homebrew() {
  if command_exists brew; then
    echo "Homebrew is already installed."
  else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

# Common package installation
install_common_packages() {
  install_git
  install_antidote
}

# macOS specific installations
install_macos_packages() {
  install_homebrew
  install_openvpn
}

# WSL specific installations
install_wsl_packages() {
  install_openvpn
}

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
