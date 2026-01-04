#!/bin/bash

# Potions Registry Client
# Handles interaction with the potions-shelf GitHub registry

# Guard against multiple inclusion
if [ -n "$REGISTRY_SOURCED" ]; then
  return 0
fi
export REGISTRY_SOURCED=1

# Source core accessories if not already sourced
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$CORE_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

if [ -z "$ACCESSORIES_SOURCED" ]; then
  source "$REPO_ROOT/packages/accessories.sh"
fi

# Registry configuration
REGISTRY_BASE_URL="${REGISTRY_BASE_URL:-https://raw.githubusercontent.com/Rynaro/potions-shelf/main}"
REGISTRY_CACHE_DIR="${REGISTRY_CACHE_DIR:-${POTIONS_HOME}/.registry}"
REGISTRY_CACHE_TTL="${REGISTRY_CACHE_TTL:-86400}"  # 24 hours in seconds
REGISTRY_INDEX_FILE="${REGISTRY_CACHE_DIR}/index.json"
REGISTRY_MANIFESTS_DIR="${REGISTRY_CACHE_DIR}/manifests"
REGISTRY_TIMESTAMP_FILE="${REGISTRY_CACHE_DIR}/.timestamp"

# Ensure cache directory exists
ensure_registry_cache_dir() {
  ensure_directory "$REGISTRY_CACHE_DIR"
  ensure_directory "$REGISTRY_MANIFESTS_DIR"
}

# Check if cache is valid (not expired)
# Usage: is_cache_valid [cache_file]
is_cache_valid() {
  local cache_file="${1:-$REGISTRY_INDEX_FILE}"
  
  if [ ! -f "$cache_file" ]; then
    return 1
  fi
  
  if [ ! -f "$REGISTRY_TIMESTAMP_FILE" ]; then
    return 1
  fi
  
  local cache_age
  local current_time
  current_time=$(date +%s)
  cache_age=$(cat "$REGISTRY_TIMESTAMP_FILE" 2>/dev/null || echo "0")
  
  if [ -z "$cache_age" ] || [ "$cache_age" = "0" ]; then
    return 1
  fi
  
  local age=$((current_time - cache_age))
  
  if [ "$age" -lt "$REGISTRY_CACHE_TTL" ]; then
    return 0
  fi
  
  return 1
}

# Update cache timestamp
update_cache_timestamp() {
  ensure_registry_cache_dir
  date +%s > "$REGISTRY_TIMESTAMP_FILE"
}

# Download a file from registry
# Usage: registry_download <url> <output_file>
registry_download() {
  local url="$1"
  local output_file="$2"
  
  if [ -z "$url" ] || [ -z "$output_file" ]; then
    log "registry_download: missing arguments"
    return 1
  fi
  
  # Verify URL is from trusted domain
  if ! echo "$url" | grep -qE "^https://(raw\.)?githubusercontent\.com/Rynaro/potions-shelf/"; then
    log "registry_download: untrusted URL: $url"
    return 1
  fi
  
  ensure_directory "$(dirname "$output_file")"
  
  # Try curl first, then wget
  if command_exists curl; then
    if curl -fsSL --max-time 10 "$url" -o "$output_file" 2>/dev/null; then
      return 0
    fi
  elif command_exists wget; then
    if wget -q --timeout=10 -O "$output_file" "$url" 2>/dev/null; then
      return 0
    fi
  fi
  
  log "registry_download: failed to download $url"
  return 1
}

# Fetch registry index.json
# Usage: registry_fetch_index [--force]
registry_fetch_index() {
  local force="${1:-false}"
  
  ensure_registry_cache_dir
  
  # Check if we should use cache
  if [ "$force" != "--force" ] && is_cache_valid "$REGISTRY_INDEX_FILE"; then
    return 0
  fi
  
  local index_url="${REGISTRY_BASE_URL}/index.json"
  local temp_file
  temp_file=$(mktemp)
  
  log "Fetching registry index..."
  
  if registry_download "$index_url" "$temp_file"; then
    # Validate JSON (basic check)
    if grep -q "{" "$temp_file" && grep -q "}" "$temp_file"; then
      mv "$temp_file" "$REGISTRY_INDEX_FILE"
      update_cache_timestamp
      log "Registry index updated"
      return 0
    else
      log "Invalid index.json received"
      rm -f "$temp_file"
      return 1
    fi
  fi
  
  rm -f "$temp_file"
  
  # If download failed but cache exists, use cache
  if [ -f "$REGISTRY_INDEX_FILE" ]; then
    log "Using cached registry index (network unavailable)"
    return 0
  fi
  
  return 1
}

# Get plugin info from index.json
# Usage: registry_get_plugin_info <plugin_name>
registry_get_plugin_info() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    return 1
  fi
  
  # Ensure index is available
  if ! registry_fetch_index; then
    return 1
  fi
  
  if [ ! -f "$REGISTRY_INDEX_FILE" ]; then
    return 1
  fi
  
  # Parse JSON to find plugin (simple grep-based parser)
  # Look for plugin name in the JSON structure
  # Format: "name": "plugin-name" or "name":"plugin-name"
  if grep -q "\"name\"[[:space:]]*:[[:space:]]*\"${plugin_name}\"" "$REGISTRY_INDEX_FILE" 2>/dev/null; then
    # Extract the plugin entry (simplified - assumes one plugin per line or simple structure)
    # This is a basic implementation - could be improved with jq if available
    grep -A 20 "\"name\"[[:space:]]*:[[:space:]]*\"${plugin_name}\"" "$REGISTRY_INDEX_FILE" 2>/dev/null | head -30
    return 0
  fi
  
  return 1
}

