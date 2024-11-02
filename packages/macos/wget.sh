#!/bin/bash

source "$(dirname "$0")/../packages/accessories.sh"

install_package() {
  brew install wget
}

install_package
