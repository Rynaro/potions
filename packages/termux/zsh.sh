#!/bin/bash

pkg install -y zsh

# Change the default shell to Zsh (Termux-specific)
# Termux uses a special file-based method instead of chsh
if [ "$SHELL" != "$(command -v zsh)" ]; then
  zsh_path="$(command -v zsh)"
  
  if [ -z "$zsh_path" ]; then
    log "ERROR: zsh command not found. Cannot change shell."
    return 1
  fi
  
  log "Changing default shell to Zsh (Termux method)..."
  termux_shell_dir="$HOME/.termux"
  termux_shell_file="$termux_shell_dir/shell"
  
  # Ensure .termux directory exists
  if [ ! -d "$termux_shell_dir" ]; then
    if ! mkdir -p "$termux_shell_dir"; then
      log "WARNING: Failed to create $termux_shell_dir directory"
    fi
  fi
  
  # Write zsh path to ~/.termux/shell
  if ! echo "$zsh_path" > "$termux_shell_file"; then
    log "WARNING: Failed to write zsh path to $termux_shell_file"
    log "You can manually set it by running: echo '$zsh_path' > ~/.termux/shell"
  else
    log "Successfully set zsh as default shell for Termux"
    log "NOTE: You need to restart the Termux app for the change to take effect"
  fi
fi