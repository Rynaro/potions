#!/bin/bash

# uninstall.sh - Uninstaller for Potions
# Author: Henrique A. Lavezzo (Rynaro)
#
# This script removes Potions from your system while preserving user customizations

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Configuration
POTIONS_HOME="$HOME/.potions"
BACKUP_DIR="$HOME/.potions-backup-$(date +%Y%m%d-%H%M%S)"

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

log_warning() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${YELLOW}${BOLD}⚠${NC} ${YELLOW}$1${NC}"
  else
    echo "[WARN] $1"
  fi
}

log_error() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${RED}${BOLD}✗${NC} ${RED}$1${NC}"
  else
    echo "[ERROR] $1"
  fi
}

log_step() {
  if [ "$HAS_COLOR" = true ]; then
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  else
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
  fi
}

# Print header
print_header() {
  echo ""
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${RED}${BOLD}"
    echo "   ██████╗  ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗"
    echo "   ██╔══██╗██╔═══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝"
    echo "   ██████╔╝██║   ██║   ██║   ██║██║   ██║██╔██╗ ██║███████╗"
    echo "   ██╔═══╝ ██║   ██║   ██║   ██║██║   ██║██║╚██╗██║╚════██║"
    echo "   ██║     ╚██████╔╝   ██║   ██║╚██████╔╝██║ ╚████║███████║"
    echo "   ╚═╝      ╚═════╝    ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝"
    echo -e "${NC}"
    echo -e "${RED}${BOLD}                    Uninstalling Potions${NC}"
    echo ""
  else
    echo "=========================================="
    echo "         POTIONS UNINSTALLER"
    echo "=========================================="
    echo ""
  fi
}

# Confirm uninstallation
confirm_uninstall() {
  log_warning "This will remove Potions from your system."
  log_info "Your customizations will be backed up to: $BACKUP_DIR"
  echo ""

  if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    return 0
  fi

  read -p "Are you sure you want to continue? [y/N] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Uninstallation cancelled."
    exit 0
  fi
}

# Backup user customizations
backup_customizations() {
  log_step "Backing up customizations"

  if [ ! -d "$POTIONS_HOME" ]; then
    log_warning "Potions installation not found at $POTIONS_HOME"
    return 0
  fi

  mkdir -p "$BACKUP_DIR"

  # Files to preserve
  local files_to_backup=(
    ".zsh_aliases"
    ".zsh_secure_aliases"
    "config/aliases.zsh"
    "config/secure.zsh"
    "config/local.zsh"
    "config/macos.zsh"
    "config/linux.zsh"
    "config/wsl.zsh"
    "config/termux.zsh"
    "nvim/user.vim"
    "tmux/user.conf"
    "sources/macos.sh"
    "sources/linux.sh"
    "sources/wsl.sh"
    "sources/termux.sh"
  )

  local backed_up=0
  for file in "${files_to_backup[@]}"; do
    if [ -f "$POTIONS_HOME/$file" ]; then
      local dir=$(dirname "$BACKUP_DIR/$file")
      mkdir -p "$dir"
      cp "$POTIONS_HOME/$file" "$BACKUP_DIR/$file"
      log_info "Backed up: $file"
      # Note: Use $((var + 1)) instead of ((var++)) to avoid exit code 1
      # when var=0, which would fail under set -e
      backed_up=$((backed_up + 1))
    fi
  done

  if [ $backed_up -gt 0 ]; then
    log_success "Backed up $backed_up customization files"
  else
    log_info "No customization files found to backup"
  fi
}

# Remove Potions files
remove_potions() {
  log_step "Removing Potions"

  # Remove .potions directory
  if [ -d "$POTIONS_HOME" ]; then
    rm -rf "$POTIONS_HOME"
    log_success "Removed $POTIONS_HOME"
  else
    log_warning "$POTIONS_HOME not found"
  fi

  # Backup and remove .zshenv
  if [ -f "$HOME/.zshenv" ]; then
    # Check if it's a Potions .zshenv
    if grep -q "ZDOTDIR.*potions" "$HOME/.zshenv" 2>/dev/null; then
      cp "$HOME/.zshenv" "$BACKUP_DIR/.zshenv"
      rm "$HOME/.zshenv"
      log_success "Removed ~/.zshenv (backed up)"
    else
      log_warning "~/.zshenv exists but doesn't appear to be from Potions, leaving it"
    fi
  fi
}

# Revert shell
revert_shell() {
  log_step "Shell Configuration"

  local current_shell=$(basename "$SHELL")
  if [ "$current_shell" = "zsh" ]; then
    log_info "Your current shell is Zsh"
    log_info "To revert to Bash, run: chsh -s $(which bash)"
    log_info "Or keep using Zsh with your own configuration"
  else
    log_info "Your current shell is $current_shell (not Zsh)"
  fi
}

# Print completion message
print_completion() {
  echo ""
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}${BOLD}  ✓ Potions has been uninstalled${NC}"
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Your customizations are saved at:${NC}"
    echo -e "  ${CYAN}$BACKUP_DIR${NC}"
    echo ""
    echo -e "${WHITE}To complete the uninstallation:${NC}"
    echo -e "  ${CYAN}1.${NC} Close this terminal and open a new one"
    echo -e "  ${CYAN}2.${NC} (Optional) Change your shell: ${BOLD}chsh -s \$(which bash)${NC}"
    echo ""
    echo -e "${WHITE}To reinstall Potions:${NC}"
    echo -e "  ${CYAN}curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/drink.sh | bash${NC}"
    echo ""
  else
    echo "========================================"
    echo "  Potions has been uninstalled"
    echo "========================================"
    echo ""
    echo "Your customizations are saved at:"
    echo "  $BACKUP_DIR"
    echo ""
    echo "To complete the uninstallation:"
    echo "  1. Close this terminal and open a new one"
    echo "  2. (Optional) Change your shell: chsh -s \$(which bash)"
    echo ""
    echo "To reinstall Potions:"
    echo "  curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/drink.sh | bash"
    echo ""
  fi
}

# Main function
main() {
  print_header
  confirm_uninstall "$1"
  backup_customizations
  remove_potions
  revert_shell
  print_completion
}

# Run main
main "$@"
