#!/bin/bash

if [ -d "${ZDOTDIR:-$POTIONS_HOME}/.antidote" ]; then
  log "Antidote is already installed."
else
   log "Installing Antidote..."
  git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-$POTIONS_HOME}/.antidote
fi

