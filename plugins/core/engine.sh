#!/bin/bash

# Potions Plugin Engine
# Core plugin operations: install, uninstall, activate, deactivate, update, list

# Guard against multiple inclusion
if [ -n "$ENGINE_SOURCED" ]; then
  return 0
fi
export ENGINE_SOURCED=1

# Source core modules
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$CORE_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

if [ -z "$ACCESSORIES_SOURCED" ]; then
  source "$REPO_ROOT/packages/accessories.sh"
fi

source "$CORE_DIR/manifest.sh"
source "$CORE_DIR/versions.sh"
source "$CORE_DIR/lockfile.sh"
source "$CORE_DIR/security.sh"
source "$CORE_DIR/scanner.sh"

# Source registry client if available
if [ -z "$REGISTRY_SOURCED" ]; then
  source "$CORE_DIR/registry.sh" 2>/dev/null || true
fi

# Plugin directories
INSTALLED_PLUGINS_DIR="${POTIONS_HOME}/plugins"
STATE_FILE="${INSTALLED_PLUGINS_DIR}/.state"

# Ensure plugin directories exist
ensure_plugin_dirs() {
  ensure_directory "$INSTALLED_PLUGINS_DIR"
}

# Parse plugin specification
# Formats: 
#   plugin_name                    -> name only
#   owner/repo                     -> GitHub repo
#   owner/repo, tag: 'v1.0.0'     -> GitHub repo with tag
#   owner/repo, branch: 'main'    -> GitHub repo with branch
# Returns: name|source|ref_type|ref_value
parse_plugin_spec() {
  local spec="$1"
  
  # Remove quotes and extra whitespace
  spec=$(echo "$spec" | sed "s/['\"]//g" | xargs)
  
  # Check for options (tag: or branch:)
  local ref_type=""
  local ref_value=""
  
  if echo "$spec" | grep -q ", *tag:"; then
    ref_type="tag"
    ref_value=$(echo "$spec" | sed -E "s/.*tag:[[:space:]]*'?([^']*)'?.*/\1/")
    spec=$(echo "$spec" | sed -E "s/,[[:space:]]*tag:.*//" | xargs)
  elif echo "$spec" | grep -q ", *branch:"; then
    ref_type="branch"
    ref_value=$(echo "$spec" | sed -E "s/.*branch:[[:space:]]*'?([^']*)'?.*/\1/")
    spec=$(echo "$spec" | sed -E "s/,[[:space:]]*branch:.*//" | xargs)
  fi
  
  # Determine source type
  local name source
  if echo "$spec" | grep -q "/"; then
    # GitHub repo format: owner/repo
    source="github:$spec"
    name=$(basename "$spec" | sed 's/^potions-//')
  else
    # Simple name
    name="$spec"
    source="registry:$spec"
  fi
  
  echo "${name}|${source}|${ref_type}|${ref_value}"
}

