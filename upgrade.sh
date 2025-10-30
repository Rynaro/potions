#!/bin/bash

# upgrade.sh - Safe one-command upgrader for Potions
# Author: Henrique A. Lavezzo (Rynaro)
#
# This script safely upgrades your Potions installation while preserving
# all user customizations and providing rollback capabilities.

set -eo pipefail

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

# Configuration
POTIONS_REPO_URL="https://github.com/Rynaro/potions.git"
POTIONS_REPO_BRANCH="main"
POTIONS_HOME="$HOME/.potions"
POTIONS_REPO_DIR="$POTIONS_HOME/.repo"
POTIONS_BACKUPS_DIR="$POTIONS_HOME/backups"
BACKUP_DIR="$POTIONS_BACKUPS_DIR/backup-$(date +%Y%m%d-%H%M%S)"
TEMP_DIR=$(mktemp -d)

# Get current script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get version from .version file (check repo root or installed location)
get_version() {
  local version_file=""
  # Try repo root first (if running from repo)
  if [ -f "$SCRIPT_DIR/.version" ]; then
    version_file="$SCRIPT_DIR/.version"
  # Try installed location
  elif [ -f "$POTIONS_HOME/.version" ]; then
    version_file="$POTIONS_HOME/.version"
  # Try repo directory
  elif [ -f "$POTIONS_REPO_DIR/.version" ]; then
    version_file="$POTIONS_REPO_DIR/.version"
  fi
  
  if [ -n "$version_file" ] && [ -f "$version_file" ]; then
    cat "$version_file" | tr -d '[:space:]'
  else
    echo ""
  fi
}

# Cleanup function
cleanup() {
  if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

# Logging functions with Oh My Zsh style (output to stderr so stdout can be captured)
log_info() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${CYAN}${BOLD}⟹${NC} ${WHITE}$1${NC}" >&2
  else
    echo "==> $1" >&2
  fi
}

log_success() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${GREEN}${BOLD}✓${NC} ${GREEN}$1${NC}" >&2
  else
    echo "[OK] $1" >&2
  fi
}

log_warning() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${YELLOW}${BOLD}⚠${NC} ${YELLOW}$1${NC}" >&2
  else
    echo "[WARN] $1" >&2
  fi
}

log_error() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${RED}${BOLD}✗${NC} ${RED}$1${NC}" >&2
  else
    echo "[ERROR] $1" >&2
  fi
}

