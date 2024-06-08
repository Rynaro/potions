#!/bin/bash

# Function to install Git
install_package() {
  echo "Installing Git..."
  sudo apt-get install -y git
}

install_package
