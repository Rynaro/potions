#!/bin/bash

safe_source "utilities.sh"

MY_PREFERRED_PACKAGE_VERSION=1.0.0

prepare_package() {
  # sudo apt install -y build-essentials
}

# Function to install package 1
install_package() {
  echo "Installing package 1..."
  # Installation commands for package 1
  echo "Installing super cool package $MY_PREFERRED_PACKAGE_VERSION"
}

configure_package() {
  # docker build ~/projects/super-duper-app
}

# Run installation
prepare_package
install_package
configure_package
