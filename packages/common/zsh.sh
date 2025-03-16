#!/bin/bash

install_package zsh

if [ -f ".zshenv" ]; then
  cp ".zshenv" "$HOME/"
  log "Copied .zshenv to $HOME"
else
  log "ERROR: .zshenv not found in current directory"
  return 1
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
