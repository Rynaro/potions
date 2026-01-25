#!/bin/bash

install_package zsh

# Copy .zshenv from repo to home directory
# Use REPO_ROOT for absolute path resolution
if [ -f "$REPO_ROOT/.zshenv" ]; then
  cp "$REPO_ROOT/.zshenv" "$HOME/"
  log "Copied .zshenv to $HOME"
elif [ -f ".zshenv" ]; then
  # Fallback to current directory (for backwards compatibility)
  cp ".zshenv" "$HOME/"
  log "Copied .zshenv to $HOME"
else
  log "WARNING: .zshenv not found, creating default"
  echo 'export ZDOTDIR=~/.potions' > "$HOME/.zshenv"
fi

# Note: Shell-changing logic is handled in platform-specific scripts
# (packages/fedora/zsh.sh, packages/termux/zsh.sh, etc.)
