#!/bin/bash

DISTRO_NAME="debian"

source "$(dirname "$0")/packages/accessories.sh"

is_distro_installed() {
  proot-distro list | grep -q "$DISTRO_NAME"
}

# Function to install PRoot-Distro
install_package() {
  pkg install -y proot-distro
}

configure_package() {
  if ! is_distro_installed; then
    proot-distro install $DISTRO_NAME

    # Prompt for the hostname
    read -p "Enter the hostname for the distro: " HOSTNAME

    # Prompt for the username
    read -p "Enter the username for the new user: " USER_NAME

    # Prompt for the password
    read -sp "Enter password for the new user $USER_NAME: " USER_PASSWORD
    echo

    # Start the distro
    echo "Starting $DISTRO_NAME..."
    proot-distro login $DISTRO_NAME << EOF
# Update and upgrade packages
echo "Updating and upgrading packages inside $DISTRO_NAME..."
apt-get update && apt-get upgrade -y

# Set the hostname
echo "Setting the hostname to $HOSTNAME..."
echo $HOSTNAME > /etc/hostname
hostname $HOSTNAME

# Install necessary packages
echo "Installing necessary packages..."
apt-get install -y sudo git build-essential wget curl

# Create a new user and add to sudoers
if id -u $USER_NAME >/dev/null 2>&1; then
    echo "User $USER_NAME already exists."
else
    echo "Creating user $USER_NAME..."
    adduser --gecos "" --disabled-password $USER_NAME
    echo "$USER_NAME:$USER_PASSWORD" | chpasswd
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

# Exit the distro
exit
EOF
  else
    echo "$DISTRO_NAME is already installed"
  fi
}

install_package
configure_package

