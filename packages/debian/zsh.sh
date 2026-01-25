#!/bin/bash

sudo apt install -y zsh

# Change the default shell to Zsh (Debian/Linux-specific)
# Debian and other Linux systems require sudo for chsh
if [ "$SHELL" != "$(command -v zsh)" ]; then
  zsh_path="$(command -v zsh)"
  
  if [ -z "$zsh_path" ]; then
    log "ERROR: zsh command not found. Cannot change shell."
    return 1
  fi
  
  log "Changing default shell to Zsh (Debian/Linux method)..."
  
  # Ensure zsh is in /etc/shells (required by PAM)
  ensure_zsh_in_shells "$zsh_path"
  
  # Use sudo chsh for Debian/Linux
  log "Running: sudo chsh -s $zsh_path"
  log "You may be prompted for your sudo password..."
  if sudo chsh -s "$zsh_path" "$USER"; then
    log "Successfully changed default shell to Zsh"
    log "NOTE: The change will take effect in new terminal sessions"
  else
    log "WARNING: Failed to change shell automatically with sudo chsh"
    log "You can manually change it by running: sudo chsh -s $zsh_path"
    log "Or if you have sudo access without password: sudo chsh -s $zsh_path $USER"
  fi
fi
