#!/bin/bash

source "$(dirname "$0")/packages/accessories.sh"

prepare_package() {
  pkg install ninja gettext cmake unzip curl clang
}

prepare_package
