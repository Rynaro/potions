#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

install_package() {
  pkg install -y git
}

install_package