log_step() {
  if [ "$HAS_COLOR" = true ]; then
    echo "" >&2
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
    echo -e "${BLUE}${BOLD}  $1${NC}" >&2
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
  else
    echo "" >&2
    echo "========================================" >&2
    echo "  $1" >&2
    echo "========================================" >&2
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

# Print header banner
print_header() {
  if [ "$HAS_COLOR" = true ]; then
    echo "" >&2
    echo -e "${MAGENTA}${BOLD}" >&2
    echo "   ██████╗  ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗" >&2
    echo "   ██╔══██╗██╔═══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝" >&2
    echo "   ██████╔╝██║   ██║   ██║   ██║██║   ██║██╔██╗ ██║███████╗" >&2
    echo "   ██╔═══╝ ██║   ██║   ██║   ██║██║   ██║██║╚██╗██║╚════██║" >&2
    echo "   ██║     ╚██████╔╝   ██║   ██║╚██████╔╝██║ ╚████║███████║" >&2
    echo "   ╚═╝      ╚═════╝    ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝" >&2
    echo -e "${NC}" >&2
    local version=$(get_version)
    if [ -n "$version" ]; then
      echo -e "${CYAN}${BOLD}                    Upgrading Potions${NC}" >&2
      echo -e "${CYAN}              Your powerful dev environment${NC}" >&2
      echo -e "${CYAN}                         v${version}${NC}" >&2
    else
      echo -e "${CYAN}${BOLD}                    Upgrading Potions${NC}" >&2
      echo -e "${CYAN}              Your powerful dev environment${NC}" >&2
    fi
    echo "" >&2
  else
    echo "" >&2
    local version=$(get_version)
    echo "==========================================" >&2
    echo "          POTIONS UPGRADER" >&2
    if [ -n "$version" ]; then
      echo "                  v${version}" >&2
    fi
    echo "==========================================" >&2
    echo "" >&2
  fi
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

# Read version from file
read_version() {
  local version_file="$1"
  if [ -f "$version_file" ]; then
    cat "$version_file" | tr -d '[:space:]'
  else
    echo "0.0.0"
  fi
}

# Compare version strings (returns 0 if v1 < v2, 1 if v1 >= v2)
version_compare() {
  local v1="$1"
  local v2="$2"
  
  # Use awk for version comparison
  local result=$(awk -v v1="$v1" -v v2="$v2" 'BEGIN {
    split(v1, a, ".")
    split(v2, b, ".")
    for (i=1; i<=3; i++) {
      a[i] = a[i] ? a[i] : 0
      b[i] = b[i] ? b[i] : 0
      if (a[i] < b[i]) { exit 0 }
      if (a[i] > b[i]) { exit 1 }
    }
    exit 1
  }')
  
  return $result
}

# Verify checksums of critical files
verify_checksums() {
  local repo_dir="$1"
  local checksums_file="$repo_dir/.checksums"
  
  if [ ! -f "$checksums_file" ]; then
    log_warning "Checksums file not found, skipping verification"
    return 0
  fi
  
  log_info "Verifying file integrity..."
  local failed=0
  
  while IFS=' ' read -r file expected_checksum; do
    # Skip empty lines and comments
    [[ -z "$file" || "$file" =~ ^# ]] && continue
    
    local file_path="$repo_dir/$file"
    if [ ! -f "$file_path" ]; then
      log_warning "File not found: $file"
      failed=1
      continue
    fi
    
    # Calculate SHA256 checksum
    local actual_checksum=""
    if command -v shasum &> /dev/null; then
      actual_checksum=$(shasum -a 256 "$file_path" | awk '{print $1}')
    elif command -v sha256sum &> /dev/null; then
      actual_checksum=$(sha256sum "$file_path" | awk '{print $1}')
    else
      log_warning "No checksum tool found, skipping verification"
      return 0
    fi
    
    if [ "$actual_checksum" != "$expected_checksum" ]; then
      log_error "Checksum mismatch for $file"
      log_error "  Expected: $expected_checksum"
      log_error "  Got:      $actual_checksum"
      failed=1
    fi
  done < "$checksums_file"
  
  if [ $failed -eq 1 ]; then
    log_error "Checksum verification failed! Installation may be compromised."
    return 1
  fi
  
  log_success "All checksums verified"
  return 0
}

# Check if upgrade is needed
check_upgrade_needed() {
  local repo_dir="$1"
  local remote_version_file="$repo_dir/.version"
  local local_version_file="$POTIONS_HOME/.version"
  
  local remote_version=$(read_version "$remote_version_file")
  local local_version=$(read_version "$local_version_file")
  
  log_info "Current version: $local_version"
  log_info "Remote version:  $remote_version"
  
  if version_compare "$local_version" "$remote_version"; then
    return 0  # Upgrade needed
  else
    log_success "Already at latest version ($local_version)"
    return 1  # No upgrade needed
  fi
}

# Create backup of current installation
create_backup() {
  log_step "Creating backup"
  
  mkdir -p "$BACKUP_DIR"
  
  # Backup entire .potions directory (excluding repo and backups directories to avoid recursion)
  if [ -d "$POTIONS_HOME" ]; then
    log_info "Backing up configuration files..."
    
    # Use rsync if available for better exclusion control
    if command -v rsync &> /dev/null; then
      if [ "$HAS_COLOR" = true ]; then
        rsync -av --exclude='.repo' --exclude='backups' "$POTIONS_HOME/" "$BACKUP_DIR/" > /dev/null 2>&1 &
        spinner $! "Copying files"
      else
        rsync -av --exclude='.repo' --exclude='backups' "$POTIONS_HOME/" "$BACKUP_DIR/" > /dev/null 2>&1
        echo "[OK] Backup created"
      fi
    else
      # Fallback: copy manually excluding .repo and backups
      if [ "$HAS_COLOR" = true ]; then
        (
          find "$POTIONS_HOME" -mindepth 1 -maxdepth 1 \
            -not -name '.repo' \
            -not -name 'backups' \
            -exec cp -r {} "$BACKUP_DIR/" \; 2>/dev/null
        ) &
        spinner $! "Copying files"
      else
        find "$POTIONS_HOME" -mindepth 1 -maxdepth 1 \
          -not -name '.repo' \
          -not -name 'backups' \
          -exec cp -r {} "$BACKUP_DIR/" \; 2>/dev/null
        echo "[OK] Backup created"
      fi
    fi
    
    log_success "Backup created at ${BACKUP_DIR#$HOME/}"
  else
    log_warning "No existing installation found to backup"
  fi
}

# Detect and prepare repository location
prepare_repository() {
  log_step "Preparing repository"
  
  local repo_dir=""
  
  # Strategy 1: Use .potions/.repo if it exists and is a git repo
  if [ -d "$POTIONS_REPO_DIR" ] && [ -d "$POTIONS_REPO_DIR/.git" ]; then
    repo_dir="$POTIONS_REPO_DIR"
    log_info "Found existing repository"
    cd "$repo_dir"
    
    # Update the repository
    if git rev-parse --git-dir > /dev/null 2>&1; then
      log_info "Fetching latest changes..."
      if [ "$HAS_COLOR" = true ]; then
        (git fetch origin "$POTIONS_REPO_BRANCH" > /dev/null 2>&1) &
        spinner $! "Fetching updates"
      else
        git fetch origin "$POTIONS_REPO_BRANCH" > /dev/null 2>&1 || log_warning "Failed to fetch updates"
      fi
      
      log_info "Updating to latest version..."
      git checkout "$POTIONS_REPO_BRANCH" > /dev/null 2>&1 || true
      if [ "$HAS_COLOR" = true ]; then
        (git pull origin "$POTIONS_REPO_BRANCH" > /dev/null 2>&1) &
        spinner $! "Applying updates"
      else
        git pull origin "$POTIONS_REPO_BRANCH" > /dev/null 2>&1 || log_warning "Failed to pull updates"
      fi
      log_success "Repository updated"
    fi
  # Strategy 2: Check if current directory is potions repo (for manual upgrades)
  elif [ -d ".git" ] && [ -f "install.sh" ] && [ -d ".potions" ]; then
    repo_dir="$(pwd)"
    log_info "Using current directory as repository"
    cd "$repo_dir"
    
    # Update if it's a git repo
    if git rev-parse --git-dir > /dev/null 2>&1; then
      log_info "Fetching latest changes..."
      if [ "$HAS_COLOR" = true ]; then
        (git fetch origin "$POTIONS_REPO_BRANCH" > /dev/null 2>&1) &
        spinner $! "Fetching updates"
      else
        git fetch origin "$POTIONS_REPO_BRANCH" > /dev/null 2>&1 || log_warning "Failed to fetch updates"
      fi
      
      log_info "Updating to latest version..."
      git checkout "$POTIONS_REPO_BRANCH" > /dev/null 2>&1 || true
      if [ "$HAS_COLOR" = true ]; then
        (git pull origin "$POTIONS_REPO_BRANCH" > /dev/null 2>&1) &
        spinner $! "Applying updates"
      else
        git pull origin "$POTIONS_REPO_BRANCH" > /dev/null 2>&1 || log_warning "Failed to pull updates"
      fi
      log_success "Repository updated"
    fi
  # Strategy 3: Clone fresh copy to .potions/.repo
  else
    log_info "Cloning fresh repository..."
    
    if command -v git &> /dev/null; then
      # Clone to temp first, then move to final location
      local temp_repo="$TEMP_DIR/potions"
      
      # Remove existing .repo if it's not a valid git repo
      if [ -d "$POTIONS_REPO_DIR" ]; then
        if [ ! -d "$POTIONS_REPO_DIR/.git" ]; then
          log_info "Cleaning up existing directory"
          rm -rf "$POTIONS_REPO_DIR"
        fi
      fi
      
      # Ensure parent directory exists
      mkdir -p "$(dirname "$POTIONS_REPO_DIR")"
      
      # Clone to temp location with spinner
      log_info "Downloading repository..."
      if [ "$HAS_COLOR" = true ]; then
        (git clone --depth=1 --branch "$POTIONS_REPO_BRANCH" "$POTIONS_REPO_URL" "$temp_repo" > /dev/null 2>&1) &
        if ! spinner $! "Downloading Potions"; then
          log_error "Failed to clone repository"
          return 1
        fi
      else
        if ! git clone --depth=1 --branch "$POTIONS_REPO_BRANCH" "$POTIONS_REPO_URL" "$temp_repo" > /dev/null 2>&1; then
          log_error "Failed to clone repository"
          return 1
        fi
      fi
      
      # Move temp repo to final location
      log_info "Installing repository..."
      if ! mv "$temp_repo" "$POTIONS_REPO_DIR" 2>/dev/null; then
        log_error "Failed to move repository to final location"
        return 1
      fi
      
      repo_dir="$POTIONS_REPO_DIR"
      
      # Verify the repo was moved successfully
      if [ ! -d "$repo_dir" ] || [ ! -d "$repo_dir/.git" ]; then
        log_error "Repository verification failed"
        return 1
      fi
      
      log_success "Repository ready"
    else
      log_error "Git is not installed. Cannot upgrade without git."
      log_info "You can manually install git or re-run the installer:"
      echo "  curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/drink.sh | bash"
      exit 1
    fi
  fi
  
  # Verify repo_dir is set and valid before proceeding
  if [ -z "$repo_dir" ]; then
    log_error "Repository directory is not set"
    return 1
  fi
  
  if [ ! -d "$repo_dir" ] || [ ! -d "$repo_dir/.git" ]; then
    log_error "Repository directory is invalid: $repo_dir"
    return 1
  fi
  
  # Make install.sh executable
  if [ -f "$repo_dir/install.sh" ]; then
    chmod +x "$repo_dir/install.sh"
  fi
  
  echo "$repo_dir"
}

# Preserve user customizations
preserve_user_files() {
  log_info "Preserving user customizations..."
  
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
  log_step "Updating configuration files"
  
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
  # Note: Only files from .potions directory are copied - AI agent docs (AGENT.md, .cursorrules, etc.)
  # in repo root are git-only and never deployed to user installations
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
  
  # Update Potions CLI if available
  if [ -f "$repo_dir/.potions/bin/potions" ]; then
    log_info "Updating Potions CLI..."
    mkdir -p "$POTIONS_HOME/bin"
    cp "$repo_dir/.potions/bin/potions" "$POTIONS_HOME/bin/potions"
    chmod +x "$POTIONS_HOME/bin/potions"
    log_success "Potions CLI updated"
  fi
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
  print_header
  
  # Check if Potions is installed
  log_info "Checking installation..."
  check_potions_installed
  
  # Create backup
  create_backup
  
  # Prepare repository
  repo_dir=$(prepare_repository)
  local prepare_exit_code=$?
  
  if [ $prepare_exit_code -ne 0 ] || [ -z "$repo_dir" ] || [ ! -d "$repo_dir" ]; then
    log_error "Failed to prepare repository"
    log_info "Exit code: $prepare_exit_code"
    log_info "Repository directory: ${repo_dir:-'(empty)'}"
    exit 1
  fi
  
  # Verify checksums before proceeding
  if ! verify_checksums "$repo_dir"; then
    log_error "Checksum verification failed. Aborting upgrade for security."
    exit 1
  fi
  
  # Check if upgrade is needed
  if ! check_upgrade_needed "$repo_dir"; then
    echo ""
    if [ "$HAS_COLOR" = true ]; then
      echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${GREEN}${BOLD}  ✓ No upgrade needed - already up to date!${NC}"
      echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
    else
      echo "=========================================="
      echo "  No upgrade needed - already up to date!"
      echo "=========================================="
      echo ""
    fi
    exit 0
  fi
  
  # Update dotfiles
  update_dotfiles "$repo_dir"
  
  # Update version file
  if [ -f "$repo_dir/.version" ]; then
    cp "$repo_dir/.version" "$POTIONS_HOME/.version"
    log_success "Version updated"
  fi
  
  # Clean up old backups
  cleanup_old_backups
  
  # Success message
  echo ""
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}${BOLD}  ✓ Upgrade completed successfully!${NC}"
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log_info "Backup saved at: ${CYAN}${BACKUP_DIR#$HOME/~}${NC}"
    echo ""
    echo -e "${WHITE}Next steps:${NC}"
    echo -e "  ${CYAN}⟹${NC} Restart your terminal or run ${BOLD}exec zsh${NC}"
    echo -e "  ${CYAN}⟹${NC} Review .backup files in ${CYAN}~/.potions${NC} if needed"
    echo ""
    echo -e "${YELLOW}Tip:${NC} If something went wrong, restore from backup:"
    echo -e "  ${CYAN}cp -r ${BACKUP_DIR#$HOME/~}/* ~/.potions/${NC}"
    echo ""
  else
    echo "========================================"
    echo "  Upgrade completed successfully!"
    echo "========================================"
    echo ""
    echo "Backup saved at: ${BACKUP_DIR#$HOME/~}"
    echo ""
    echo "Next steps:"
    echo "  - Restart your terminal or run 'exec zsh'"
    echo "  - Review .backup files in ~/.potions if needed"
    echo ""
    echo "Tip: If something went wrong, restore from backup:"
    echo "  cp -r ${BACKUP_DIR#$HOME/~}/* ~/.potions/"
    echo ""
  fi
}

# Run main function
main "$@"
