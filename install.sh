#!/bin/bash

# install.sh - Beautiful installer for Potions
# Author: Henrique A. Lavezzo (Rynaro)
#
# This script installs Potions with a beautiful, animated interface

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

# Source accessories.sh for utility functions
POTIONS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$POTIONS_ROOT/packages/accessories.sh"

# Get version from .version file
get_version() {
  local version_file=""
  # Try repo root first (if running from repo)
  if [ -f "$POTIONS_ROOT/.version" ]; then
    version_file="$POTIONS_ROOT/.version"
  # Try installed location
  elif [ -f "$POTIONS_HOME/.version" ]; then
    version_file="$POTIONS_HOME/.version"
  fi
  
  if [ -n "$version_file" ] && [ -f "$version_file" ]; then
    cat "$version_file" | tr -d '[:space:]'
  else
    echo ""
  fi
}

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
      echo -e "${CYAN}${BOLD}                 Installing Potions${NC}" >&2
      echo -e "${CYAN}              Your powerful dev environment${NC}" >&2
      echo -e "${CYAN}                         v${version}${NC}" >&2
    else
      echo -e "${CYAN}${BOLD}                 Installing Potions${NC}" >&2
      echo -e "${CYAN}              Your powerful dev environment${NC}" >&2
    fi
    echo "" >&2
  else
    echo "" >&2
    local version=$(get_version)
    echo "==========================================" >&2
    echo "         POTIONS INSTALLER" >&2
    if [ -n "$version" ]; then
      echo "                  v${version}" >&2
    fi
    echo "==========================================" >&2
    echo "" >&2
  fi
}

# Test mode detection (after logging functions are defined)
TEST_MODE=false
if [[ "$1" == "--test" ]] || [[ "$2" == "--test" ]]; then
  TEST_MODE=true
  TEST_DIR=$(mktemp -d)
  TEST_POTIONS_HOME="$TEST_DIR/.potions-test"
  log_warning "🧪 TEST MODE ENABLED - No changes will be made to your system"
  log_info "Test directory: $TEST_DIR"
  
  # Override POTIONS_HOME in test mode
  POTIONS_HOME="$TEST_POTIONS_HOME"
  mkdir -p "$POTIONS_HOME"
fi

update_potions() {
  local target_dir="$HOME"
  if [ "$TEST_MODE" = true ]; then
    target_dir="$TEST_DIR"
    log_info "[TEST] Copying Potions files to test directory..."
  else
    log_info "Copying Potions files to your home directory..."
  fi
  
  # Only copy .potions directory - excludes AI agent docs (AGENT.md, .cursorrules, etc.)
  # These files are git-only and should not be deployed to user installations
  if [ "$HAS_COLOR" = true ]; then
    if [ "$TEST_MODE" = true ]; then
      # Simulate with a delay to show spinner
      (sleep 0.5 && cp -r .potions "$target_dir/" 2>/dev/null) &
      spinner $! "Installing dotfiles"
    else
      (cp -r .potions "$target_dir/" 2>/dev/null) &
      spinner $! "Installing dotfiles"
    fi
  else
    if [ "$TEST_MODE" = true ]; then
      sleep 0.5
    fi
    cp -r .potions "$target_dir/" 2>/dev/null
  fi
  
  local check_dir="$target_dir/.potions"
  if [ "$TEST_MODE" = true ]; then
    check_dir="$TEST_POTIONS_HOME"
  fi
  
  if [ ! -d "$check_dir" ]; then
    log_error "Failed to copy Potions files"
    return 1
  fi
  
  # Copy version file if it exists
  if [ -f ".version" ]; then
    cp ".version" "$check_dir/.version" 2>/dev/null || true
  fi
  
  log_success "Potions files installed"
}

prepare_system() {
  if [ "$TEST_MODE" = true ]; then
    if is_macos; then
      log_info "[TEST] Setting up Homebrew..."
      # Simulate homebrew setup
      if [ "$HAS_COLOR" = true ]; then
        (sleep 1.2) &
        spinner $! "Setting up Homebrew"
      else
        sleep 1.2
      fi
      log_success "Homebrew ready"
    fi

    log_info "[TEST] Updating package repositories..."
    if [ "$HAS_COLOR" = true ]; then
      # Simulate repository update with delay
      (sleep 1.5) &
      spinner $! "Updating repositories"
    else
      sleep 1.5
    fi
    log_success "Repositories updated"
  else
    if is_macos; then
      log_info "Setting up Homebrew..."
      unpack_it 'macos/homebrew'
      log_success "Homebrew ready"
    fi

    log_info "Updating package repositories..."
    if [ "$HAS_COLOR" = true ]; then
      # Allow stderr through for sudo prompts and errors, only suppress stdout
      (update_repositories > /dev/null) &
      spinner $! "Updating repositories"
    else
      update_repositories
    fi
    log_success "Repositories updated"
  fi
  
  update_potions
}

