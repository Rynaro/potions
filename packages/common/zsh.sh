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

# Change the default shell to Zsh
if [ "$SHELL" != "$(command -v zsh)" ]; then
  if is_termux; then
    chsh -s zsh
  elif is_macos || is_linux; then
    log "Changing default shell to Zsh..."
    chsh -s "$(command -v zsh)" || {
      log "Failed to change shell automatically. Please run: chsh -s $(command -v zsh)"
    }
  fi
fi
