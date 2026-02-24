#!/bin/bash

brew install zsh

# Change the default shell to Zsh (macOS-specific)
# macOS chsh works without sudo (uses system authentication)
if [ "$SHELL" != "$(command -v zsh)" ]; then
  zsh_path="$(command -v zsh)"
  
  if [ -z "$zsh_path" ]; then
    log "ERROR: zsh command not found. Cannot change shell."
    return 1
  fi
  
  log "Changing default shell to Zsh (macOS method)..."
  if chsh -s "$zsh_path"; then
    log "Successfully changed default shell to Zsh"
    log "NOTE: The change will take effect in new terminal sessions"
  else
    log "WARNING: Failed to change shell automatically"
    log "You can manually change it by running: chsh -s $zsh_path"
  fi
fi