# Fetch plugin manifest (.potion file)
# Usage: registry_fetch_manifest <plugin_name> [output_file]
registry_fetch_manifest() {
  local plugin_name="$1"
  local output_file="${2:-${REGISTRY_MANIFESTS_DIR}/${plugin_name}.potion}"
  
  if [ -z "$plugin_name" ]; then
    return 1
  fi
  
  ensure_registry_cache_dir
  
  # Check cache first
  if [ -f "$output_file" ] && is_cache_valid "$output_file"; then
    return 0
  fi
  
  local manifest_url="${REGISTRY_BASE_URL}/plugins/${plugin_name}.potion"
  local temp_file
  temp_file=$(mktemp)
  
  log "Fetching manifest for: $plugin_name"
  
  if registry_download "$manifest_url" "$temp_file"; then
    # Basic validation - check if it looks like YAML
    if [ -s "$temp_file" ] && head -1 "$temp_file" | grep -qE "^[a-zA-Z]|^#"; then
      mv "$temp_file" "$output_file"
      return 0
    else
      log "Invalid manifest received for: $plugin_name"
      rm -f "$temp_file"
      return 1
    fi
  fi
  
  rm -f "$temp_file"
  
  # If download failed but cache exists, use cache
  if [ -f "$output_file" ]; then
    log "Using cached manifest for: $plugin_name"
    return 0
  fi
  
  return 1
}

# Check if plugin is in registry
# Usage: registry_is_verified <plugin_name>
registry_is_verified() {
  local plugin_name="$1"
  
  if [ -z "$plugin_name" ]; then
    return 1
  fi
  
  # Try to get plugin info from index
  if registry_get_plugin_info "$plugin_name" > /dev/null 2>&1; then
    return 0
  fi
  
  return 1
}

# Search plugins in registry
# Usage: registry_search <query>
registry_search() {
  local query="$1"
  
  if [ -z "$query" ]; then
    # List all plugins
    if ! registry_fetch_index; then
      return 1
    fi
    
    if [ ! -f "$REGISTRY_INDEX_FILE" ]; then
      return 1
    fi
    
    # Extract plugin names from index.json
    # Simple grep-based extraction
    grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$REGISTRY_INDEX_FILE" 2>/dev/null | \
      sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | \
      sort
    return 0
  fi
  
  # Search for query in index
  if ! registry_fetch_index; then
    return 1
  fi
  
  if [ ! -f "$REGISTRY_INDEX_FILE" ]; then
    return 1
  fi
  
  # Search in name, description, tags, etc.
  grep -i "$query" "$REGISTRY_INDEX_FILE" 2>/dev/null | \
    grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | \
    sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | \
    sort -u
}

# Sync registry (update cache)
# Usage: registry_sync
registry_sync() {
  log "Syncing registry..."
  
  if registry_fetch_index --force; then
    log "Registry sync complete"
    return 0
  else
    log "Registry sync failed"
    return 1
  fi
}

# Get registry status
# Usage: registry_status
registry_status() {
  echo "Registry Status"
  echo "==============="
  echo ""
  echo "Base URL: $REGISTRY_BASE_URL"
  echo "Cache Dir: $REGISTRY_CACHE_DIR"
  echo "Cache TTL: $REGISTRY_CACHE_TTL seconds ($(($REGISTRY_CACHE_TTL / 3600)) hours)"
  echo ""
  
  if [ -f "$REGISTRY_INDEX_FILE" ]; then
    local cache_age
    local current_time
    current_time=$(date +%s)
    cache_age=$(cat "$REGISTRY_TIMESTAMP_FILE" 2>/dev/null || echo "0")
    
    if [ -n "$cache_age" ] && [ "$cache_age" != "0" ]; then
      local age=$((current_time - cache_age))
      local age_hours=$((age / 3600))
      local age_mins=$(((age % 3600) / 60))
      
      echo "Cache Status: Present"
      echo "Cache Age: ${age_hours}h ${age_mins}m"
      
      if is_cache_valid; then
        echo "Cache Valid: Yes"
      else
        echo "Cache Valid: No (expired)"
      fi
    else
      echo "Cache Status: Present (no timestamp)"
    fi
    
    # Count plugins in index
    local plugin_count
    plugin_count=$(grep -c '"name"' "$REGISTRY_INDEX_FILE" 2>/dev/null || echo "0")
    echo "Plugins in Index: $plugin_count"
  else
    echo "Cache Status: Not found"
  fi
  
  echo ""
  
  # Test connectivity
  echo "Testing connectivity..."
  if registry_fetch_index --force > /dev/null 2>&1; then
    echo "Connection: ✓ Online"
  else
    echo "Connection: ✗ Offline (using cache if available)"
  fi
}