preflight_checks() {
  log_step "Running pre-flight checks"

  # Check for required permissions
  if [ ! -w "$HOME" ]; then
    log_error "Cannot write to home directory"
    exit 1
  fi

  # Check for conflicting installations
  if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    log_warning "Existing .zshrc found - Potions uses ZDOTDIR instead"
  fi

  # Check for existing Potions installation
  if [ -d "$POTIONS_HOME" ]; then
    log_info "Existing Potions installation detected"
  fi

  # Check network connectivity for package downloads
  if command_exists curl; then
    if ! curl -s --connect-timeout 5 https://github.com > /dev/null 2>&1; then
      log_warning "Cannot reach github.com - some installations may fail"
    fi
  elif command_exists wget; then
    if ! wget -q --timeout=5 -O /dev/null https://github.com 2>&1; then
      log_warning "Cannot reach github.com - some installations may fail"
    fi
  fi

  log_success "Pre-flight checks passed"
}

install_packages() {
  # Package order is important:
  # 1. curl/wget - basic tools, no deps
  # 2. git - required for antidote, vim-plug
  # 3. zsh - required before antidote (needs ZDOTDIR)
  # 4. antidote - needs git
  # 5. tmux - no deps
  # 6. neovim - no deps but needed before vim-plug
  # 7. vim-plug - needs neovim and curl
  # 8. openvpn - optional, at end
  local packages=(
    'curl'
    'wget'
    'git'
    'zsh'
    'antidote'
    'tmux'
    'neovim'
    'vim-plug'
    'openvpn'
  )

  local installed_count=0
  local total_count=${#packages[@]}

  for pkg in "${packages[@]}"; do
    if [ "$TEST_MODE" = true ]; then
      log_info "[TEST] Installing $pkg ($((installed_count + 1))/$total_count)..."
    else
      log_info "Installing $pkg ($((installed_count + 1))/$total_count)..."
    fi
    
    if [ "$HAS_COLOR" = true ]; then
      if [ "$TEST_MODE" = true ]; then
        # Simulate installation with delay (0.8-1.5 seconds)
        # Use simple variation: 0.8 + (package_index % 7) * 0.1
        local delay_multiplier=$((installed_count % 7))
        local delay=$(LC_NUMERIC=C awk "BEGIN {printf \"%.1f\", 0.8 + $delay_multiplier * 0.1}")
        (sleep $delay) &
        spinner $! "Installing $pkg"
        log_success "$pkg installed"
        ((installed_count++))
      else
        # Allow stderr through for sudo prompts and errors, only suppress stdout
        (unpack_it "common/$pkg" > /dev/null) &
        if spinner $! "Installing $pkg"; then
          log_success "$pkg installed"
          ((installed_count++))
        else
          log_warning "$pkg installation may have encountered issues"
          ((installed_count++))
        fi
      fi
    else
      if [ "$TEST_MODE" = true ]; then
        # Simulate installation with delay
        local delay_multiplier=$((installed_count % 7))
        local delay=$(LC_NUMERIC=C awk "BEGIN {printf \"%.1f\", 0.8 + $delay_multiplier * 0.1}")
        sleep $delay
      else
        unpack_it "common/$pkg"
      fi
      log_success "$pkg installed"
      ((installed_count++))
    fi
  done
  
  log_success "All packages installed ($installed_count/$total_count)"
}

# Main installation flow
main() {
  print_header
  
  # Handle test mode cleanup
  if [ "$TEST_MODE" = true ]; then
    trap "echo ''; log_info 'Test directory preserved at: $TEST_DIR'; log_info 'To clean up manually: rm -rf $TEST_DIR'" EXIT
  fi
  
  if [[ "$1" == "--only-dotfiles" ]] && [ "$TEST_MODE" = false ]; then
    log_step "Updating Dotfiles Only"
    update_potions
    log_success "Dotfiles updated successfully!"
  elif [ "$TEST_MODE" = true ]; then
    log_step "TEST MODE - Simulating Installation"
    prepare_system
    
    log_step "Installing Packages"
    install_packages

    log_step "Finalizing Installation"
    
    # Create activation script in test directory
    POTIONS_SETUP="$TEST_POTIONS_HOME/activate.sh"
    log_info "[TEST] Creating activation script..."
    if [ "$HAS_COLOR" = true ]; then
      (sleep 0.3) &
      spinner $! "Creating activation script"
    else
      sleep 0.3
    fi
    cat > "$POTIONS_SETUP" << 'EOF'
#!/bin/bash
# Potions activation script (TEST MODE)
EOF
    chmod +x "$POTIONS_SETUP"
    log_success "Activation script created"

    # Success message
    echo ""
    if [ "$HAS_COLOR" = true ]; then
      echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${GREEN}${BOLD}  ✓ Test installation completed successfully!${NC}"
      echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo -e "${YELLOW}${BOLD}🧪 TEST MODE - No changes were made to your system${NC}"
      echo ""
      echo -e "${WHITE}Test directory:${NC} ${CYAN}$TEST_DIR${NC}"
      echo -e "${WHITE}Test installation:${NC} ${CYAN}$TEST_POTIONS_HOME${NC}"
      echo ""
      echo -e "${WHITE}To clean up test files:${NC}"
      echo -e "  ${CYAN}rm -rf $TEST_DIR${NC}"
      echo ""
    else
      echo "=========================================="
      echo "  Test installation completed successfully!"
      echo "=========================================="
      echo ""
      echo "TEST MODE - No changes were made to your system"
      echo ""
      echo "Test directory: $TEST_DIR"
      echo "Test installation: $TEST_POTIONS_HOME"
      echo ""
      echo "To clean up test files:"
      echo "  rm -rf $TEST_DIR"
      echo ""
    fi
  else
    preflight_checks

    log_step "Preparing System"
    prepare_system
    
    log_step "Installing Packages"
    install_packages

    log_step "Finalizing Installation"
    
    # Create a script that properly sets up the Potions environment
    POTIONS_SETUP="$POTIONS_HOME/activate.sh"
    log_info "Creating activation script..."
    if [ "$HAS_COLOR" = true ]; then
      (cat > "$POTIONS_SETUP" << 'EOF'
#!/bin/bash
# Potions activation script

# Set Zsh directory
export ZDOTDIR="$HOME/.potions"

# Display welcome message
echo "🧪 Potions has been installed successfully!"
echo "Your development environment is now ready."
echo ""
echo "This terminal session is still using your original shell."
echo "You can either:"
echo "  1. Close this terminal and open a new one (recommended)"
echo "  2. Type 'zsh' to switch to Zsh with Potions now"
echo ""
echo "All new terminal sessions will automatically use Potions."
EOF
      ) &
      spinner $! "Creating activation script"
    else
      cat > "$POTIONS_SETUP" << 'EOF'
#!/bin/bash
# Potions activation script

# Set Zsh directory
export ZDOTDIR="$HOME/.potions"

# Display welcome message
echo "🧪 Potions has been installed successfully!"
echo "Your development environment is now ready."
echo ""
echo "This terminal session is still using your original shell."
echo "You can either:"
echo "  1. Close this terminal and open a new one (recommended)"
echo "  2. Type 'zsh' to switch to Zsh with Potions now"
echo ""
echo "All new terminal sessions will automatically use Potions."
EOF
      fi

    chmod +x "$POTIONS_SETUP"
    log_success "Activation script created"

    # Install Potions CLI
    log_info "Installing Potions CLI..."
    POTIONS_BIN_DIR="$POTIONS_HOME/bin"
    mkdir -p "$POTIONS_BIN_DIR"
    
    # Copy CLI script from repo if available, otherwise create it
    if [ -f "$POTIONS_ROOT/.potions/bin/potions" ]; then
      cp "$POTIONS_ROOT/.potions/bin/potions" "$POTIONS_BIN_DIR/potions"
      chmod +x "$POTIONS_BIN_DIR/potions"
      log_success "Potions CLI installed"
    else
      log_warning "CLI script not found in repo, skipping CLI installation"
    fi

    # Success message
    echo ""
    if [ "$HAS_COLOR" = true ]; then
      echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${GREEN}${BOLD}  ✓ Installation completed successfully!${NC}"
      echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo -e "${WHITE}Next steps:${NC}"
      echo -e "  ${CYAN}⟹${NC} Close this terminal and open a new one (recommended)"
      echo -e "  ${CYAN}⟹${NC} Or type ${BOLD}exec zsh${NC} to start using Potions now"
      echo ""
      echo -e "${WHITE}CLI Commands:${NC}"
      echo -e "  ${CYAN}⟹${NC} Run ${BOLD}potions help${NC} to see available commands"
      echo -e "  ${CYAN}⟹${NC} Run ${BOLD}potions upgrade${NC} to upgrade Potions"
      echo -e "  ${CYAN}⟹${NC} Run ${BOLD}potions version${NC} to check version"
      echo ""
      echo -e "${YELLOW}Tip:${NC} All new terminal sessions will automatically use Potions!"
      echo ""
    else
      echo "=========================================="
      echo "  Installation completed successfully!"
      echo "=========================================="
      echo ""
      echo "Next steps:"
      echo "  - Close this terminal and open a new one (recommended)"
      echo "  - Or type 'exec zsh' to start using Potions now"
      echo ""
      echo "CLI Commands:"
      echo "  - Run 'potions help' to see available commands"
      echo "  - Run 'potions upgrade' to upgrade Potions"
      echo "  - Run 'potions version' to check version"
      echo ""
      echo "Tip: All new terminal sessions will automatically use Potions!"
      echo ""
    fi

    # Source the activation script for immediate information
    source "$POTIONS_SETUP"
  fi
}

# Run main function
main "$@"