# Install a plugin
# Usage: plugin_install <plugin_spec> [--force] [--skip-security]
plugin_install() {
  local plugin_spec="$1"
  local force=false
  local skip_security=false
  
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --force) force=true ;;
      --skip-security) skip_security=true ;;
    esac
    shift
  done
  
  ensure_plugin_dirs
  
  log "Installing plugin: $plugin_spec"
  
  # Check if it's a local plugin
  if is_local_plugin "$plugin_spec"; then
    plugin_install_local "$plugin_spec" "$force" "$skip_security"
    return $?
  fi
  
  # Remote plugin - verify it's in the registry
  if ! verify_plugin_signature "$plugin_spec"; then
    log "Installation aborted: Plugin not verified"
    return 1
  fi
  
  # Parse plugin specification
  local parsed name source ref_type ref_value
  parsed=$(parse_plugin_spec "$plugin_spec")
  IFS='|' read -r name source ref_type ref_value <<< "$parsed"
  
  local target_dir="$INSTALLED_PLUGINS_DIR/$name"
  
  # Check if already installed
  if [ -d "$target_dir" ] && [ "$force" != "true" ]; then
    log "Plugin already installed: $name"
    log "Use --force to reinstall"
    return 1
  fi
  
  # Download plugin
  log "Downloading plugin..."
  local temp_dir
  temp_dir=$(mktemp -d)
  trap "rm -rf $temp_dir" EXIT
  
  local repo_url
  if [[ "$source" == github:* ]]; then
    local repo="${source#github:}"
    repo_url="https://github.com/${repo}.git"
  elif [[ "$source" == registry:* ]]; then
    # Fetch manifest from registry to get repository info
    local registry_name="${source#registry:}"
    log "Fetching plugin manifest from registry: $registry_name"
    
    if [ -n "$REGISTRY_SOURCED" ] && command -v registry_fetch_manifest > /dev/null 2>&1; then
      local manifest_file="$temp_dir/manifest.potion"
      if registry_fetch_manifest "$registry_name" "$manifest_file"; then
        # Parse repository from manifest
        # Look for repository field in YAML
        local repo_field
        repo_field=$(grep -E "^[[:space:]]*repository[[:space:]]*:" "$manifest_file" 2>/dev/null | \
                     head -1 | \
                     sed -E "s/^[[:space:]]*repository[[:space:]]*:[[:space:]]*//" | \
                     sed -E "s/^[\"']//;s/[\"']$//" | \
                     sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [ -n "$repo_field" ]; then
          # Extract owner/repo from URL
          if echo "$repo_field" | grep -qE '^https://github\.com/'; then
            repo=$(echo "$repo_field" | sed 's|^https://github\.com/||' | sed 's|\.git$||')
            repo_url="https://github.com/${repo}.git"
          elif echo "$repo_field" | grep -qE '^git@github\.com:'; then
            repo=$(echo "$repo_field" | sed 's|^git@github\.com:||' | sed 's|\.git$||')
            repo_url="https://github.com/${repo}.git"
          elif echo "$repo_field" | grep -qE '/'; then
            # Assume it's already owner/repo format
            repo="$repo_field"
            repo_url="https://github.com/${repo}.git"
          else
            log "Invalid repository format in manifest: $repo_field"
            return 1
          fi
        else
          log "No repository field found in manifest"
          return 1
        fi
      else
        log "Failed to fetch manifest from registry"
        return 1
      fi
    else
      log "Registry client not available"
      return 1
    fi
  else
    log "Unknown source type: $source"
    return 1
  fi
  
  local git_args=("--depth=1")
  if [ -n "$ref_type" ] && [ -n "$ref_value" ]; then
    if [ "$ref_type" = "tag" ]; then
      git_args+=("--branch" "$ref_value")
    elif [ "$ref_type" = "branch" ]; then
      git_args+=("--branch" "$ref_value")
    fi
  fi
  
  if ! git clone "${git_args[@]}" "$repo_url" "$temp_dir/plugin" 2>/dev/null; then
    log "Failed to download plugin"
    return 1
  fi
  
  local plugin_path="$temp_dir/plugin"
  
  # Validate plugin
  if ! validate_plugin "$plugin_path"; then
    log "Plugin validation failed"
    return 1
  fi
  
  # Security scan (unless skipped)
  if [ "$skip_security" != "true" ]; then
    if ! quick_scan "$plugin_path"; then
      log "Security scan failed. Use --skip-security to bypass (not recommended)"
      return 1
    fi
  fi
  
  # Check Potions compatibility
  if ! validate_potions_compatibility "$plugin_path"; then
    log "Plugin not compatible with current Potions version"
    return 1
  fi
  
  # Remove old installation if exists
  if [ -d "$target_dir" ]; then
    rm -rf "$target_dir"
  fi
  
  # Copy plugin to installed directory
  cp -r "$plugin_path" "$target_dir"
  
  # Make scripts executable
  chmod +x "$target_dir"/*.sh 2>/dev/null || true
  chmod +x "$target_dir"/packages/*.sh 2>/dev/null || true
  
  # Run install script
  log "Running plugin installation..."
  if [ -f "$target_dir/install.sh" ]; then
    (cd "$target_dir" && bash install.sh)
  fi
  
  # Update lockfile
  local version
  version=$(get_plugin_version "$target_dir")
  lockfile_add "$name" "$version" "none" "$source"
  
  # Set initial state to active
  state_set "$name" "active" "$version"
  
  log "Plugin installed successfully: $name v$version"
  return 0
}

# Install a local plugin
# Usage: plugin_install_local <path> [force] [skip_security]
plugin_install_local() {
  local plugin_path="$1"
  local force="${2:-false}"
  local skip_security="${3:-false}"
  
  # Expand path
  plugin_path="${plugin_path/#\~/$HOME}"
  
  if [ ! -d "$plugin_path" ]; then
    log "Local plugin path not found: $plugin_path"
    return 1
  fi
  
  warn_local_plugin "$plugin_path"
  
  # Validate plugin structure
  if ! validate_plugin "$plugin_path"; then
    log "Plugin validation failed"
    return 1
  fi
  
  # Optional security scan
  if [ "$skip_security" != "true" ]; then
    log "Running security scan (optional for local plugins)..."
    quick_scan "$plugin_path" || log "Security warnings found - proceeding anyway for local plugin"
  fi
  
  local name
  name=$(get_plugin_name "$plugin_path")
  
  if [ -z "$name" ]; then
    name=$(basename "$plugin_path")
  fi
  
  local target_dir="$INSTALLED_PLUGINS_DIR/$name"
  
  # Check if already installed
  if [ -d "$target_dir" ] && [ "$force" != "true" ]; then
    log "Plugin already installed: $name"
    log "Use --force to reinstall"
    return 1
  fi
  
  # Create symlink to local plugin
  if [ -d "$target_dir" ] || [ -L "$target_dir" ]; then
    rm -rf "$target_dir"
  fi
  
  ln -s "$plugin_path" "$target_dir"
  
  # Run install script
  log "Running plugin installation..."
  if [ -f "$plugin_path/install.sh" ]; then
    (cd "$plugin_path" && bash install.sh)
  fi
  
  # Update lockfile
  lockfile_add "$name" "local" "none" "local:$plugin_path"
  
  # Set initial state to active
  state_set "$name" "active" "local"
  
  log "Local plugin installed: $name"
  return 0
}

# Uninstall a plugin
# Usage: plugin_uninstall <plugin_name>
plugin_uninstall() {
  local name="$1"
  
  if [ -z "$name" ]; then
    log "Usage: plugin_uninstall <plugin_name>"
    return 1
  fi
  
  local target_dir="$INSTALLED_PLUGINS_DIR/$name"
  
  if [ ! -d "$target_dir" ] && [ ! -L "$target_dir" ]; then
    log "Plugin not installed: $name"
    return 1
  fi
  
  log "Uninstalling plugin: $name"
  
  # Run uninstall script if exists
  local actual_path="$target_dir"
  if [ -L "$target_dir" ]; then
    actual_path=$(readlink "$target_dir")
  fi
  
  if [ -f "$actual_path/uninstall.sh" ]; then
    log "Running plugin uninstall script..."
    (cd "$actual_path" && bash uninstall.sh)
  fi
  
  # Remove plugin directory or symlink
  rm -rf "$target_dir"
  
  # Update lockfile
  lockfile_remove "$name"
  
  # Remove state
  state_remove "$name"
  
  log "Plugin uninstalled: $name"
  return 0
}

# Activate a plugin
# Usage: plugin_activate <plugin_name>
plugin_activate() {
  local name="$1"
  
  if [ -z "$name" ]; then
    log "Usage: plugin_activate <plugin_name>"
    return 1
  fi
  
  local target_dir="$INSTALLED_PLUGINS_DIR/$name"
  
  if [ ! -d "$target_dir" ] && [ ! -L "$target_dir" ]; then
    log "Plugin not installed: $name"
    return 1
  fi
  
  local current_state
  current_state=$(state_get "$name" | cut -d: -f2)
  
  if [ "$current_state" = "active" ]; then
    log "Plugin already active: $name"
    return 0
  fi
  
  log "Activating plugin: $name"
  
  # Run activate script if exists
  local actual_path="$target_dir"
  if [ -L "$target_dir" ]; then
    actual_path=$(readlink "$target_dir")
  fi
  
  if [ -f "$actual_path/activate.sh" ]; then
    (cd "$actual_path" && bash activate.sh)
  fi
  
  # Update state
  local version
  version=$(state_get "$name" | cut -d: -f3)
  state_set "$name" "active" "$version"
  
  log "Plugin activated: $name"
  return 0
}

# Deactivate a plugin
# Usage: plugin_deactivate <plugin_name>
plugin_deactivate() {
  local name="$1"
  
  if [ -z "$name" ]; then
    log "Usage: plugin_deactivate <plugin_name>"
    return 1
  fi
  
  local target_dir="$INSTALLED_PLUGINS_DIR/$name"
  
  if [ ! -d "$target_dir" ] && [ ! -L "$target_dir" ]; then
    log "Plugin not installed: $name"
    return 1
  fi
  
  local current_state
  current_state=$(state_get "$name" | cut -d: -f2)
  
  if [ "$current_state" = "inactive" ]; then
    log "Plugin already inactive: $name"
    return 0
  fi
  
  log "Deactivating plugin: $name"
  
  # Run deactivate script if exists
  local actual_path="$target_dir"
  if [ -L "$target_dir" ]; then
    actual_path=$(readlink "$target_dir")
  fi
  
  if [ -f "$actual_path/deactivate.sh" ]; then
    (cd "$actual_path" && bash deactivate.sh)
  fi
  
  # Update state
  local version
  version=$(state_get "$name" | cut -d: -f3)
  state_set "$name" "inactive" "$version"
  
  log "Plugin deactivated: $name"
  return 0
}

# Update a plugin
# Usage: plugin_update <plugin_name> [--all]
plugin_update() {
  local name="$1"
  
  if [ "$name" = "--all" ] || [ -z "$name" ]; then
    # Update all plugins
    log "Updating all plugins..."
    for plugin_dir in "$INSTALLED_PLUGINS_DIR"/*/; do
      [ -d "$plugin_dir" ] || continue
      local plugin_name
      plugin_name=$(basename "$plugin_dir")
      plugin_update "$plugin_name"
    done
    return 0
  fi
  
  local target_dir="$INSTALLED_PLUGINS_DIR/$name"
  
  if [ ! -d "$target_dir" ] && [ ! -L "$target_dir" ]; then
    log "Plugin not installed: $name"
    return 1
  fi
  
  # Check if local plugin
  if [ -L "$target_dir" ]; then
    log "Local plugin - update manually: $name"
    return 0
  fi
  
  log "Updating plugin: $name"
  
  # Get source from lockfile
  local source
  source=$(lockfile_get_source "$name")
  
  if [ -z "$source" ] || [ "$source" = "local" ]; then
    log "Cannot update: unknown source"
    return 1
  fi
  
  # Reinstall with force
  local plugin_spec
  if [[ "$source" == github:* ]]; then
    plugin_spec="${source#github:}"
  else
    plugin_spec="$name"
  fi
  
  plugin_install "$plugin_spec" --force
}

