#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

prepare_package() {
  brew install ninja cmake gettext curl ripgrep
}

prepare_package
