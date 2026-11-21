#!/bin/bash

# Potions Plugin Engine
# Core plugin operations: install, uninstall, activate, deactivate, update, list

# Guard against multiple inclusion
if [ -n "$ENGINE_SOURCED" ] && declare -F plugin_install >/dev/null; then
  return 0
fi
ENGINE_SOURCED=1

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
  mkdir -p "$INSTALLED_PLUGINS_DIR"
}

# Plugin names are used in paths, state records and generated shell code.
valid_plugin_name() {
  [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]
}

# Returns name|source|ref_type|ref_value. Accepts GitHub URLs and legacy refs.
parse_plugin_spec() {
  local spec="$1" ref_type="" ref_value="" repo name
  spec=$(printf '%s' "$spec" | sed "s/^[[:space:]'\"]*//;s/[[:space:]'\"]*$//")
  if [[ "$spec" == *,* ]]; then
    local options="${spec#*,}"
    spec="${spec%%,*}"
    options=$(printf '%s' "$options" | sed "s/^[[:space:]]*//;s/['\"]//g")
    ref_type="${options%%:*}"
    ref_value=$(printf '%s' "${options#*:}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    case "$ref_type" in tag|branch) ;; *) return 1 ;; esac
  elif [[ "$spec" == *@* ]] && [[ "$spec" != git@* ]]; then
    ref_value="${spec##*@}"
    spec="${spec%@*}"
    ref_type=tag
  fi
  spec=$(printf '%s' "$spec" | sed 's/[[:space:]]*$//')
  repo="${spec#https://github.com/}"
  repo="${repo#github:}"
  repo="${repo%.git}"
  if [[ "$repo" == */* ]]; then
    [[ "$repo" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*/[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ ]] || return 1
    name="${repo##*/}"
    valid_plugin_name "$name" || return 1
    if [ -n "$ref_type" ]; then
      [ -n "$ref_value" ] && git check-ref-format "refs/tags/$ref_value" >/dev/null 2>&1 || return 1
      [[ "$ref_value" != *'|'* ]] || return 1
    fi
    printf '%s|github:%s|%s|%s\n' "$name" "$repo" "$ref_type" "$ref_value"
  else
    valid_plugin_name "$repo" || return 1
    [ -z "$ref_type" ] || return 1
    printf '%s|registry:%s||\n' "$repo" "$repo"
  fi
}

# Run hooks in their own process, with a stable plugin directory and environment.
plugin_run_hook() {
  local plugin_path="$1" hook="$2"
  [ -f "$plugin_path/$hook.sh" ] || return 0
  (cd "$plugin_path" && POTIONS_HOME="$POTIONS_HOME" bash -eo pipefail "$hook.sh")
}

# Installs are staged and checked before replacing an existing plugin.
plugin_install() (
  local plugin_spec="${1:-}" force=false skip_security=false trust=false
  [ -n "$plugin_spec" ] || return 1
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --force) force=true ;;
      --skip-security) skip_security=true ;;
      --trust) trust=true ;;
      *) log "Unknown install option: $1"; return 2 ;;
    esac
    shift
  done
  ensure_plugin_dirs
  local temp_dir target_dir="" backup="" replacement=false committed=false
  temp_dir=$(mktemp -d "$INSTALLED_PLUGINS_DIR/.install.XXXXXX") || return 1
  plugin_install_cleanup() {
    local result="$?"
    if [ "$replacement" = true ] && [ "$committed" != true ]; then
      rm -rf "$target_dir"
      [ -z "$backup" ] || mv "$backup/plugin" "$target_dir"
      if [ -f "$temp_dir/old.lock" ]; then cp "$temp_dir/old.lock" "$LOCKFILE_PATH"; else rm -f "$LOCKFILE_PATH"; fi
      if [ -f "$temp_dir/old.state" ]; then cp "$temp_dir/old.state" "$STATE_FILE"; else rm -f "$STATE_FILE"; fi
    fi
    rm -rf "$temp_dir"
    return "$result"
  }
  trap plugin_install_cleanup EXIT
  local parsed name source ref_type ref_value plugin_path version commit=none
  if is_local_plugin "$plugin_spec"; then
    plugin_spec="${plugin_spec/#\~/$HOME}"
    plugin_path=$(cd "$plugin_spec" && pwd -P) || return 1
    source="local:$plugin_path"
    [[ "$plugin_path" != *'|'* && "$plugin_path" != *$'\n'* ]] || return 1
    name=$(get_plugin_name "$plugin_path") || return 1
    valid_plugin_name "$name" || { log "Invalid plugin name: $name"; return 1; }
  else
    command_exists git || { log "Git is required to install GitHub plugins."; return 1; }
    parsed=$(parse_plugin_spec "$plugin_spec") || { log "Invalid plugin source: $plugin_spec"; return 1; }
    IFS='|' read -r name source ref_type ref_value <<< "$parsed"
    if [[ "$source" == registry:* ]]; then
      registry_fetch_manifest "${source#registry:}" "$temp_dir/manifest.potion" || return 1
      local repository
      repository=$(parse_potion_field "$temp_dir/manifest.potion" repository) || return 1
      parsed=$(parse_plugin_spec "$repository") || return 1
      IFS='|' read -r name source ref_type ref_value <<< "$parsed"
      [[ "$source" == github:* ]] || return 1
    fi
    name="${name#potions-}"
    local repo="${source#github:}"
    local requested_source="$source"
    [ -z "$ref_type" ] || requested_source="$source, $ref_type: $ref_value"
    if [ "$force" != true ] && [ -d "$INSTALLED_PLUGINS_DIR/$name" ] &&
       [ "$(lockfile_get_source "$name" 2>/dev/null || true)" = "$requested_source" ]; then
      log "Plugin already installed: $name"
      return 0
    fi
    local needs_trust=false
    is_verified_plugin "$repo" || needs_trust=true
    local git_args=(--depth=1)
    [ -z "$ref_value" ] || git_args+=(--branch "$ref_value")
    git -c core.hooksPath=/dev/null clone "${git_args[@]}" -- "https://github.com/$repo.git" "$temp_dir/plugin" || return 1
    plugin_path="$temp_dir/plugin"
    if [ -n "$ref_type" ]; then
      local namespace=tags
      [ "$ref_type" != branch ] || namespace=heads
      git -C "$plugin_path" fetch --depth=1 origin "refs/$namespace/$ref_value" || return 1
      git -C "$plugin_path" checkout --detach FETCH_HEAD || return 1
    fi
    commit=$(git -C "$plugin_path" rev-parse HEAD) || return 1
    if [ "$needs_trust" = true ] && [ "$trust" != true ]; then
      if [ -t 0 ] && [ -t 1 ]; then
        printf 'Repository https://github.com/%s\nRevision %s (%s)\nPlugin code runs with your account permissions. Trust this revision? [y/N] ' "$repo" "$commit" "${ref_value:-default branch}"
        local answer
        IFS= read -r answer || return 1
        case "$answer" in y|Y|yes) ;; *) return 1 ;; esac
      else
        log "Review https://github.com/$repo/commit/$commit then install with --trust to allow its code."
        return 1
      fi
    fi
    source="github:$repo"
    [ -z "$ref_type" ] || source="$source, $ref_type: $ref_value"
  fi
  validate_plugin "$plugin_path" || return 1
  validate_potions_compatibility "$plugin_path" || return 1
  if [ "$skip_security" != true ]; then
    quick_scan "$plugin_path" || return 1
  fi
  # Remote installations retain their historical repository-derived name.
  valid_plugin_name "$name" || return 1
  target_dir="$INSTALLED_PLUGINS_DIR/$name"
  local previous_state=""
  [ ! -f "$LOCKFILE_PATH" ] || cp "$LOCKFILE_PATH" "$temp_dir/old.lock" || return 1
  [ ! -f "$STATE_FILE" ] || cp "$STATE_FILE" "$temp_dir/old.state" || return 1
  if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
    if [ "$force" != true ]; then
      if [ "$(lockfile_get_source "$name" 2>/dev/null || true)" = "$source" ]; then
        log "Plugin already installed: $name"
        return 0
      fi
      log "Plugin name already installed: $name. Use --force to replace it."
      return 1
    fi
    previous_state=$(state_get "$name" 2>/dev/null | cut -d: -f2)
    ensure_directory "$INSTALLED_PLUGINS_DIR/.backups"
    backup=$(mktemp -d "$INSTALLED_PLUGINS_DIR/.backups/$name.XXXXXX") || return 1
    mv "$target_dir" "$backup/plugin" || return 1
  fi
  replacement=true
  if [[ "$source" == local:* ]]; then
    ln -s "$plugin_path" "$target_dir" || return 1
  else
    mv "$plugin_path" "$target_dir" || return 1
  fi
  if ! plugin_run_hook "$target_dir" install; then
    log "Plugin installation failed. Previous plugin and records preserved."
    return 1
  fi
  version=$(get_plugin_version "$target_dir") || return 1
  lockfile_add "$name" "$version" "$commit" "$source" || return 1
  state_set "$name" "${previous_state:-active}" "$version" || return 1
  committed=true
  log "Plugin installed: $name v$version"
  [ "$commit" = none ] || log "Git commit: $commit"
  [ -z "$backup" ] || log "Previous files backed up to $backup/plugin"
)

