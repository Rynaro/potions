#!/bin/bash

DISTRO_NAME="debian"
REPO_URL="https://github.com/Rynaro/potions"
REPO_DIR="potions"

source "$(dirname "$0")/packages/accessories.sh"

# Function to install PRoot-Distro
install_package() {
  pkg install -y proot-distro
}

configure_package() {
  proot-distro install debian

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

# Switch to the new user
echo "Switching to user $USER_NAME..."
su - $USER_NAME << EOU
# Clone the repository
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning the repository $REPO_URL..."
    git clone $REPO_URL
else
    echo "Repository already cloned."
fi

# Navigate to the repository directory and run the install script
cd $REPO_DIR
echo "Running install.sh script..."
bash install.sh

EOU

# Exit the distro
exit
EOF
}

install_package
configure_package
