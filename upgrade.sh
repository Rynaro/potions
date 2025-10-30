#!/bin/bash

# upgrade.sh - Safe one-command upgrader for Potions
# Author: Henrique A. Lavezzo (Rynaro)
#
# This script safely upgrades your Potions installation while preserving
# all user customizations and providing rollback capabilities.

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
POTIONS_REPO_URL="https://github.com/Rynaro/potions.git"
POTIONS_REPO_BRANCH="main"
POTIONS_HOME="$HOME/.potions"
POTIONS_REPO_DIR="$POTIONS_HOME/.repo"
POTIONS_BACKUPS_DIR="$POTIONS_HOME/backups"
BACKUP_DIR="$POTIONS_BACKUPS_DIR/backup-$(date +%Y%m%d-%H%M%S)"
TEMP_DIR=$(mktemp -d)

# Cleanup function
cleanup() {
  if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

# Logging functions
log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

log_step() {
  echo -e "\n${BLUE}▶${NC} $1"
}

# Check if Potions is installed
check_potions_installed() {
  if [ ! -d "$POTIONS_HOME" ]; then
    log_error "Potions is not installed. Please install it first using:"
    echo "  curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/drink.sh | bash"
    exit 1
  fi
  log_success "Potions installation detected at $POTIONS_HOME"
}

# Create backup of current installation
create_backup() {
  log_step "Creating backup..."
  mkdir -p "$BACKUP_DIR"
  
  # Backup entire .potions directory (excluding repo and backups directories to avoid recursion)
  if [ -d "$POTIONS_HOME" ]; then
    # Use rsync if available for better exclusion control
    if command -v rsync &> /dev/null; then
      rsync -av --exclude='.repo' --exclude='backups' "$POTIONS_HOME/" "$BACKUP_DIR/"
    else
      # Fallback: copy manually excluding .repo and backups
      find "$POTIONS_HOME" -mindepth 1 -maxdepth 1 \
        -not -name '.repo' \
        -not -name 'backups' \
        -exec cp -r {} "$BACKUP_DIR/" \;
    fi
    log_success "Backup created at $BACKUP_DIR"
  else
    log_warning "No existing installation found to backup"
  fi
}

# Detect and prepare repository location
prepare_repository() {
  log_step "Preparing repository..."
  
  local repo_dir=""
  
  # Strategy 1: Use .potions/.repo if it exists and is a git repo
  if [ -d "$POTIONS_REPO_DIR" ] && [ -d "$POTIONS_REPO_DIR/.git" ]; then
    repo_dir="$POTIONS_REPO_DIR"
    log_info "Found existing repository at $repo_dir"
    cd "$repo_dir"
    
    # Update the repository
    if git rev-parse --git-dir > /dev/null 2>&1; then
      log_info "Updating repository..."
      git fetch origin "$POTIONS_REPO_BRANCH" || log_warning "Failed to fetch updates"
      git checkout "$POTIONS_REPO_BRANCH" || true
      git pull origin "$POTIONS_REPO_BRANCH" || log_warning "Failed to pull updates"
      log_success "Repository updated"
    fi
  # Strategy 2: Check if current directory is potions repo (for manual upgrades)
  elif [ -d ".git" ] && [ -f "install.sh" ] && [ -d ".potions" ]; then
    repo_dir="$(pwd)"
    log_info "Using current directory as repository: $repo_dir"
    cd "$repo_dir"
    
    # Update if it's a git repo
    if git rev-parse --git-dir > /dev/null 2>&1; then
      log_info "Updating repository..."
      git fetch origin "$POTIONS_REPO_BRANCH" || log_warning "Failed to fetch updates"
      git checkout "$POTIONS_REPO_BRANCH" || true
      git pull origin "$POTIONS_REPO_BRANCH" || log_warning "Failed to pull updates"
      log_success "Repository updated"
    fi
  # Strategy 3: Clone fresh copy to .potions/.repo
  else
    log_info "Cloning repository to $POTIONS_REPO_DIR..."
    mkdir -p "$POTIONS_REPO_DIR"
    
    if command -v git &> /dev/null; then
      # Clone to temp first, then move to final location
      local temp_repo="$TEMP_DIR/potions"
      git clone --depth=1 --branch "$POTIONS_REPO_BRANCH" "$POTIONS_REPO_URL" "$temp_repo"
      
      # Move to final location (preserve existing .repo if it exists but isn't a git repo)
      if [ -d "$POTIONS_REPO_DIR" ] && [ ! -d "$POTIONS_REPO_DIR/.git" ]; then
        rm -rf "$POTIONS_REPO_DIR"
      fi
      mv "$temp_repo" "$POTIONS_REPO_DIR"
      repo_dir="$POTIONS_REPO_DIR"
      log_success "Repository cloned"
    else
      log_error "Git is not installed. Cannot upgrade without git."
      log_info "You can manually install git or re-run the installer:"
      echo "  curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/drink.sh | bash"
      exit 1
    fi
  fi
  
  # Make install.sh executable
  if [ -f "$repo_dir/install.sh" ]; then
    chmod +x "$repo_dir/install.sh"
  fi
  
  echo "$repo_dir"
}

# Preserve user customizations
preserve_user_files() {
  log_step "Preserving user customizations..."
  
  local repo_dir="$1"
  local preserved_files=(
    ".zsh_aliases"
    ".zsh_secure_aliases"
    "sources/macos.sh"
    "sources/linux.sh"
    "sources/wsl.sh"
    "sources/termux.sh"
  )
  
  for file in "${preserved_files[@]}"; do
    local user_file="$POTIONS_HOME/$file"
    local new_file="$repo_dir/.potions/$file"
    
    if [ -f "$user_file" ] && [ -f "$new_file" ]; then
      # Check if files are different
      if ! cmp -s "$user_file" "$new_file"; then
        log_info "Processing $file..."
        
        # Backup user's original file
        cp "$user_file" "$POTIONS_HOME/$file.backup"
        
        # For .zsh_aliases and .zsh_secure_aliases, try to preserve user additions
        # Strategy: Append user lines that don't exist in new file
        if [ "$file" = ".zsh_aliases" ] || [ "$file" = ".zsh_secure_aliases" ]; then
          # Create merged version: new content + user additions
          cp "$new_file" "$user_file"
          
          # Extract user-specific lines (lines in user file but not in new file)
          # Use comm command if available, otherwise use simpler diff approach
          local user_additions=""
          if command -v comm &> /dev/null; then
            # Ensure files are not empty before sorting
            if [ -s "$new_file" ] && [ -s "$user_file.backup" ]; then
              user_additions=$(comm -13 <(sort "$new_file") <(sort "$user_file.backup") 2>/dev/null || true)
            elif [ -s "$user_file.backup" ]; then
              # If new file is empty but user file has content, preserve all user content
              user_additions=$(cat "$user_file.backup")
            fi
          else
            # Fallback: simple diff approach (less accurate but works everywhere)
            log_warning "  'comm' command not available, using simple merge strategy"
            # Just keep the new version and warn user
            user_additions=""
          fi
          
          if [ -n "$user_additions" ]; then
            echo "" >> "$user_file"
            echo "# User customizations (automatically preserved during upgrade)" >> "$user_file"
            echo "$user_additions" >> "$user_file"
            log_success "  Merged user customizations into $file"
          else
            log_info "  Updated $file (no user customizations detected)"
          fi
        else
          # For other files (sources/*.sh), be more conservative
          # Just update and warn user to check backup
          cp "$new_file" "$user_file"
          log_warning "  Updated $file. Your original saved to $file.backup"
          log_info "  Please review $file.backup and merge manually if needed"
        fi
      else
        log_info "  $file is up to date"
      fi
    elif [ -f "$new_file" ] && [ ! -f "$user_file" ]; then
      # New file that doesn't exist in user's installation
      mkdir -p "$(dirname "$POTIONS_HOME/$file")"
      cp "$new_file" "$user_file"
      log_info "  Added new file: $file"
    fi
  done
  
  log_success "User customizations preserved"
}

# Update dotfiles
update_dotfiles() {
  log_step "Updating configuration files..."
  
  local repo_dir="$1"
  local preserved_files=(
    ".zsh_aliases"
    ".zsh_secure_aliases"
    "sources/macos.sh"
    "sources/linux.sh"
    "sources/wsl.sh"
    "sources/termux.sh"
  )
  
  if [ ! -d "$repo_dir/.potions" ]; then
    log_error "Cannot find .potions directory in repository"
    return 1
  fi
  
  # Update files while preserving user customizations
  preserve_user_files "$repo_dir"
  
  # Copy new/updated files (excluding preserved ones that we handled specially)
  log_info "Copying updated files..."
  
  # Copy new files and update existing ones (excluding preserved files)
  # First, ensure directory structure exists
  find "$repo_dir/.potions" -type d | while read -r dir; do
    rel_dir="${dir#$repo_dir/.potions/}"
    if [ -n "$rel_dir" ]; then
      mkdir -p "$POTIONS_HOME/$rel_dir"
    fi
  done
  
  # Copy files, excluding preserved ones
  find "$repo_dir/.potions" -type f | while read -r file; do
    rel_file="${file#$repo_dir/.potions/}"
    
    # Skip preserved files (already handled)
    should_skip=false
    for preserved in "${preserved_files[@]}"; do
      if [ "$rel_file" = "$preserved" ]; then
        should_skip=true
        break
      fi
    done
    
    if [ "$should_skip" = false ]; then
      cp "$file" "$POTIONS_HOME/$rel_file"
    fi
  done
  
  log_success "Dotfiles updated"
}

# Clean up old backups (keep last 5 backups)
cleanup_old_backups() {
  log_step "Cleaning up old backups..."
  
  if [ -d "$POTIONS_BACKUPS_DIR" ]; then
    # Keep only the 5 most recent backups
    # Backup directories are named backup-YYYYMMDD-HHMMSS, so we can sort by name
    local backup_count=$(find "$POTIONS_BACKUPS_DIR" -maxdepth 1 -type d -name "backup-*" 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$backup_count" -gt 5 ]; then
      # Sort by directory name (which includes timestamp), keep newest 5, delete oldest
      find "$POTIONS_BACKUPS_DIR" -maxdepth 1 -type d -name "backup-*" | \
        sort -r | \
        tail -n +6 | \
        xargs rm -rf 2>/dev/null || true
      
      log_info "Kept 5 most recent backups"
    fi
  fi
}

# Main upgrade function
main() {
  echo "🧪 Potions Upgrader"
  echo "==================="
  echo ""
  
  # Check if Potions is installed
  check_potions_installed
  
  # Create backup
  create_backup
  
  # Prepare repository
  repo_dir=$(prepare_repository)
  
  if [ -z "$repo_dir" ] || [ ! -d "$repo_dir" ]; then
    log_error "Failed to prepare repository"
    exit 1
  fi
  
  # Update dotfiles
  update_dotfiles "$repo_dir"
  
  # Clean up old backups
  cleanup_old_backups
  
  # Success message
  echo ""
  log_success "Potions has been upgraded successfully!"
  echo ""
  log_info "Backup location: $BACKUP_DIR"
  log_info "If something went wrong, you can restore from backup:"
  echo "  cp -r $BACKUP_DIR/* $POTIONS_HOME/"
  echo ""
  log_info "Review any .backup files in $POTIONS_HOME for customizations"
  log_info "Restart your terminal or run 'exec zsh' to apply changes"
  echo ""
}

# Run main function
main "$@"
