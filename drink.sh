#!/bin/bash

# drink.sh - One-line installer for Potions
# Author: Henrique A. Lavezzo (Rynaro)

set -e

echo "🧪 Potions one-line installer"
echo "=============================="

# Detect OS for better user feedback
OS_TYPE="$(uname -s)"
if [ "$OS_TYPE" = "Darwin" ]; then
  OS_NAME="macOS"
elif [ "$OS_TYPE" = "Linux" ]; then
  if grep -qi microsoft /proc/version 2>/dev/null; then
    OS_NAME="WSL"
  elif [ -n "$PREFIX" ] && [ -x "$PREFIX/bin/termux-info" ]; then
    OS_NAME="Termux"
  else
    OS_NAME="Linux"
  fi
else
  OS_NAME="Unknown"
fi

echo "Detected environment: $OS_NAME"

# Temporary directory for downloading
TEMP_DIR=$(mktemp -d)
POTIONS_DIR="$HOME/.potions-installer"

cleanup() {
  echo "Cleaning up temporary files..."
  rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

# Check for download tools
DOWNLOAD_TOOL=""
if command -v curl &> /dev/null; then
  DOWNLOAD_TOOL="curl"
elif command -v wget &> /dev/null; then
  DOWNLOAD_TOOL="wget"
else
  echo "❌ Neither curl nor wget found. Installing curl..."

  # Install curl based on OS
  if [ "$OS_NAME" = "macOS" ]; then
    if ! command -v brew &> /dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install curl
  elif [ "$OS_NAME" = "Termux" ]; then
    pkg install -y curl
  else
    # Debian/Ubuntu/WSL
    sudo apt-get update
    sudo apt-get install -y curl
  fi

  DOWNLOAD_TOOL="curl"
fi

RELEASE_VERSION="v2.0.0"
RELEASE_URL="https://github.com/Rynaro/potions/releases/download/$RELEASE_VERSION/potions-$RELEASE_VERSION.tar.gz"
ARCHIVE_NAME="potions-$RELEASE_VERSION.tar.gz"

echo "📦 Downloading Potions release $RELEASE_VERSION..."

# Download the release archive
if [ "$DOWNLOAD_TOOL" = "curl" ]; then
  curl -L "$RELEASE_URL" -o "$TEMP_DIR/$ARCHIVE_NAME"
else
  wget -O "$TEMP_DIR/$ARCHIVE_NAME" "$RELEASE_URL"
fi

# Create installation directory if it doesn't exist
mkdir -p "$POTIONS_DIR"

# Extract files
echo "📂 Extracting files..."
tar -xzf "$TEMP_DIR/$ARCHIVE_NAME" -C "$TEMP_DIR"
find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -not -name "$ARCHIVE_NAME" -exec cp -r {} "$POTIONS_DIR" \;

# Copy hidden files (if any)
find "$TEMP_DIR" -name ".*" -not -path "$TEMP_DIR" -exec cp -r {} "$POTIONS_DIR" 2>/dev/null \; || true

echo "🔧 Installing..."
cd "$POTIONS_DIR"
chmod +x install.sh
./install.sh