# Legacy API for callers that install a local checkout directly.
plugin_install_local() {
  local options=()
  [ "${2:-false}" != true ] || options+=(--force)
  [ "${3:-false}" != true ] || options+=(--skip-security)
  plugin_install "$1" "${options[@]}"
}

# Uninstall a plugin
# Usage: plugin_uninstall <plugin_name>
plugin_uninstall() (
  local name="${1:-}"
  valid_plugin_name "$name" || { log "Invalid plugin name: $name"; return 1; }
  local target_dir="$INSTALLED_PLUGINS_DIR/$name"
  if [ ! -d "$target_dir" ] && [ ! -L "$target_dir" ]; then
    log "Plugin not installed: $name"
    return 1
  fi
  plugin_run_hook "$target_dir" uninstall || return 1
  local temp_dir removed=false committed=false
  temp_dir=$(mktemp -d "$INSTALLED_PLUGINS_DIR/.uninstall.XXXXXX") || return 1
  [ ! -f "$LOCKFILE_PATH" ] || cp "$LOCKFILE_PATH" "$temp_dir/old.lock" || return 1
  [ ! -f "$STATE_FILE" ] || cp "$STATE_FILE" "$temp_dir/old.state" || return 1
  plugin_uninstall_cleanup() {
    local result="$?"
    if [ "$removed" = true ] && [ "$committed" != true ]; then
      mv "$temp_dir/plugin" "$target_dir"
      [ ! -f "$temp_dir/old.lock" ] || cp "$temp_dir/old.lock" "$LOCKFILE_PATH"
      [ ! -f "$temp_dir/old.state" ] || cp "$temp_dir/old.state" "$STATE_FILE"
    fi
    rm -rf "$temp_dir"
    return "$result"
  }
  trap plugin_uninstall_cleanup EXIT
  mv "$target_dir" "$temp_dir/plugin" || return 1
  removed=true
  if lockfile_has "$name"; then lockfile_remove "$name" || return 1; fi
  state_remove "$name" || return 1
  committed=true
  log "Plugin uninstalled: $name"
)

