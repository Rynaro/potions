#!/bin/bash

OS_TYPE="$(uname -s)"

update_repositories() {
  echo "Update Repositories..."
  if [ "$OS_TYPE" = "Darwin" ]; then
    brew update
  elif [ -n "$(command -v apt-get)" ]; then
    sudo apt-get update
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
