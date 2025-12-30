#!/bin/bash

# migrate.sh - Migration script for Potions v2.5.0
# Author: Henrique A. Lavezzo (Rynaro)
#
# This script migrates existing Potions installations to the new configuration structure

set -eo pipefail

# Enable verbose mode when DEBUG is set
if [ "${DEBUG:-}" = "1" ]; then
  set -x
fi

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
BACKUP_DIR="$POTIONS_HOME/backups/pre-migration-$(date +%Y%m%d-%H%M%S)"

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

# Check if migration is needed
check_migration_needed() {
  # Check for legacy files that need migration
  local needs_migration=false

  if [ -f "$POTIONS_HOME/.zsh_aliases" ] && [ ! -f "$POTIONS_HOME/config/aliases.zsh" ]; then
    needs_migration=true
  fi

  if [ -f "$POTIONS_HOME/.zsh_secure_aliases" ] && [ ! -f "$POTIONS_HOME/config/secure.zsh" ]; then
    needs_migration=true
  fi

  if [ -d "$POTIONS_HOME/sources" ] && [ ! -d "$POTIONS_HOME/config" ]; then
    needs_migration=true
  fi

  if [ "$needs_migration" = false ]; then
    log_info "No migration needed - already using new configuration structure"
    return 1
  fi

  return 0
}

# Create backup
create_backup() {
  log_step "Creating backup"

  mkdir -p "$BACKUP_DIR"

  # Backup legacy files
  local files_to_backup=(
    ".zsh_aliases"
    ".zsh_secure_aliases"
    "sources"
  )

  for item in "${files_to_backup[@]}"; do
    if [ -e "$POTIONS_HOME/$item" ]; then
      cp -r "$POTIONS_HOME/$item" "$BACKUP_DIR/"
      log_info "Backed up: $item"
    fi
  done

  log_success "Backup created at $BACKUP_DIR"
}

# Migrate files
migrate_files() {
  log_step "Migrating configuration files"

  # Ensure config directory exists
  mkdir -p "$POTIONS_HOME/config"

  # Migrate .zsh_aliases -> config/aliases.zsh
  if [ -f "$POTIONS_HOME/.zsh_aliases" ]; then
    if [ -f "$POTIONS_HOME/config/aliases.zsh" ]; then
      # Append to existing file
      echo "" >> "$POTIONS_HOME/config/aliases.zsh"
      echo "# Migrated from .zsh_aliases" >> "$POTIONS_HOME/config/aliases.zsh"
      cat "$POTIONS_HOME/.zsh_aliases" >> "$POTIONS_HOME/config/aliases.zsh"
    else
      # Create new file with header
      {
        echo "# User Aliases and Functions"
        echo "# Migrated from .zsh_aliases"
        echo ""
        cat "$POTIONS_HOME/.zsh_aliases"
      } > "$POTIONS_HOME/config/aliases.zsh"
    fi
    log_success "Migrated .zsh_aliases -> config/aliases.zsh"
  fi

  # Migrate .zsh_secure_aliases -> config/secure.zsh
  if [ -f "$POTIONS_HOME/.zsh_secure_aliases" ]; then
    if [ -f "$POTIONS_HOME/config/secure.zsh" ]; then
      echo "" >> "$POTIONS_HOME/config/secure.zsh"
      echo "# Migrated from .zsh_secure_aliases" >> "$POTIONS_HOME/config/secure.zsh"
      cat "$POTIONS_HOME/.zsh_secure_aliases" >> "$POTIONS_HOME/config/secure.zsh"
    else
      {
        echo "# Secure/Private Aliases"
        echo "# Migrated from .zsh_secure_aliases"
        echo ""
        cat "$POTIONS_HOME/.zsh_secure_aliases"
      } > "$POTIONS_HOME/config/secure.zsh"
    fi
    log_success "Migrated .zsh_secure_aliases -> config/secure.zsh"
  fi

  # Migrate sources/*.sh -> config/*.zsh
  if [ -d "$POTIONS_HOME/sources" ]; then
    # macos.sh -> config/macos.zsh
    if [ -f "$POTIONS_HOME/sources/macos.sh" ]; then
      {
        echo "# macOS-specific Configuration"
        echo "# Migrated from sources/macos.sh"
        echo ""
        cat "$POTIONS_HOME/sources/macos.sh"
      } > "$POTIONS_HOME/config/macos.zsh"
      log_success "Migrated sources/macos.sh -> config/macos.zsh"
    fi

    # linux.sh -> config/linux.zsh
    if [ -f "$POTIONS_HOME/sources/linux.sh" ]; then
      {
        echo "# Linux-specific Configuration"
        echo "# Migrated from sources/linux.sh"
        echo ""
        cat "$POTIONS_HOME/sources/linux.sh"
      } > "$POTIONS_HOME/config/linux.zsh"
      log_success "Migrated sources/linux.sh -> config/linux.zsh"
    fi

    # wsl.sh -> config/wsl.zsh
    if [ -f "$POTIONS_HOME/sources/wsl.sh" ]; then
      {
        echo "# WSL-specific Configuration"
        echo "# Migrated from sources/wsl.sh"
        echo ""
        cat "$POTIONS_HOME/sources/wsl.sh"
      } > "$POTIONS_HOME/config/wsl.zsh"
      log_success "Migrated sources/wsl.sh -> config/wsl.zsh"
    fi

    # termux.sh -> config/termux.zsh
    if [ -f "$POTIONS_HOME/sources/termux.sh" ]; then
      {
        echo "# Termux-specific Configuration"
        echo "# Migrated from sources/termux.sh"
        echo ""
        cat "$POTIONS_HOME/sources/termux.sh"
      } > "$POTIONS_HOME/config/termux.zsh"
      log_success "Migrated sources/termux.sh -> config/termux.zsh"
    fi
  fi

  # Create placeholder files if they don't exist
  if [ ! -f "$POTIONS_HOME/config/local.zsh" ]; then
    cat > "$POTIONS_HOME/config/local.zsh" << 'EOF'
# Local Machine Configuration
# This file is for machine-specific settings (not synced)
EOF
    log_info "Created config/local.zsh"
  fi

  if [ ! -f "$POTIONS_HOME/nvim/user.vim" ]; then
    cat > "$POTIONS_HOME/nvim/user.vim" << 'EOF'
" User Neovim Configuration
" Add your custom settings here
EOF
    log_info "Created nvim/user.vim"
  fi

  if [ ! -f "$POTIONS_HOME/tmux/user.conf" ]; then
    cat > "$POTIONS_HOME/tmux/user.conf" << 'EOF'
# User Tmux Configuration
# Add your custom settings here
EOF
    log_info "Created tmux/user.conf"
  fi
}

