#!/bin/bash

# Environment Variables
OS_TYPE="$(uname -s)"
USER_HOME_FOLDER="$(get_user_home_folder)"
POTIONS_HOME="$USER_HOME_FOLDER/.potions"
ZDOTDIR=$POTIONS_HOME

update_repositories() {
  echo "Updating repositories..."
  if is_macos; then
    brew update
  elif is_termux; then
    pkg update
  elif is_wsl || is_linux; then
    if is_apt_package_manager; then
      echo "If you do not need sudo for any reason, modify this script!"
      sudo apt-get update
    else
      exit_with_message "No supported package manager have been found! Consider move to another environment supported! Or create a patch! :)"
    fi
  fi
}

prepare_logging_stream() {
  ensure_directory $LOGS_FOLDER
  ensure_files "$LOGS_FOLDER" "$LOG_OUTPUT_FILE"
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Function to source the common holding package
unpack_it() {
  local package="$1"
  safe_source "packages/common/$package.sh"
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
  [ $OS_TYPE = "Darwin" ]
}

# Function to check if the environment is Linux-based kernel
is_linux() {
  [ $OS_TYPE = "Linux" ]
}

get_user_home_folder() {
  local home_folder=${HOME:-$(getent passwd "$USER" | cut -d: -f6)}
  if [[ -z home_folder ]]; then
    exit_with_message "No home folder found for this user, consider add a HOME varible to your environment!"
  fi

  echo $home_folder
}

# Function to check if apt is the package manager
is_apt_package_manager() {
  command_exists apt
}

# Function to check and create directory
ensure_directory() {
    local dir="$1"
    if [ -d "$dir" ]; then
        log "Directory '$dir' already exists."
    else
        log "Directory '$dir' does not exist. Creating..."
        mkdir -p "$dir"
        if [ $? -eq 0 ]; then
            log "Successfully created directory '$dir'."
        else
            log "Error: Failed to create directory '$dir'." >&2
            exit 1
        fi
    fi
}

ensure_files() {
    local dir="$1"
    shift
    local files=("$@")

    for file in "${files[@]}"; do
        local filepath="$dir/$file"
        if [ -f "$filepath" ]; then
            echo "File '$filepath' already exists."
        else
            echo "File '$filepath' does not exist. Creating..."
            touch "$filepath"
            if [ $? -eq 0 ]; then
                echo "Successfully created file '$filepath'."
            else
                echo "Error: Failed to create file '$filepath'." >&2
                exit 1
            fi
        fi
    done
}

# Beautifully message and go!
exit_with_message() {
  echo $1
  echo "Terminating Potions Routines..."
  exit 1
}
