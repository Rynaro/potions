#!/bin/bash

UTILITIES_VERSION=1.1.0

OS_TYPE="$(uname -s)"

update_repositories() {
  echo "Updating repositories..."
  if is_macos; then
    brew update
  elif is_termux; then
    pkg update
  elif is_wsl; then
    sudo apt-get update
  elif is_linux; then
    if is_fedora || is_dnf_package_manager; then
      sudo dnf makecache
    else
      sudo apt-get update
    fi
  fi
}

# Function to check if a command exists
command_exists() {
  local cmd="$1"

  # Check in bash
  if command -v "$cmd" &> /dev/null; then
    return 0
  fi

  # Check in zsh
  if ZDOTDIR="$HOME/.potions" zsh -c "command -v $cmd" &> /dev/null; then
    return 0
  fi

  return 1
}

# Function to safely source a script if it exists
safe_source() {
  [ -f "$PLUGIN_RELATIVE_FOLDER/$1" ] && source "$PLUGIN_RELATIVE_FOLDER/$1"
}

# Function to check if the environment is Termux
is_termux() {
  [ -n "$PREFIX" ] && [ -x "$PREFIX/bin/termux-info" ]
}

# Function to check if the environment is WSL
is_wsl() {
  grep -qi microsoft /proc/version
}

# Function to check if the environment is macOS
is_macos() {
  [ $OS_TYPE = "Darwin" ]
}

# Function to check if the environment is Linux-based kernel
is_linux() {
  [ $OS_TYPE = "Linux" ]
}

# Function to check if the environment is Fedora (or Fedora-based)
is_fedora() {
  [ -f /etc/fedora-release ] || grep -qi '^ID=fedora' /etc/os-release 2>/dev/null
}

# Function to check if dnf is the package manager
is_dnf_package_manager() {
  command -v dnf &> /dev/null
}

is_debian_bookworm() {
  grep -qi 'debian.*bookworm' /etc/os-release
}
