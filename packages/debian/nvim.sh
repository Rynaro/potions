#!/bin/bash

NEOVIM_INSTALLATION_FOLDER=$USER_HOME_FOLDER/.neovim

sudo apt install -y ninja-build gettext cmake unzip curl build-essential ripgrep

# Save current directory
local original_dir="$(pwd)"

# Clone repository if it doesn't exist
if [ ! -d "$NEOVIM_INSTALLATION_FOLDER" ]; then
  git clone https://github.com/neovim/neovim "$NEOVIM_INSTALLATION_FOLDER" || {
    log "ERROR: Failed to clone NeoVim repository"
    return 1
  }
fi

# Enter repository directory
cd "$NEOVIM_INSTALLATION_FOLDER" || {
  log "ERROR: Failed to change to NeoVim directory"
  return 1
}

# Checkout stable branch
git checkout stable || {
  log "ERROR: Failed to checkout stable branch"
  cd "$original_dir"
  return 1
}

# Remove build directory if it exists
if [ -d "build" ]; then
  rm -rf build/ || log "Warning: Failed to remove build directory, continuing anyway"
fi

# Install NeoVim
make CMAKE_BUILD_TYPE=Release || {
  log "ERROR: Failed to build NeoVim"
  cd "$original_dir"
  return 1
}

sudo make install || {
  log "ERROR: Failed to install NeoVim"
  cd "$original_dir"
  return 1
}

# Return to original directory
cd "$original_dir"
log "NeoVim installation completed successfully"
