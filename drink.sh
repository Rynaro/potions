#!/bin/bash

# drink.sh - One-line installer for Potions
# Author: Henrique A. Lavezzo (Rynaro)

set -e

# Colors for output (Oh My Zsh style)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if terminal supports colors
if [ -t 1 ]; then
  HAS_COLOR=true
else
  HAS_COLOR=false
fi

# Disable colors if NO_COLOR is set
if [ -n "${NO_COLOR:-}" ]; then
  HAS_COLOR=false
fi

# Print header banner
print_header() {
  if [ "$HAS_COLOR" = true ]; then
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    echo "   ██████╗  ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗"
    echo "   ██╔══██╗██╔═══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝"
    echo "   ██████╔╝██║   ██║   ██║   ██║██║   ██║██╔██╗ ██║███████╗"
    echo "   ██╔═══╝ ██║   ██║   ██║   ██║██║   ██║██║╚██╗██║╚════██║"
    echo "   ██║     ╚██████╔╝   ██║   ██║╚██████╔╝██║ ╚████║███████║"
    echo "   ╚═╝      ╚═════╝    ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝"
    echo -e "${NC}"
    echo -e "${CYAN}${BOLD}           Welcome to Potions Installer${NC}"
    echo -e "${CYAN}              Your powerful dev environment${NC}"
    echo ""
  else
    echo ""
    echo "=========================================="
    echo "      POTIONS ONE-LINE INSTALLER"
    echo "=========================================="
    echo ""
  fi
}

# Logging functions
log_info() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${CYAN}${BOLD}⟹${NC} ${WHITE}$1${NC}"
  else
    echo "==> $1"
  fi
}

log_success() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${GREEN}${BOLD}✓${NC} ${GREEN}$1${NC}"
  else
    echo "[OK] $1"
  fi
}

log_error() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${RED}${BOLD}✗${NC} ${RED}$1${NC}"
  else
    echo "[ERROR] $1"
  fi
}

