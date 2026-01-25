#!/bin/bash

sudo apt install -y zsh

# Change the default shell to Zsh (WSL-specific)
# WSL may or may not require sudo, try without first
if [ "$SHELL" != "$(command -v zsh)" ]; then
  zsh_path="$(command -v zsh)"
  
  if [ -z "$zsh_path" ]; then
    log "ERROR: zsh command not found. Cannot change shell."
    return 1
  fi
  
  log "Changing default shell to Zsh (WSL method)..."
  
  # Ensure zsh is in /etc/shells
  ensure_zsh_in_shells "$zsh_path"
  
  # Try chsh without sudo first (WSL sometimes allows this)
  if chsh -s "$zsh_path" 2>/dev/null; then
    log "Successfully changed default shell to Zsh"
  elif sudo chsh -s "$zsh_path" "$USER" 2>/dev/null; then
    log "Successfully changed default shell to Zsh (with sudo)"
  else
    log "WARNING: Failed to change shell automatically"
    log "You can manually change it by running: chsh -s $zsh_path"
    log "Or if that fails: sudo chsh -s $zsh_path"
  fi
fi
