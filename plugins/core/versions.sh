#!/bin/bash

# Potions Plugin Version Management
# Handles semantic versioning comparison and compatibility checks

# Guard against multiple inclusion
if [ -n "$VERSIONS_SOURCED" ]; then
  return 0
fi
export VERSIONS_SOURCED=1

# Source core accessories if not already sourced
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$CORE_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

if [ -z "$ACCESSORIES_SOURCED" ]; then
  source "$REPO_ROOT/packages/accessories.sh"
fi

# Source manifest parser
source "$CORE_DIR/manifest.sh"

# Get current Potions version
# Usage: get_potions_version
get_current_potions_version() {
  local version_file=""
  
  # Try installed location first
  if [ -f "$POTIONS_HOME/.version" ]; then
    version_file="$POTIONS_HOME/.version"
  # Try repo root
  elif [ -f "$REPO_ROOT/.version" ]; then
    version_file="$REPO_ROOT/.version"
  fi
  
  if [ -n "$version_file" ] && [ -f "$version_file" ]; then
    cat "$version_file" | tr -d '[:space:]'
  else
    echo "0.0.0"
  fi
}

# Parse version string into components
# Usage: parse_version <version_string>
# Returns: major minor patch (space-separated)
parse_version() {
  local version="$1"
  
  # Remove 'v' prefix if present
  version="${version#v}"
  
  # Split on dots
  local major minor patch
  major=$(echo "$version" | cut -d. -f1)
  minor=$(echo "$version" | cut -d. -f2)
  patch=$(echo "$version" | cut -d. -f3)
  
  # Default to 0 if not present
  major="${major:-0}"
  minor="${minor:-0}"
  patch="${patch:-0}"
  
  # Remove any non-numeric characters (pre-release tags)
  major=$(echo "$major" | sed 's/[^0-9]//g')
  minor=$(echo "$minor" | sed 's/[^0-9]//g')
  patch=$(echo "$patch" | sed 's/[^0-9]//g')
  
  echo "$major $minor $patch"
}

# Compare two semantic versions
# Usage: compare_versions <version1> <version2>
# Returns: -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
compare_versions() {
  local v1="$1"
  local v2="$2"
  
  # Parse versions into components
  local v1_parts v2_parts
  read -r v1_major v1_minor v1_patch <<< "$(parse_version "$v1")"
  read -r v2_major v2_minor v2_patch <<< "$(parse_version "$v2")"
  
  # Compare major version
  if [ "$v1_major" -lt "$v2_major" ]; then
    echo "-1"
    return 0
  elif [ "$v1_major" -gt "$v2_major" ]; then
    echo "1"
    return 0
  fi
  
  # Compare minor version
  if [ "$v1_minor" -lt "$v2_minor" ]; then
    echo "-1"
    return 0
  elif [ "$v1_minor" -gt "$v2_minor" ]; then
    echo "1"
    return 0
  fi
  
  # Compare patch version
  if [ "$v1_patch" -lt "$v2_patch" ]; then
    echo "-1"
    return 0
  elif [ "$v1_patch" -gt "$v2_patch" ]; then
    echo "1"
    return 0
  fi
  
  # Versions are equal
  echo "0"
}

# Check if version1 is less than version2
# Usage: version_lt <version1> <version2>
version_lt() {
  local result
  result=$(compare_versions "$1" "$2")
  [ "$result" = "-1" ]
}

# Check if version1 is less than or equal to version2
# Usage: version_lte <version1> <version2>
version_lte() {
  local result
  result=$(compare_versions "$1" "$2")
  [ "$result" = "-1" ] || [ "$result" = "0" ]
}

# Check if version1 is greater than version2
# Usage: version_gt <version1> <version2>
version_gt() {
  local result
  result=$(compare_versions "$1" "$2")
  [ "$result" = "1" ]
}

# Check if version1 is greater than or equal to version2
# Usage: version_gte <version1> <version2>
version_gte() {
  local result
  result=$(compare_versions "$1" "$2")
  [ "$result" = "1" ] || [ "$result" = "0" ]
}

# Check if version1 equals version2
# Usage: version_eq <version1> <version2>
version_eq() {
  local result
  result=$(compare_versions "$1" "$2")
  [ "$result" = "0" ]
}

# Validate plugin is compatible with current Potions version
# Usage: validate_potions_compatibility <plugin_path>
validate_potions_compatibility() {
  local plugin_path="$1"
  
  local min_version
  min_version=$(get_potions_min_version "$plugin_path")
  
  if [ -z "$min_version" ]; then
    # No minimum version specified, assume compatible
    return 0
  fi
  
  local current_version
  current_version=$(get_current_potions_version)
  
  if version_gte "$current_version" "$min_version"; then
    return 0
  fi
  
  log "Plugin requires Potions v$min_version or later (current: v$current_version)"
  return 1
}

# Check for available plugin updates
# Usage: check_plugin_updates <plugin_path> <available_version>
check_plugin_updates() {
  local plugin_path="$1"
  local available_version="$2"
  
  local installed_version
  installed_version=$(get_plugin_version "$plugin_path")
  
  if [ -z "$installed_version" ]; then
    log "Could not determine installed version"
    return 1
  fi
  
  if version_lt "$installed_version" "$available_version"; then
    log "Update available: $installed_version -> $available_version"
    return 0
  fi
  
  log "Plugin is up to date (v$installed_version)"
  return 1
}

# Increment version (for development)
# Usage: increment_version <version> <part>
# part: major, minor, patch
increment_version() {
  local version="$1"
  local part="${2:-patch}"
  
  read -r major minor patch <<< "$(parse_version "$version")"
  
  case "$part" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
    *)
      log "Invalid version part: $part (use major, minor, or patch)"
      return 1
      ;;
  esac
  
  echo "$major.$minor.$patch"
}

# Validate version string format
# Usage: validate_version_format <version>
validate_version_format() {
  local version="$1"
  
  # Remove 'v' prefix if present
  version="${version#v}"
  
  # Check format: X.Y.Z where X, Y, Z are numbers
  if echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$'; then
    return 0
  fi
  
  log "Invalid version format: $version (expected: X.Y.Z)"
  return 1
}
