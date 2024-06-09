#!/bin/bash

prepare_package() {
  xcode-select --install
  brew install openssl@3 readline libyaml gmp
}

prepare_package