# List installed plugins
# Usage: plugin_list [--all|--active|--inactive]
plugin_list() {
  local filter="${1:---all}"
  
  ensure_plugin_dirs
  
  echo ""
  echo "Installed Plugins"
  echo "================="
  echo ""
  
  local count=0
  
  for plugin_dir in "$INSTALLED_PLUGINS_DIR"/*/; do
    [ -d "$plugin_dir" ] || continue
    
    local name
    name=$(basename "$plugin_dir")
    
    # Skip hidden directories
    [[ "$name" == .* ]] && continue
    
    local state_info version status
    state_info=$(state_get "$name")
    
    if [ -n "$state_info" ]; then
      status=$(echo "$state_info" | cut -d: -f2)
      version=$(echo "$state_info" | cut -d: -f3)
    else
      status="unknown"
      version=$(get_plugin_version "$plugin_dir" 2>/dev/null || echo "unknown")
    fi
    
    # Apply filter
    case "$filter" in
      --active)
        [ "$status" != "active" ] && continue
        ;;
      --inactive)
        [ "$status" != "inactive" ] && continue
        ;;
    esac
    
    local type_indicator=""
    if [ -L "$plugin_dir" ]; then
      type_indicator=" (local)"
    fi
    
    local status_indicator
    if [ "$status" = "active" ]; then
      status_indicator="●"
    else
      status_indicator="○"
    fi
    
    printf "  %s %-25s v%-10s %s%s\n" "$status_indicator" "$name" "$version" "$status" "$type_indicator"
    count=$((count + 1))
  done
  
  if [ $count -eq 0 ]; then
    echo "  No plugins installed"
  fi
  
  echo ""
  echo "Total: $count plugin(s)"
  echo ""
}

# Search available plugins
# Usage: plugin_search <query>
plugin_search() {
  local query="$1"
  
  # Try registry search first
  if [ -n "$REGISTRY_SOURCED" ] && command -v registry_search > /dev/null 2>&1; then
    local results
    results=$(registry_search "$query" 2>/dev/null)
    
    if [ -n "$results" ]; then
      echo ""
      echo "Search Results:"
      echo "==============="
      echo ""
      for plugin in $results; do
        printf "  %s\n" "$plugin"
      done
      echo ""
      return 0
    fi
  fi
  
  # Fallback to local registry
  list_verified_plugins | grep -i "$query" || echo "No plugins found matching: $query"
}

# Show plugin info
# Usage: plugin_info <plugin_name>
plugin_info() {
  local name="$1"
  
  if [ -z "$name" ]; then
    log "Usage: plugin_info <plugin_name>"
    return 1
  fi
  
  local target_dir="$INSTALLED_PLUGINS_DIR/$name"
  
  if [ ! -d "$target_dir" ] && [ ! -L "$target_dir" ]; then
    # Check if it's in the registry
    if is_verified_plugin "$name"; then
      echo "Plugin: $name (not installed)"
      echo ""
      
      # Try to get detailed info from registry
      if [ -n "$REGISTRY_SOURCED" ] && command -v registry_fetch_manifest > /dev/null 2>&1; then
        local temp_manifest
        temp_manifest=$(mktemp)
        if registry_fetch_manifest "$name" "$temp_manifest" 2>/dev/null; then
          # Display info from manifest (registry returns .potion YAML format)
          local version author description license repository
          if command -v parse_potion_field > /dev/null 2>&1; then
            version=$(parse_potion_field "$temp_manifest" "version" 2>/dev/null || echo "unknown")
            author=$(parse_potion_field "$temp_manifest" "author" 2>/dev/null || echo "unknown")
            description=$(parse_potion_field "$temp_manifest" "description" 2>/dev/null || echo "No description")
            license=$(parse_potion_field "$temp_manifest" "license" 2>/dev/null || echo "unknown")
            repository=$(parse_potion_field "$temp_manifest" "repository" 2>/dev/null || echo "")
          else
            # Fallback: try to extract with grep/sed
            version=$(grep -E "^[[:space:]]*version[[:space:]]*:" "$temp_manifest" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//' | sed "s/[\"']//g" || echo "unknown")
            author=$(grep -E "^[[:space:]]*author[[:space:]]*:" "$temp_manifest" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//' | sed "s/[\"']//g" || echo "unknown")
            description=$(grep -E "^[[:space:]]*description[[:space:]]*:" "$temp_manifest" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//' | sed "s/[\"']//g" || echo "No description")
            license=$(grep -E "^[[:space:]]*license[[:space:]]*:" "$temp_manifest" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//' | sed "s/[\"']//g" || echo "unknown")
            repository=$(grep -E "^[[:space:]]*repository[[:space:]]*:" "$temp_manifest" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//' | sed "s/[\"']//g" || echo "")
          fi
          
          echo "Version: $version"
          echo "Author: $author"
          echo "Description: $description"
          echo "License: $license"
          [ -n "$repository" ] && echo "Repository: $repository"
          echo ""
          rm -f "$temp_manifest"
        fi
      fi
      
      display_plugin_security_status "$name"
      return 0
    fi
    
    log "Plugin not found: $name"
    return 1
  fi
  
  local actual_path="$target_dir"
  if [ -L "$target_dir" ]; then
    actual_path=$(readlink "$target_dir")
  fi
  
  display_plugin_info "$actual_path"
  
  # Show state
  local state_info
  state_info=$(state_get "$name")
  if [ -n "$state_info" ]; then
    echo "Status: $(echo "$state_info" | cut -d: -f2)"
  fi
  
  # Show if local
  if [ -L "$target_dir" ]; then
    echo "Type: Local plugin"
    echo "Path: $actual_path"
  fi
}

# State management helpers
state_init() {
  ensure_plugin_dirs
  if [ ! -f "$STATE_FILE" ]; then
    echo "# Plugin State (auto-generated)" > "$STATE_FILE"
  fi
}

state_get() {
  local name="$1"
  state_init
  grep "^${name}:" "$STATE_FILE" 2>/dev/null | head -1
}

state_set() {
  local name="$1"
  local status="$2"
  local version="$3"
  
  state_init
  state_remove "$name" 2>/dev/null
  echo "${name}:${status}:${version}" >> "$STATE_FILE"
}

state_remove() {
  local name="$1"
  
  if [ ! -f "$STATE_FILE" ]; then
    return 0
  fi
  
  local temp_file
  temp_file=$(mktemp)
  grep -v "^${name}:" "$STATE_FILE" > "$temp_file" 2>/dev/null || true
  mv "$temp_file" "$STATE_FILE"
}

# Install plugins from Potionfile
# Usage: plugin_install_from_potionfile [potionfile_path]
plugin_install_from_potionfile() {
  local potionfile="${1:-$POTIONS_HOME/Potionfile}"
  
  if [ ! -f "$potionfile" ]; then
    log "Potionfile not found: $potionfile"
    return 1
  fi
  
  log "Installing plugins from Potionfile..."
  
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    
    # Parse plugin or local_plugin declarations
    if echo "$line" | grep -qE "^[[:space:]]*plugin[[:space:]]"; then
      local spec
      spec=$(echo "$line" | sed -E "s/^[[:space:]]*plugin[[:space:]]+['\"]?([^'\"]+)['\"]?.*/\1/")
      plugin_install "$spec"
    elif echo "$line" | grep -qE "^[[:space:]]*local_plugin[[:space:]]"; then
      local path
      path=$(echo "$line" | sed -E "s/^[[:space:]]*local_plugin[[:space:]]+['\"]?([^'\"]+)['\"]?.*/\1/")
      plugin_install "$path"
    fi
  done < "$potionfile"
  
  log "Potionfile installation complete"
}
