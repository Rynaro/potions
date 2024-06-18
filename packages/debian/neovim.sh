#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

prepare_package() {
  sudo apt-get install -y ninja-build gettext cmake \
    unzip curl build-essential ripgrep
}

prepare_package
