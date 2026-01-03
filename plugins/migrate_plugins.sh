#!/bin/bash

# Potions Plugin Migration Script
# Migrates existing plugins to the new plugin system structure

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

source "$REPO_ROOT/packages/accessories.sh"
source "$SCRIPT_DIR/core/manifest.sh"
source "$SCRIPT_DIR/core/lockfile.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

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

# Detect old-style plugins
detect_old_plugins() {
  local plugins_dir="$SCRIPT_DIR"
  local old_plugins=()
  
  for plugin_dir in "$plugins_dir"/*/; do
    [ -d "$plugin_dir" ] || continue
    
    local plugin_name
    plugin_name=$(basename "$plugin_dir")
    
    # Skip system directories
    [[ "$plugin_name" == "core" ]] && continue
    [[ "$plugin_name" == "registry" ]] && continue
    [[ "$plugin_name" == "templates" ]] && continue
    [[ "$plugin_name" == "tests" ]] && continue
    
    # Check if old-style (has install.sh but no plugin.potions.json)
    if [ -f "$plugin_dir/install.sh" ] && [ ! -f "$plugin_dir/plugin.potions.json" ]; then
      old_plugins+=("$plugin_name")
    fi
  done
  
  printf '%s\n' "${old_plugins[@]}"
}

# Generate manifest for old-style plugin
generate_manifest() {
  local plugin_path="$1"
  local plugin_name
  plugin_name=$(basename "$plugin_path")
  
  # Try to extract version from install.sh
  local version="0.0.1"
  if [ -f "$plugin_path/install.sh" ]; then
    local found_version
    found_version=$(grep -oE 'PLUGIN_VERSION="?[0-9]+\.[0-9]+\.[0-9]+"?' "$plugin_path/install.sh" 2>/dev/null | \
                   sed 's/PLUGIN_VERSION=//;s/"//g' | head -1)
    [ -n "$found_version" ] && version="$found_version"
  fi
  
  # Try to detect what the plugin provides
  local provides_nvim="[]"
  local provides_shell="[]"
  
  # Check for nvim-related files
  if [ -d "$plugin_path/config" ]; then
    if ls "$plugin_path/config"/*.lua 2>/dev/null | grep -q .; then
      provides_nvim='["colorscheme"]'
    fi
    if ls "$plugin_path/config"/*.zsh 2>/dev/null | grep -q .; then
      provides_shell='["aliases", "functions"]'
    fi
  fi
  
  # Get author from git or fallback
  local author="Unknown"
  if command_exists git; then
    author=$(git config --get user.name 2>/dev/null || echo "Unknown")
  fi
  
  cat > "$plugin_path/plugin.potions.json" << EOF
{
  "name": "$plugin_name",
  "version": "$version",
  "description": "Migrated plugin",
  "author": "$author",
  "license": "MIT",
  "potions_min_version": "2.6.0",
  "platforms": ["macos", "linux", "wsl", "termux"],
  "dependencies": [],
  "provides": {
    "nvim": $provides_nvim,
    "shell": $provides_shell,
    "tmux": []
  },
  "hooks": {
    "post_install": "",
    "pre_uninstall": ""
  },
  "checksums": {}
}
EOF
  
  log_success "Generated manifest for: $plugin_name"
}

# Create missing required files
create_missing_files() {
  local plugin_path="$1"
  local plugin_name
  plugin_name=$(basename "$plugin_path")
  
  # Create uninstall.sh if missing
  if [ ! -f "$plugin_path/uninstall.sh" ]; then
    cat > "$plugin_path/uninstall.sh" << EOF
#!/bin/bash

# Plugin uninstallation script (auto-generated during migration)

PLUGIN_NAME="$plugin_name"
PLUGIN_RELATIVE_FOLDER="\$(dirname "\$0")"

[ -f "\$PLUGIN_RELATIVE_FOLDER/utilities.sh" ] && source "\$PLUGIN_RELATIVE_FOLDER/utilities.sh"

echo "Uninstalling plugin: \$PLUGIN_NAME"
echo "Note: You may need to manually remove any installed files"
EOF
    chmod +x "$plugin_path/uninstall.sh"
    log_success "Created uninstall.sh for: $plugin_name"
  fi
  
  # Create activate.sh if missing
  if [ ! -f "$plugin_path/activate.sh" ]; then
    cat > "$plugin_path/activate.sh" << EOF
#!/bin/bash

# Plugin activation script (auto-generated during migration)

PLUGIN_NAME="$plugin_name"
PLUGIN_RELATIVE_FOLDER="\$(dirname "\$0")"

[ -f "\$PLUGIN_RELATIVE_FOLDER/utilities.sh" ] && source "\$PLUGIN_RELATIVE_FOLDER/utilities.sh"

echo "Activating plugin: \$PLUGIN_NAME"
EOF
    chmod +x "$plugin_path/activate.sh"
    log_success "Created activate.sh for: $plugin_name"
  fi
  
  # Create deactivate.sh if missing
  if [ ! -f "$plugin_path/deactivate.sh" ]; then
    cat > "$plugin_path/deactivate.sh" << EOF
#!/bin/bash

# Plugin deactivation script (auto-generated during migration)

PLUGIN_NAME="$plugin_name"
PLUGIN_RELATIVE_FOLDER="\$(dirname "\$0")"

[ -f "\$PLUGIN_RELATIVE_FOLDER/utilities.sh" ] && source "\$PLUGIN_RELATIVE_FOLDER/utilities.sh"

echo "Deactivating plugin: \$PLUGIN_NAME"
EOF
    chmod +x "$plugin_path/deactivate.sh"
    log_success "Created deactivate.sh for: $plugin_name"
  fi
  
  # Create README.md if missing
  if [ ! -f "$plugin_path/README.md" ]; then
    cat > "$plugin_path/README.md" << EOF
# $plugin_name

A Potions plugin.

## Installation

\`\`\`bash
./plugins.sh install $plugin_name
\`\`\`

## Uninstallation

\`\`\`bash
potions plugin uninstall $plugin_name
\`\`\`
EOF
    log_success "Created README.md for: $plugin_name"
  fi
}

# Migrate plugins.txt to Potionfile
migrate_plugins_txt() {
  local plugins_txt="$POTIONS_HOME/plugins.txt"
  local potionfile="$POTIONS_HOME/Potionfile"
  
  if [ ! -f "$plugins_txt" ]; then
    return 0
  fi
  
  log_warning "Found legacy plugins.txt - migrating to Potionfile"
  
  # Create or append to Potionfile
  if [ ! -f "$potionfile" ]; then
    cp "$REPO_ROOT/.potions/Potionfile.template" "$potionfile" 2>/dev/null || \
    echo "# Potionfile - Potions Plugin Registry" > "$potionfile"
  fi
  
  echo "" >> "$potionfile"
  echo "# Migrated from plugins.txt on $(date '+%Y-%m-%d')" >> "$potionfile"
  
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    
    echo "plugin '$line'" >> "$potionfile"
    log_success "Migrated: $line"
  done < "$plugins_txt"
  
  # Rename old file
  mv "$plugins_txt" "$plugins_txt.migrated"
  log_success "Renamed plugins.txt to plugins.txt.migrated"
}

# Main migration function
migrate_plugins() {
  echo ""
  echo -e "${BOLD}Potions Plugin Migration${NC}"
  echo "========================="
  echo ""
  
  local dry_run=false
  if [ "$1" = "--dry-run" ]; then
    dry_run=true
    log_info "Dry run mode - no changes will be made"
    echo ""
  fi
  
  # Detect old-style plugins
  log_info "Scanning for old-style plugins..."
  local old_plugins
  old_plugins=$(detect_old_plugins)
  
  if [ -z "$old_plugins" ]; then
    log_success "No old-style plugins found"
  else
    echo ""
    log_warning "Found old-style plugins:"
    echo "$old_plugins" | while read -r plugin; do
      echo "  - $plugin"
    done
    echo ""
    
    if [ "$dry_run" = false ]; then
      echo "$old_plugins" | while read -r plugin; do
        local plugin_path="$SCRIPT_DIR/$plugin"
        
        log_info "Migrating: $plugin"
        
        # Generate manifest
        generate_manifest "$plugin_path"
        
        # Create missing files
        create_missing_files "$plugin_path"
        
        echo ""
      done
    fi
  fi
  
  # Migrate plugins.txt
  if [ "$dry_run" = false ]; then
    migrate_plugins_txt
  else
    if [ -f "$POTIONS_HOME/plugins.txt" ]; then
      log_warning "Would migrate plugins.txt to Potionfile"
    fi
  fi
  
  # Regenerate lockfile
  if [ "$dry_run" = false ]; then
    log_info "Regenerating lockfile..."
    lockfile_regenerate
  fi
  
  echo ""
  log_success "Migration complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Review the generated plugin.potions.json files"
  echo "  2. Update any plugin-specific configurations"
  echo "  3. Run './plugins.sh validate <plugin>' to verify each plugin"
  echo ""
}

# Show usage
usage() {
  cat << EOF
Potions Plugin Migration Script

Usage: $0 [options]

Options:
  --dry-run    Show what would be migrated without making changes
  --help       Show this help message

This script migrates old-style plugins to the new plugin system by:
  1. Generating plugin.potions.json manifests
  2. Creating missing required files (uninstall.sh, activate.sh, etc.)
  3. Migrating plugins.txt to Potionfile format
  4. Regenerating the lockfile

EOF
}

# Main
case "${1:-}" in
  --help|-h)
    usage
    ;;
  *)
    migrate_plugins "$@"
    ;;
esac
