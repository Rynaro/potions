#!/bin/bash

# Potions Plugin Scaffolding Script
# Creates a new plugin with the standardized structure

SCAFFOLD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCAFFOLD_DIR")"
TEMPLATES_DIR="$SCAFFOLD_DIR/templates"

source "$REPO_ROOT/packages/accessories.sh"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Get current user info for author field
get_author_name() {
  local author=""
  
  # Try git config
  if command_exists git; then
    author=$(git config --get user.name 2>/dev/null)
  fi
  
  # Fallback to system user
  if [ -z "$author" ]; then
    author="$USER"
  fi
  
  echo "$author"
}

# Create a new plugin scaffold
create_plugin() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    echo "Usage: create_plugin <plugin_name>"
    echo ""
    echo "Example: create_plugin my-awesome-plugin"
    exit 1
  fi
  
  # Sanitize plugin name (lowercase, hyphens only)
  plugin_name=$(echo "$plugin_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
  
  local plugin_dir="$SCAFFOLD_DIR/$plugin_name"
  
  # Check if plugin already exists
  if [ -d "$plugin_dir" ]; then
    log "Plugin already exists: $plugin_dir"
    echo "Remove it first or choose a different name."
    exit 1
  fi
  
  echo ""
  echo -e "${CYAN}${BOLD}Creating new Potions plugin: $plugin_name${NC}"
  echo ""
  
  # Create directory structure
  log "Creating directory structure..."
  mkdir -p "$plugin_dir/packages"
  mkdir -p "$plugin_dir/config"
  
  # Get author name
  local author
  author=$(get_author_name)
  
  # Create plugin.potions.json
  log "Creating plugin manifest..."
  cat > "$plugin_dir/plugin.potions.json" << EOF
{
  "name": "$plugin_name",
  "version": "0.0.1",
  "description": "A Potions plugin",
  "author": "$author",
  "license": "MIT",
  "potions_min_version": "2.6.0",
  "platforms": ["macos", "linux", "wsl", "termux"],
  "dependencies": [],
  "provides": {
    "nvim": [],
    "shell": [],
    "tmux": []
  },
  "hooks": {
    "post_install": "",
    "pre_uninstall": ""
  },
  "checksums": {}
}
EOF
  
  # Create install.sh
  log "Creating install.sh..."
  cat > "$plugin_dir/install.sh" << EOF
#!/bin/bash

# Plugin installation script for $plugin_name

PLUGIN_NAME="$plugin_name"
PLUGIN_VERSION="0.0.1"
PLUGIN_RELATIVE_FOLDER="\$(dirname "\$0")"

# Source utilities script
source "\$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to prepare for installation
prepare() {
  log "Preparing plugin installation: \$PLUGIN_NAME v\$PLUGIN_VERSION..."
  # Add any preparation steps (checking dependencies, etc.)
}

# Function to install packages/dependencies
install_packages() {
  log "Installing plugin: \$PLUGIN_NAME..."
  # Source package installation scripts if needed
  # safe_source "packages/main.sh"
}

# Function to configure the plugin
configure() {
  log "Configuring \$PLUGIN_NAME..."
  # Add configuration steps
  # Example: copy config files to appropriate locations
}

# Function for post-installation tasks
post_install() {
  log "Plugin \$PLUGIN_NAME v\$PLUGIN_VERSION installed successfully."
  # Add any post-installation steps
}

# Run installation pipeline
prepare
install_packages
configure
post_install
EOF
  chmod +x "$plugin_dir/install.sh"
  
  # Create uninstall.sh
  log "Creating uninstall.sh..."
  cat > "$plugin_dir/uninstall.sh" << EOF
#!/bin/bash

# Plugin uninstallation script for $plugin_name

PLUGIN_NAME="$plugin_name"
PLUGIN_RELATIVE_FOLDER="\$(dirname "\$0")"

# Source utilities script
source "\$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to prepare for uninstallation
prepare() {
  log "Preparing to uninstall plugin: \$PLUGIN_NAME..."
}

# Function to remove installed files
remove_files() {
  log "Removing plugin files..."
  # Add commands to remove installed files
  # Example: rm -f "\$POTIONS_HOME/nvim/lua/plugins/\$PLUGIN_NAME.lua"
}

# Function to cleanup configurations
cleanup_config() {
  log "Cleaning up configuration..."
  # Add commands to cleanup any configurations
  # Be careful not to remove user customizations
}

# Function for post-uninstallation tasks
post_uninstall() {
  log "Plugin \$PLUGIN_NAME has been uninstalled."
}

# Run uninstall pipeline
prepare
remove_files
cleanup_config
post_uninstall
EOF
  chmod +x "$plugin_dir/uninstall.sh"
  
  # Create activate.sh
  log "Creating activate.sh..."
  cat > "$plugin_dir/activate.sh" << EOF
#!/bin/bash

# Plugin activation script for $plugin_name

PLUGIN_NAME="$plugin_name"
PLUGIN_RELATIVE_FOLDER="\$(dirname "\$0")"

# Source utilities script
source "\$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to activate the plugin
activate() {
  log "Activating plugin: \$PLUGIN_NAME..."
  # Add activation commands here
}

# Function for post-activation tasks
post_activate() {
  log "Plugin \$PLUGIN_NAME has been activated."
  log "You may need to restart your shell for changes to take effect."
}

# Run activation pipeline
activate
post_activate
EOF
  chmod +x "$plugin_dir/activate.sh"
  
  # Create deactivate.sh
  log "Creating deactivate.sh..."
  cat > "$plugin_dir/deactivate.sh" << EOF
#!/bin/bash

# Plugin deactivation script for $plugin_name

PLUGIN_NAME="$plugin_name"
PLUGIN_RELATIVE_FOLDER="\$(dirname "\$0")"

# Source utilities script
source "\$PLUGIN_RELATIVE_FOLDER/utilities.sh"

# Function to deactivate the plugin
deactivate() {
  log "Deactivating plugin: \$PLUGIN_NAME..."
  # Add deactivation commands here
}

# Function for post-deactivation tasks
post_deactivate() {
  log "Plugin \$PLUGIN_NAME has been deactivated."
  log "Plugin files are preserved. Use 'activate' to re-enable."
}

# Run deactivation pipeline
deactivate
post_deactivate
EOF
  chmod +x "$plugin_dir/deactivate.sh"
  
  # Create utilities.sh
  log "Creating utilities.sh..."
  cat > "$plugin_dir/utilities.sh" << EOF
#!/bin/bash

# Plugin utilities for $plugin_name

UTILITIES_VERSION="2.0.0"
PLUGIN_RELATIVE_FOLDER="\$(dirname "\$0")"

# Environment
OS_TYPE="\$(uname -s)"
POTIONS_HOME="\${POTIONS_HOME:-\$HOME/.potions}"

# Logging
log() {
  echo "[\$(date '+%Y-%m-%d %H:%M:%S')] [$plugin_name] \$*"
}

# Function to safely source a script if it exists
safe_source() {
  local file="\$1"
  if [ -f "\$PLUGIN_RELATIVE_FOLDER/\$file" ]; then
    source "\$PLUGIN_RELATIVE_FOLDER/\$file"
  elif [ -f "\$file" ]; then
    source "\$file"
  fi
}

# Function to check if a command exists
command_exists() {
  command -v "\$1" &> /dev/null
}

# Platform detection functions
is_macos() {
  [ "\$OS_TYPE" = "Darwin" ]
}

is_linux() {
  [ "\$OS_TYPE" = "Linux" ]
}

is_termux() {
  [ -n "\$PREFIX" ] && [ -x "\$PREFIX/bin/termux-info" ]
}

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

# Cross-platform package installation helper
install_with_package_manager() {
  local package="\$1"
  
  if is_macos; then
    if command_exists brew; then
      brew install "\$package"
    fi
  elif is_termux; then
    pkg install -y "\$package"
  elif is_wsl || is_linux; then
    if command_exists apt-get; then
      sudo apt-get install -y "\$package"
    fi
  fi
}
EOF
  chmod +x "$plugin_dir/utilities.sh"
  
  # Create README.md
  log "Creating README.md..."
  cat > "$plugin_dir/README.md" << EOF
# $plugin_name

A Potions plugin.

## Description

Describe what this plugin does and why users would want it.

## Requirements

- Potions v2.6.0 or later

## Installation

### Via Potionfile (Recommended)

Add to your \`~/.potions/Potionfile\`:

\`\`\`bash
plugin '$plugin_name'
\`\`\`

Then run:

\`\`\`bash
potions plugin install
\`\`\`

### Manual Installation

\`\`\`bash
./plugins.sh install $plugin_name
\`\`\`

## Configuration

After installation, customize the plugin as needed.

## Usage

Describe how to use the plugin's features.

## Uninstallation

\`\`\`bash
potions plugin uninstall $plugin_name
\`\`\`

## License

MIT

## Author

$author
EOF
  
  # Create sample config file
  log "Creating sample config file..."
  cat > "$plugin_dir/config/init.zsh" << EOF
# $plugin_name shell configuration
# This file is sourced when the plugin is active

# Add your shell aliases, functions, and configurations here

# Example alias:
# alias my-command='echo "Hello from $plugin_name"'

# Example function:
# my_function() {
#   echo "This is a function from $plugin_name"
# }
EOF
  
  # Create sample package script
  log "Creating sample package script..."
  cat > "$plugin_dir/packages/main.sh" << EOF
#!/bin/bash

# Main package installation script for $plugin_name

source "\$(dirname "\$0")/../utilities.sh"

# Function to prepare package installation
prepare_package() {
  log "Preparing main package..."
}

# Function to install the package
install_package() {
  log "Installing main package..."
  # Add installation commands here
}

# Function to configure the package
configure_package() {
  log "Configuring main package..."
  # Add configuration commands here
}

# Run installation pipeline
prepare_package
install_package
configure_package
EOF
  chmod +x "$plugin_dir/packages/main.sh"
  
  echo ""
  echo -e "${GREEN}${BOLD}✓ Plugin created successfully!${NC}"
  echo ""
  echo -e "Plugin location: ${CYAN}$plugin_dir${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Edit the manifest: $plugin_dir/plugin.potions.json"
  echo "  2. Implement your plugin logic in install.sh"
  echo "  3. Add shell configurations in config/init.zsh"
  echo "  4. Update the README.md with documentation"
  echo ""
  echo "To test your plugin locally:"
  echo "  ./plugins.sh install $plugin_dir"
  echo ""
  echo "To validate your plugin:"
  echo "  ./plugins.sh validate $plugin_dir"
  echo ""
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_plugin "$@"
fi
