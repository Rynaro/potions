#!/bin/bash

OS_TYPE="$(uname -s)"

update_repositories() {
  echo "Updating repositories..."
  if is_macos; then
    brew update
  elif is_wsl; then
    sudo apt-get update
  elif is_termux; then
    pkg update
  fi
}

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Function to safely source a script if it exists
safe_source() {
  [ -f "$1" ] && source "$1"
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
  [ "$(uname -s)" = "Darwin" ]
}
