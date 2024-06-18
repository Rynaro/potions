#!/bin/bash

UTILITIES_VERSION=1.0.0

OS_TYPE="$(uname -s)"

update_repositories() {
  echo "Updating repositories..."
  if is_macos; then
    brew update
  elif is_termux; then
    pkg update
  elif is_wsl || is_linux; then
    sudo apt-get update
  fi
}

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
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

is_debian_bookworm() {
  grep -qi 'debian.*bookworm' /etc/os-release
}
