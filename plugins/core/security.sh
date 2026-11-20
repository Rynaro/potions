#!/bin/bash

# Potions Plugin Security Module
# Handles plugin verification, registry checks, and security validation

# Guard against multiple inclusion
if [ -n "$SECURITY_SOURCED" ] && declare -F is_verified_plugin >/dev/null; then
  return 0
fi
SECURITY_SOURCED=1

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
    /* | \~* | ./* | ../*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Check if exact owner/repository is in the maintainer allowlist
# Usage: is_verified_plugin <plugin_spec>
is_verified_plugin() {
  local plugin_spec="$1"
  
  if [ -f "$VERIFIED_REGISTRY" ] && awk -F'|' -v repo="$plugin_spec" '$1 == repo {found=1} END {exit !found}' "$VERIFIED_REGISTRY"; then
    return 0
  fi
  return 1
}

# Get verified plugin info from registry
# Usage: get_verified_plugin_info <plugin_spec>
get_verified_plugin_info() {
  local plugin_spec="$1"

  # Only the local owner/repository allowlist contains maintainer trust data.
  if [ -f "$VERIFIED_REGISTRY" ]; then
    awk -F'|' -v repo="$plugin_spec" '$1 == repo {print; exit}' "$VERIFIED_REGISTRY"
    return $?
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
  
  # Catalog presence is informational and never establishes repository trust.
  if ! is_verified_plugin "$plugin_spec"; then
    if command -v registry_has_plugin >/dev/null 2>&1 && registry_has_plugin "$plugin_spec"; then
      log "Plugin '$plugin_spec' is listed in the catalog, but that does not verify its code."
    else
      log "Plugin '$plugin_spec' is not in the Potions maintainer allowlist."
    fi
    log "Review the repository and approve its resolved commit during installation."
    return 1
  fi
  
  log "Plugin '$plugin_spec' matches the Potions maintainer allowlist."
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
    echo "Plugins in the Potions Shelf catalog:"
    echo "====================================="
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
    echo "  No plugins are currently listed."
    return 0
  fi
  
  # Fall back to the small maintainer-trusted repository list.
  if [ -f "$VERIFIED_REGISTRY" ]; then
    echo "Repositories in the Potions maintainer allowlist:"
    echo "==============================================="
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
  # - GitHub repositories in the maintainer allowlist
  
  if is_local_plugin "$source_url"; then
    return 0
  fi
  
  # Check if it's an allowlisted GitHub repository
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
  echo "   Local plugin code runs with your account permissions."
  echo "   Review its files before enabling it."
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
    echo "Catalog: Local source"
    echo "Trust: Review the local plugin code before installing."
  elif is_verified_plugin "$plugin_spec"; then
    echo "Type: Remote plugin"
    echo "Trust: Repository is listed in the Potions maintainer allowlist."
    
    local min_version
    min_version=$(get_verified_min_version "$plugin_spec")
    [ -z "$min_version" ] || echo "Minimum Potions Version: $min_version"
    echo "Review the resolved revision before trusting plugin code."
  elif command -v registry_has_plugin >/dev/null 2>&1 && registry_has_plugin "$plugin_spec"; then
    echo "Type: Remote plugin"
    echo "Catalog: Listed in Potions Shelf"
    echo "Trust: Catalog membership does not verify or endorse its code."
    echo "Review the repository and approve the resolved commit before installation."
  else
    echo "Type: Remote plugin"
    echo "Catalog: No entry found"
    echo "Trust: Direct GitHub installs require review and approval of the resolved commit."
  fi
}