# Spinner function for long operations
spinner() {
  local pid=$1
  local message="${2:-Processing...}"
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  
  if [ "$HAS_COLOR" = false ]; then
    wait $pid
    return $?
  fi
  
  printf "${CYAN}${BOLD}⟹${NC} ${WHITE}${message}${NC} " >&2
  while kill -0 $pid 2>/dev/null; do
    for i in $(seq 0 $((${#spinstr}-1))); do
      printf "\b${spinstr:$i:1}" >&2
      sleep 0.1
    done
  done
  printf "\b${GREEN}${BOLD}✓${NC}\n" >&2
  wait $pid
  return $?
}

# Test mode detection
TEST_MODE=false
if [[ "$1" == "--test" ]]; then
  TEST_MODE=true
fi

print_header

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

log_info "Detected environment: ${BOLD}${OS_NAME}${NC}"

if [ "$TEST_MODE" = true ]; then
  log_warning "🧪 TEST MODE ENABLED - No changes will be made to your system"
fi

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
  log_success "Found curl"
elif command -v wget &> /dev/null; then
  DOWNLOAD_TOOL="wget"
  log_success "Found wget"
else
  log_error "Neither curl nor wget found. Installing curl..."

  # Install curl based on OS
  if [ "$OS_NAME" = "macOS" ]; then
    if ! command -v brew &> /dev/null; then
      log_info "Installing Homebrew first..."
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
  log_success "curl installed"
fi

# Check for git installation
if command -v git &> /dev/null; then
  HAS_GIT=true
  log_success "Found git"
else
  HAS_GIT=false
  log_info "Git not found, will use archive download"
fi

log_info "Preparing Potions installation..."

if [ "$HAS_GIT" = true ]; then
  log_info "Downloading Potions via Git..."
  if [ "$HAS_COLOR" = true ]; then
    (git clone --depth=1 https://github.com/Rynaro/potions.git "$TEMP_DIR/potions" 2>&1 | grep -v "^Cloning\|^remote\|^Resolving\|^Receiving" > /dev/null || true) &
    spinner $! "Downloading Potions"
  else
    git clone --depth=1 https://github.com/Rynaro/potions.git "$TEMP_DIR/potions"
  fi

  # Move files to installation directory (temporary staging area)
  # Note: Entire repo is copied here temporarily, but only .potions directory
  # is deployed to user's home during install.sh execution. AI agent docs
  # (AGENT.md, .cursorrules, etc.) remain git-only and are never deployed.
  mkdir -p "$POTIONS_DIR"
  if [ "$HAS_COLOR" = true ]; then
    (cp -r "$TEMP_DIR/potions/"* "$POTIONS_DIR/" 2>/dev/null; cp -r "$TEMP_DIR/potions/."* "$POTIONS_DIR/" 2>/dev/null || true) &
    spinner $! "Preparing files"
  else
    cp -r "$TEMP_DIR/potions/"* "$POTIONS_DIR/"
    cp -r "$TEMP_DIR/potions/."* "$POTIONS_DIR/" 2>/dev/null || true
  fi
  log_success "Potions downloaded"
else
  # Fallback to download via archive if git is not available
  log_info "Downloading Potions zip archive..."
  ARCHIVE_URL="https://github.com/Rynaro/potions/archive/refs/heads/main.zip"
  ARCHIVE_PATH="$TEMP_DIR/potions.zip"

  if [ "$HAS_COLOR" = true ]; then
    if [ "$DOWNLOAD_TOOL" = "curl" ]; then
      (curl -L "$ARCHIVE_URL" -o "$ARCHIVE_PATH" 2>/dev/null) &
      spinner $! "Downloading archive"
    else
      (wget -O "$ARCHIVE_PATH" "$ARCHIVE_URL" 2>/dev/null) &
      spinner $! "Downloading archive"
    fi
  else
    if [ "$DOWNLOAD_TOOL" = "curl" ]; then
      curl -L "$ARCHIVE_URL" -o "$ARCHIVE_PATH"
    else
      wget -O "$ARCHIVE_PATH" "$ARCHIVE_URL"
    fi
  fi

  # Check for unzip
  if ! command -v unzip &> /dev/null; then
    log_info "Installing unzip..."
    if [ "$OS_NAME" = "macOS" ]; then
      brew install unzip
    elif [ "$OS_NAME" = "Termux" ]; then
      pkg install -y unzip
    else
      sudo apt-get update
      sudo apt-get install -y unzip
    fi
    log_success "unzip installed"
  fi

  # Extract files
  log_info "Extracting files..."
  mkdir -p "$TEMP_DIR/extract"
  if [ "$HAS_COLOR" = true ]; then
    (unzip -q "$ARCHIVE_PATH" -d "$TEMP_DIR/extract" 2>/dev/null) &
    spinner $! "Extracting archive"
  else
    unzip -q "$ARCHIVE_PATH" -d "$TEMP_DIR/extract"
  fi

  # Create installation directory and copy files (temporary staging area)
  # Note: Entire repo is copied here temporarily, but only .potions directory
  # is deployed to user's home during install.sh execution. AI agent docs
  # (AGENT.md, .cursorrules, etc.) remain git-only and are never deployed.
  mkdir -p "$POTIONS_DIR"
  if [ "$HAS_COLOR" = true ]; then
    (cp -r "$TEMP_DIR/extract/"*/* "$POTIONS_DIR/" 2>/dev/null; cp -r "$TEMP_DIR/extract/"*/.* "$POTIONS_DIR/" 2>/dev/null || true) &
    spinner $! "Preparing files"
  else
    cp -r "$TEMP_DIR/extract/"*/* "$POTIONS_DIR/"
    cp -r "$TEMP_DIR/extract/"*/.* "$POTIONS_DIR/" 2>/dev/null || true
  fi
  log_success "Potions downloaded"
fi

echo ""
log_info "Starting installation..."
cd "$POTIONS_DIR"
chmod +x install.sh

if [ "$TEST_MODE" = true ]; then
  ./install.sh --test
else
  ./install.sh
fi

