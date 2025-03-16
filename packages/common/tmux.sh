#!/bin/bash

ensure_directory "$POTIONS_HOME/tmux/plugins"
install_package tmux
git clone https://github.com/tmux-plugins/tpm $POTIONS_HOME/tmux/plugins/tpm
