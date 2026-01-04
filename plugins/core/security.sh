#!/bin/bash

# Potions Plugin Security Module
# Handles plugin verification, registry checks, and security validation

# Guard against multiple inclusion
if [ -n "$SECURITY_SOURCED" ]; then
  return 0
fi
export SECURITY_SOURCED=1

# Source core accessories if not already sourced
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$CORE_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

if [ -z "$ACCESSORIES_SOURCED" ]; then
  source "$REPO_ROOT/packages/accessories.sh"
fi

# Source registry client if available
if [ -z "$REGISTRY_SOURCED" ]; then
  source "$CORE_DIR/registry.sh" 2>/dev/null || true
fi

# Registry file location (fallback for backward compatibility)
VERIFIED_REGISTRY="$PLUGINS_DIR/registry/verified.txt"

# Check if a path is a local plugin (filesystem path)
# Usage: is_local_plugin <plugin_spec>
is_local_plugin() {
  local plugin_spec="$1"
  
  # Local plugins start with /, ~, or ./
  case "$plugin_spec" in
    /* | ~* | ./*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Check if plugin is in verified registry
# Usage: is_verified_plugin <plugin_spec>
is_verified_plugin() {
  local plugin_spec="$1"
  
  # Try registry first (if available)
  if [ -n "$REGISTRY_SOURCED" ] && command -v registry_is_verified > /dev/null 2>&1; then
    # Extract plugin name from spec (handle owner/repo format)
    local plugin_name
    if echo "$plugin_spec" | grep -q "/"; then
      # It's owner/repo format - extract repo name
      plugin_name=$(basename "$plugin_spec")
    else
      plugin_name="$plugin_spec"
    fi
    
    if registry_is_verified "$plugin_name"; then
      return 0
    fi
    
    # Also try with full owner/repo format
    if registry_is_verified "$plugin_spec"; then
      return 0
    fi
  fi
  
  # Fallback to local verified.txt for backward compatibility
  if [ -f "$VERIFIED_REGISTRY" ]; then
    grep -q "^${plugin_spec}|" "$VERIFIED_REGISTRY" 2>/dev/null && return 0
  fi
  
  return 1
}

# Get verified plugin info from registry
# Usage: get_verified_plugin_info <plugin_spec>
get_verified_plugin_info() {
  local plugin_spec="$1"
  
  # Try registry first (if available)
  if [ -n "$REGISTRY_SOURCED" ] && command -v registry_get_plugin_info > /dev/null 2>&1; then
    local plugin_name
    if echo "$plugin_spec" | grep -q "/"; then
      plugin_name=$(basename "$plugin_spec")
    else
      plugin_name="$plugin_spec"
    fi
    
    local info
    info=$(registry_get_plugin_info "$plugin_name" 2>/dev/null)
    if [ -n "$info" ]; then
      echo "$info"
      return 0
    fi
    
    # Try with full spec
    info=$(registry_get_plugin_info "$plugin_spec" 2>/dev/null)
    if [ -n "$info" ]; then
      echo "$info"
      return 0
    fi
  fi
  
  # Fallback to local verified.txt
  if [ -f "$VERIFIED_REGISTRY" ]; then
    grep "^${plugin_spec}|" "$VERIFIED_REGISTRY" | head -1
    return 0
  fi
  
  return 1
}

# Get minimum version for verified plugin
# Usage: get_verified_min_version <plugin_spec>
get_verified_min_version() {
  local info
  info=$(get_verified_plugin_info "$1")
  
  if [ -z "$info" ]; then
    return 1
  fi
  
  echo "$info" | cut -d'|' -f2
}

# Get checksum URL for verified plugin
# Usage: get_verified_checksum_url <plugin_spec>
get_verified_checksum_url() {
  local info
  info=$(get_verified_plugin_info "$1")
  
  if [ -z "$info" ]; then
    return 1
  fi
  
  echo "$info" | cut -d'|' -f3
}

# Verify plugin signature/source
# Usage: verify_plugin_signature <plugin_spec>
verify_plugin_signature() {
  local plugin_spec="$1"
  
  # Local plugins bypass signature verification
  if is_local_plugin "$plugin_spec"; then
    log "Local plugin - skipping signature verification"
    return 0
  fi
  
  # Check if plugin is in verified registry (tries registry first, then local)
  if ! is_verified_plugin "$plugin_spec"; then
    log "Plugin '$plugin_spec' is not in the verified registry"
    log "Only verified plugins from the Potions registry can be installed remotely"
    log "For local plugins, use: local_plugin '/path/to/plugin'"
    log ""
    log "To submit a plugin to the registry, see:"
    log "  https://github.com/Rynaro/potions-shelf"
    return 1
  fi
  
  log "Plugin '$plugin_spec' is verified"
  return 0
}

# Calculate SHA256 checksum of a file
# Usage: calculate_checksum <file>
calculate_checksum() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    return 1
  fi
  
  if command_exists sha256sum; then
    sha256sum "$file" | cut -d' ' -f1
  elif command_exists shasum; then
    shasum -a 256 "$file" | cut -d' ' -f1
  else
    log "No SHA256 tool available"
    return 1
  fi
}

# Verify file checksum
# Usage: verify_file_checksum <file> <expected_checksum>
verify_file_checksum() {
  local file="$1"
  local expected="$2"
  
  local actual
  actual=$(calculate_checksum "$file")
  
  if [ "$actual" = "$expected" ]; then
    return 0
  fi
  
  log "Checksum mismatch for $file"
  log "Expected: $expected"
  log "Actual:   $actual"
  return 1
}

# Verify plugin checksums against expected values
# Usage: verify_plugin_checksums <plugin_path> <checksums_file>
verify_plugin_checksums() {
  local plugin_path="$1"
  local checksums_file="$2"
  
  if [ ! -f "$checksums_file" ]; then
    log "No checksums file provided"
    return 1
  fi
  
  local errors=0
  
  while IFS=':' read -r file expected_checksum; do
    [ -z "$file" ] && continue
    
    local full_path="$plugin_path/$file"
    
    if [ ! -f "$full_path" ]; then
      log "Missing file: $file"
      errors=$((errors + 1))
      continue
    fi
    
    if ! verify_file_checksum "$full_path" "$expected_checksum"; then
      errors=$((errors + 1))
    fi
  done < "$checksums_file"
  
  return $errors
}

# List all verified plugins
# Usage: list_verified_plugins
list_verified_plugins() {
  # Try registry first (if available)
  if [ -n "$REGISTRY_SOURCED" ] && command -v registry_search > /dev/null 2>&1; then
    echo "Verified Potions Plugins (from registry):"
    echo "========================================="
    echo ""
    
    local plugins
    plugins=$(registry_search "" 2>/dev/null)
    
    if [ -n "$plugins" ]; then
      for plugin in $plugins; do
        # Get more info from registry if possible
        local info
        info=$(registry_get_plugin_info "$plugin" 2>/dev/null | head -5)
        if [ -n "$info" ]; then
          # Extract description if available
          local desc
          desc=$(echo "$info" | grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/' | head -1)
          printf "  %-35s %s\n" "$plugin" "${desc:-No description}"
        else
          printf "  %-35s\n" "$plugin"
        fi
      done
      return 0
    fi
  fi
  
  # Fallback to local verified.txt
  if [ -f "$VERIFIED_REGISTRY" ]; then
    echo "Verified Potions Plugins (local):"
    echo "================================="
    echo ""
    
    while IFS='|' read -r repo version _ description; do
      # Skip comments and empty lines
      [[ "$repo" =~ ^# ]] && continue
      [ -z "$repo" ] && continue
      
      printf "  %-35s %-8s %s\n" "$repo" "v$version" "$description"
    done < "$VERIFIED_REGISTRY"
    return 0
  fi
  
  log "Verified registry not found"
  return 1
}

# Check if plugin comes from trusted source
# Usage: is_trusted_source <source_url>
is_trusted_source() {
  local source_url="$1"
  
  # Trusted sources are:
  # - Local paths
  # - GitHub repos from verified registry
  
  if is_local_plugin "$source_url"; then
    return 0
  fi
  
  # Check if it's a verified GitHub repo
  if echo "$source_url" | grep -qE '^(https://github\.com/|github:)'; then
    local repo
    repo=$(echo "$source_url" | sed -E 's#^(https://github\.com/|github:)##' | sed 's#\.git$##')
    
    if is_verified_plugin "$repo"; then
      return 0
    fi
  fi
  
  return 1
}

# Warn about local plugin installation
# Usage: warn_local_plugin <plugin_path>
warn_local_plugin() {
  local plugin_path="$1"
  
  echo ""
  echo "⚠️  WARNING: Installing local plugin"
  echo "   Path: $plugin_path"
  echo ""
  echo "   Local plugins are NOT verified by Potions Quality Assurance."
  echo "   Only install plugins from sources you trust."
  echo ""
}

# Display security status of a plugin
# Usage: display_plugin_security_status <plugin_spec>
display_plugin_security_status() {
  local plugin_spec="$1"
  
  echo "Security Status for: $plugin_spec"
  echo "=================================="
  
  if is_local_plugin "$plugin_spec"; then
    echo "Type: Local plugin"
    echo "Verification: Not verified (local plugins bypass verification)"
    echo "Status: ⚠️  Use at your own risk"
  elif is_verified_plugin "$plugin_spec"; then
    echo "Type: Remote plugin"
    echo "Verification: ✓ Verified by Potions Quality Assurance"
    echo "Status: ✓ Safe to install"
    
    local min_version checksum_url
    min_version=$(get_verified_min_version "$plugin_spec")
    checksum_url=$(get_verified_checksum_url "$plugin_spec")
    
    echo "Minimum Version: $min_version"
    [ -n "$checksum_url" ] && echo "Checksum URL: $checksum_url"
  else
    echo "Type: Remote plugin"
    echo "Verification: ✗ NOT in verified registry"
    echo "Status: ✗ REJECTED - Cannot be installed"
    echo ""
    echo "To use this plugin:"
    echo "  1. Submit a PR to add it to the verified registry, or"
    echo "  2. Clone it locally and use: local_plugin '/path/to/plugin'"
  fi
}
