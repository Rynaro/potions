#!/bin/bash

ensure_directory "$POTIONS_HOME/tmux/plugins"
install_package tmux

# Install TPM (Tmux Plugin Manager) - idempotent check
if [ -d "$POTIONS_HOME/tmux/plugins/tpm" ]; then
  log "TPM already installed, skipping..."
else
  log "Installing TPM (Tmux Plugin Manager)..."
  git clone https://github.com/tmux-plugins/tpm "$POTIONS_HOME/tmux/plugins/tpm"
fi
