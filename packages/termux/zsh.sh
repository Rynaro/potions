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
  
  # Termux's login execs ~/.termux/shell directly — it must be a SYMLINK
  # to the shell binary, not a file containing the path. Writing text here
  # permanently locks the user out of Termux (exec: Permission denied).
  if ! ln -sfn "$zsh_path" "$termux_shell_file"; then
    log "WARNING: Failed to symlink $termux_shell_file -> $zsh_path"
    log "You can manually set it by running: ln -sfn '$zsh_path' ~/.termux/shell"
  else
    log "Successfully set zsh as default shell for Termux"
    log "NOTE: You need to restart the Termux app for the change to take effect"
  fi
fi