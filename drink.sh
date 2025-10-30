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

# Check for git installation
if command -v git &> /dev/null; then
  HAS_GIT=true
else
  HAS_GIT=false
fi

if [ "$HAS_GIT" = true ]; then
  echo "📦 Downloading Potions via Git..."
  git clone --depth=1 https://github.com/Rynaro/potions.git "$TEMP_DIR/potions"

  # Move files to installation directory (temporary staging area)
  # Note: Entire repo is copied here temporarily, but only .potions directory
  # is deployed to user's home during install.sh execution. AI agent docs
  # (AGENT.md, .cursorrules, etc.) remain git-only and are never deployed.
  mkdir -p "$POTIONS_DIR"
  cp -r "$TEMP_DIR/potions/"* "$POTIONS_DIR/"
  cp -r "$TEMP_DIR/potions/."* "$POTIONS_DIR/" 2>/dev/null || true
else
  # Fallback to download via archive if git is not available
  echo "📦 Downloading Potions zip archive..."
  ARCHIVE_URL="https://github.com/Rynaro/potions/archive/refs/heads/main.zip"
  ARCHIVE_PATH="$TEMP_DIR/potions.zip"

  if [ "$DOWNLOAD_TOOL" = "curl" ]; then
    curl -L "$ARCHIVE_URL" -o "$ARCHIVE_PATH"
  else
    wget -O "$ARCHIVE_PATH" "$ARCHIVE_URL"
  fi

  # Check for unzip
  if ! command -v unzip &> /dev/null; then
    echo "Installing unzip..."
    if [ "$OS_NAME" = "macOS" ]; then
      brew install unzip
    elif [ "$OS_NAME" = "Termux" ]; then
      pkg install -y unzip
    else
      sudo apt-get update
      sudo apt-get install -y unzip
    fi
  fi

  # Extract files
  echo "📂 Extracting files..."
  mkdir -p "$TEMP_DIR/extract"
  unzip -q "$ARCHIVE_PATH" -d "$TEMP_DIR/extract"

  # Create installation directory and copy files (temporary staging area)
  # Note: Entire repo is copied here temporarily, but only .potions directory
  # is deployed to user's home during install.sh execution. AI agent docs
  # (AGENT.md, .cursorrules, etc.) remain git-only and are never deployed.
  mkdir -p "$POTIONS_DIR"
  cp -r "$TEMP_DIR/extract/"*/* "$POTIONS_DIR/"
  cp -r "$TEMP_DIR/extract/"*/.* "$POTIONS_DIR/" 2>/dev/null || true
fi

echo "🔧 Installing..."
cd "$POTIONS_DIR"
chmod +x install.sh
./install.sh