# Print completion message
print_completion() {
  echo ""
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}${BOLD}  ✓ Migration completed successfully!${NC}"
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Changes made:${NC}"
    echo -e "  ${CYAN}•${NC} Legacy files backed up to: ${CYAN}$BACKUP_DIR${NC}"
    echo -e "  ${CYAN}•${NC} New config files created in: ${CYAN}~/.potions/config/${NC}"
    echo ""
    echo -e "${WHITE}New structure:${NC}"
    echo -e "  ${CYAN}config/aliases.zsh${NC}  - Your custom aliases and functions"
    echo -e "  ${CYAN}config/secure.zsh${NC}   - Private/sensitive configurations"
    echo -e "  ${CYAN}config/local.zsh${NC}    - Machine-specific settings"
    echo -e "  ${CYAN}config/{platform}.zsh${NC} - Platform-specific settings"
    echo -e "  ${CYAN}nvim/user.vim${NC}       - Your Neovim customizations"
    echo -e "  ${CYAN}tmux/user.conf${NC}      - Your Tmux customizations"
    echo ""
    echo -e "${WHITE}Next steps:${NC}"
    echo -e "  ${CYAN}1.${NC} Restart your terminal or run ${BOLD}exec zsh${NC}"
    echo -e "  ${CYAN}2.${NC} Review and organize your settings in the new files"
    echo -e "  ${CYAN}3.${NC} (Optional) Remove legacy files after verifying migration"
    echo ""
    echo -e "${YELLOW}Note:${NC} Legacy files are still loaded for backwards compatibility."
    echo -e "      You can safely remove them after verifying your config works."
    echo ""
  else
    echo "========================================"
    echo "  Migration completed successfully!"
    echo "========================================"
    echo ""
    echo "Legacy files backed up to: $BACKUP_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal or run 'exec zsh'"
    echo "  2. Review your settings in ~/.potions/config/"
    echo ""
  fi
}

# Main function
main() {
  log_step "Potions Configuration Migration"
  log_info "This script migrates your configuration to the new structure"
  echo ""

  # Check if Potions is installed
  if [ ! -d "$POTIONS_HOME" ]; then
    log_error "Potions is not installed at $POTIONS_HOME"
    exit 1
  fi

  # Check if migration is needed
  if ! check_migration_needed; then
    exit 0
  fi

  # Confirm migration
  if [ "$1" != "--force" ] && [ "$1" != "-f" ]; then
    read -p "Continue with migration? [Y/n] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
      log_info "Migration cancelled."
      exit 0
    fi
  fi

  # Perform migration
  create_backup
  migrate_files
  print_completion
}

# Run main
main "$@"