# Activate a plugin
# Usage: plugin_activate <plugin_name>
plugin_activate() {
  local name="$1"
  valid_plugin_name "$name" || { log "Invalid plugin name: $name"; return 1; }
  
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
    plugin_run_hook "$actual_path" activate || return 1
  fi
  
  # Update state
  local version
  version=$(state_get "$name" | cut -d: -f3)
  state_set "$name" "active" "$version" || return 1
  
  log "Plugin activated: $name"
  return 0
}

# Deactivate a plugin
# Usage: plugin_deactivate <plugin_name>
plugin_deactivate() {
  local name="$1"
  valid_plugin_name "$name" || { log "Invalid plugin name: $name"; return 1; }
  
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
    plugin_run_hook "$actual_path" deactivate || return 1
  fi
  
  # Update state
  local version
  version=$(state_get "$name" | cut -d: -f3)
  state_set "$name" "inactive" "$version" || return 1
  
  log "Plugin deactivated: $name"
  return 0
}

# Update a plugin
# Usage: plugin_update <plugin_name> [--all]
plugin_update() {
  local name="${1:---all}"
  shift || true
  if [ "$name" = --all ]; then
    local plugin_dir failed=0
    for plugin_dir in "$INSTALLED_PLUGINS_DIR"/*; do
      [ -d "$plugin_dir" ] || continue
      plugin_update "${plugin_dir##*/}" "$@" || failed=1
    done
    return "$failed"
  fi
  valid_plugin_name "$name" || return 1
  local target_dir="$INSTALLED_PLUGINS_DIR/$name" source
  [ -d "$target_dir" ] || { log "Plugin not installed: $name"; return 1; }
  if [ -L "$target_dir" ]; then
    log "Local plugin uses your working files: $name"
    return 0
  fi
  source=$(lockfile_get_source "$name") || return 1
  case "$source" in
    github:*) plugin_install "${source#github:}" --force "$@" ;;
    *) log "Cannot update plugin with unknown source: $name"; return 1 ;;
  esac
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
  
  for plugin_dir in "$INSTALLED_PLUGINS_DIR"/*; do
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
  list_verified_plugins | grep -iF -- "$query" || echo "No plugins found matching: $query"
}

# Show plugin info
# Usage: plugin_info <plugin_name>
plugin_info() {
  local name="$1"
  valid_plugin_name "$name" || { log "Invalid plugin name: $name"; return 1; }
  
  if [ -z "$name" ]; then
    log "Usage: plugin_info <plugin_name>"
    return 1
  fi
  
  local target_dir="$INSTALLED_PLUGINS_DIR/$name"
  
  if [ ! -d "$target_dir" ] && [ ! -L "$target_dir" ]; then
    # Check if it's in the registry
    if registry_has_plugin "$name" || is_verified_plugin "$name"; then
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
  awk -F: -v name="$name" '$1 == name {print; exit}' "$STATE_FILE"
}

state_set() {
  local name="$1"
  local status="$2"
  local version="$3"
  
  state_init
  state_remove "$name" 2>/dev/null || return 1
  echo "${name}:${status}:${version}" >> "$STATE_FILE"
}

state_remove() {
  local name="$1"
  
  if [ ! -f "$STATE_FILE" ]; then
    return 0
  fi
  
  local temp_file
  temp_file=$(mktemp)
  awk -F: -v name="$name" '$1 != name' "$STATE_FILE" > "$temp_file" || return 1
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
  
  local failed=0 line spec
  while IFS= read -r line || [ -n "$line" ]; do
    line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//')
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue
    case "$line" in
      plugin[[:space:]]*|local_plugin[[:space:]]*)
        spec=$(printf '%s' "$line" | sed -E 's/^(plugin|local_plugin)[[:space:]]+//')
        # Strip the declaration's wrapping quotes, preserving ref options.
        spec=$(printf '%s' "$spec" | sed "s/^[[:space:]'\"]*//;s/['\"][[:space:]]*,/,/;s/['\"][[:space:]]*$//")
        plugin_install "$spec" || failed=1
        ;;
      *) log "Invalid Potionfile declaration: $line"; failed=1 ;;
    esac
  done < "$potionfile"
  return "$failed"
}
