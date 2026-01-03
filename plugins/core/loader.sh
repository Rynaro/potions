#!/bin/bash

# Potions Plugin Loader
# Loads active plugins at shell startup and generates initialization scripts

# Guard against multiple inclusion
if [ -n "$LOADER_SOURCED" ]; then
  return 0
fi
export LOADER_SOURCED=1

# Source core accessories if not already sourced
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$CORE_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

if [ -z "$ACCESSORIES_SOURCED" ]; then
  source "$REPO_ROOT/packages/accessories.sh"
fi

# Plugin directories
INSTALLED_PLUGINS_DIR="${POTIONS_HOME}/plugins"
STATE_FILE="${INSTALLED_PLUGINS_DIR}/.state"
INIT_SCRIPT="${INSTALLED_PLUGINS_DIR}/.init.zsh"

# Get list of active plugins
# Usage: get_active_plugins
get_active_plugins() {
  if [ ! -f "$STATE_FILE" ]; then
    return 0
  fi
  
  grep ":active:" "$STATE_FILE" 2>/dev/null | cut -d: -f1
}

# Get list of all installed plugins
# Usage: get_installed_plugins
get_installed_plugins() {
  if [ ! -d "$INSTALLED_PLUGINS_DIR" ]; then
    return 0
  fi
  
  for plugin_dir in "$INSTALLED_PLUGINS_DIR"/*/; do
    [ -d "$plugin_dir" ] || continue
    local name
    name=$(basename "$plugin_dir")
    [[ "$name" == .* ]] && continue
    echo "$name"
  done
}

# Get plugin config directory
# Usage: get_plugin_config_dir <plugin_name>
get_plugin_config_dir() {
  local name="$1"
  local plugin_dir="$INSTALLED_PLUGINS_DIR/$name"
  
  if [ -L "$plugin_dir" ]; then
    plugin_dir=$(readlink "$plugin_dir")
  fi
  
  if [ -d "$plugin_dir/config" ]; then
    echo "$plugin_dir/config"
  fi
}

# Generate plugin initialization script
# This script is sourced by .zshrc to load active plugins
# Usage: generate_plugin_init
generate_plugin_init() {
  local init_file="$INIT_SCRIPT"
  
  ensure_directory "$(dirname "$init_file")"
  
  cat > "$init_file" << 'HEADER'
# Potions Plugin Initialization Script
# Auto-generated - DO NOT EDIT MANUALLY
# Regenerate with: potions plugin regenerate-init
#
# This script is sourced by .zshrc to load active plugins

POTIONS_PLUGINS_DIR="${POTIONS_HOME}/plugins"

# Helper to safely source plugin files
_potions_source_plugin() {
  local plugin_name="$1"
  local plugin_dir="$POTIONS_PLUGINS_DIR/$plugin_name"
  
  # Resolve symlinks for local plugins
  if [ -L "$plugin_dir" ]; then
    plugin_dir=$(readlink "$plugin_dir")
  fi
  
  if [ ! -d "$plugin_dir" ]; then
    return 1
  fi
  
  # Source shell configurations from config directory
  if [ -d "$plugin_dir/config" ]; then
    for config_file in "$plugin_dir/config"/*.zsh; do
      [ -f "$config_file" ] && source "$config_file"
    done
    for config_file in "$plugin_dir/config"/*.sh; do
      [ -f "$config_file" ] && source "$config_file"
    done
  fi
  
  return 0
}

HEADER

  # Add active plugins
  echo "# Active plugins" >> "$init_file"
  
  for plugin_name in $(get_active_plugins); do
    echo "_potions_source_plugin '$plugin_name'" >> "$init_file"
  done
  
  echo "" >> "$init_file"
  echo "# End of plugin initialization" >> "$init_file"
  
  log "Generated plugin init script: $init_file"
}

# Load active plugins (for sourcing in current shell)
# Usage: load_active_plugins
load_active_plugins() {
  for plugin_name in $(get_active_plugins); do
    local plugin_dir="$INSTALLED_PLUGINS_DIR/$plugin_name"
    
    # Resolve symlinks
    if [ -L "$plugin_dir" ]; then
      plugin_dir=$(readlink "$plugin_dir")
    fi
    
    if [ ! -d "$plugin_dir" ]; then
      continue
    fi
    
    # Source shell configurations
    if [ -d "$plugin_dir/config" ]; then
      for config_file in "$plugin_dir/config"/*.zsh "$plugin_dir/config"/*.sh; do
        [ -f "$config_file" ] && source "$config_file"
      done
    fi
  done
}

# Check if init script needs regeneration
# Usage: needs_init_regeneration
needs_init_regeneration() {
  if [ ! -f "$INIT_SCRIPT" ]; then
    return 0
  fi
  
  # Check if state file is newer than init script
  if [ -f "$STATE_FILE" ]; then
    if [ "$STATE_FILE" -nt "$INIT_SCRIPT" ]; then
      return 0
    fi
  fi
  
  return 1
}

# Auto-regenerate init script if needed
# Usage: auto_regenerate_init
auto_regenerate_init() {
  if needs_init_regeneration; then
    generate_plugin_init
  fi
}

# Get plugin shell aliases
# Usage: get_plugin_aliases <plugin_name>
get_plugin_aliases() {
  local plugin_name="$1"
  local plugin_dir="$INSTALLED_PLUGINS_DIR/$plugin_name"
  
  if [ -L "$plugin_dir" ]; then
    plugin_dir=$(readlink "$plugin_dir")
  fi
  
  local aliases_file="$plugin_dir/config/aliases.zsh"
  
  if [ -f "$aliases_file" ]; then
    cat "$aliases_file"
  fi
}

# Get plugin functions
# Usage: get_plugin_functions <plugin_name>
get_plugin_functions() {
  local plugin_name="$1"
  local plugin_dir="$INSTALLED_PLUGINS_DIR/$plugin_name"
  
  if [ -L "$plugin_dir" ]; then
    plugin_dir=$(readlink "$plugin_dir")
  fi
  
  local functions_file="$plugin_dir/config/functions.zsh"
  
  if [ -f "$functions_file" ]; then
    cat "$functions_file"
  fi
}

# Display loader status
# Usage: loader_status
loader_status() {
  echo ""
  echo "Plugin Loader Status"
  echo "===================="
  echo ""
  
  echo "Plugins Directory: $INSTALLED_PLUGINS_DIR"
  echo "State File: $STATE_FILE"
  echo "Init Script: $INIT_SCRIPT"
  echo ""
  
  local installed_count active_count
  installed_count=$(get_installed_plugins | wc -l | tr -d ' ')
  active_count=$(get_active_plugins | wc -l | tr -d ' ')
  
  echo "Installed Plugins: $installed_count"
  echo "Active Plugins: $active_count"
  echo ""
  
  if [ -f "$INIT_SCRIPT" ]; then
    echo "Init Script Status: ✓ Generated"
    echo "Last Modified: $(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$INIT_SCRIPT" 2>/dev/null || stat -c '%y' "$INIT_SCRIPT" 2>/dev/null | cut -d. -f1)"
  else
    echo "Init Script Status: ✗ Not generated"
    echo "Run 'potions plugin regenerate-init' to create it"
  fi
  echo ""
  
  if [ $active_count -gt 0 ]; then
    echo "Active Plugins:"
    for plugin in $(get_active_plugins); do
      echo "  ● $plugin"
    done
  fi
  echo ""
}

# Clean up orphaned state entries
# Usage: loader_cleanup
loader_cleanup() {
  if [ ! -f "$STATE_FILE" ]; then
    return 0
  fi
  
  local temp_file cleaned=0
  temp_file=$(mktemp)
  
  # Copy header
  grep "^#" "$STATE_FILE" > "$temp_file" 2>/dev/null || true
  
  # Only keep entries for installed plugins
  while IFS=: read -r name status version; do
    [[ "$name" =~ ^# ]] && continue
    [ -z "$name" ] && continue
    
    if [ -d "$INSTALLED_PLUGINS_DIR/$name" ] || [ -L "$INSTALLED_PLUGINS_DIR/$name" ]; then
      echo "${name}:${status}:${version}" >> "$temp_file"
    else
      cleaned=$((cleaned + 1))
    fi
  done < "$STATE_FILE"
  
  mv "$temp_file" "$STATE_FILE"
  
  if [ $cleaned -gt 0 ]; then
    log "Cleaned $cleaned orphaned state entries"
    generate_plugin_init
  fi
}
