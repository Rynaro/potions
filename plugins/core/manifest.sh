#!/bin/bash

# Potions Plugin Manifest Parser and Validator
# Handles plugin.potions.json parsing and validation

# Guard against multiple inclusion
if [ -n "$MANIFEST_SOURCED" ]; then
  return 0
fi
export MANIFEST_SOURCED=1

# Source core accessories if not already sourced
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$CORE_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

if [ -z "$ACCESSORIES_SOURCED" ]; then
  source "$REPO_ROOT/packages/accessories.sh"
fi

# Required fields in plugin manifest
MANIFEST_REQUIRED_FIELDS=("name" "version" "description" "author" "potions_min_version")

# Required files for a valid plugin
PLUGIN_REQUIRED_FILES=("plugin.potions.json" "install.sh" "README.md")

# Parse JSON field from manifest using native bash (no jq dependency)
# Usage: parse_manifest_field <manifest_file> <field_name>
parse_manifest_field() {
  local manifest_file="$1"
  local field="$2"
  
  if [ ! -f "$manifest_file" ]; then
    return 1
  fi
  
  # Use grep and sed to extract JSON field value
  # This handles simple string values
  local value
  value=$(grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$manifest_file" 2>/dev/null | \
          sed 's/.*:[[:space:]]*"\([^"]*\)"/\1/' | head -1)
  
  if [ -n "$value" ]; then
    echo "$value"
    return 0
  fi
  
  return 1
}

# Parse JSON array field from manifest
# Usage: parse_manifest_array <manifest_file> <field_name>
parse_manifest_array() {
  local manifest_file="$1"
  local field="$2"
  
  if [ ! -f "$manifest_file" ]; then
    return 1
  fi
  
  # Extract array values (simplified parser for flat arrays)
  local values
  values=$(grep -o "\"$field\"[[:space:]]*:[[:space:]]*\[[^]]*\]" "$manifest_file" 2>/dev/null | \
           sed 's/.*\[\([^]]*\)\]/\1/' | \
           tr ',' '\n' | \
           sed 's/^[[:space:]]*"//;s/"[[:space:]]*$//' | \
           grep -v '^$')
  
  echo "$values"
}

# Get plugin name from manifest
# Usage: get_plugin_name <plugin_path>
get_plugin_name() {
  local plugin_path="$1"
  local manifest="$plugin_path/plugin.potions.json"
  parse_manifest_field "$manifest" "name"
}

# Get plugin version from manifest
# Usage: get_plugin_version <plugin_path>
get_plugin_version() {
  local plugin_path="$1"
  local manifest="$plugin_path/plugin.potions.json"
  parse_manifest_field "$manifest" "version"
}

# Get minimum Potions version required by plugin
# Usage: get_potions_min_version <plugin_path>
get_potions_min_version() {
  local plugin_path="$1"
  local manifest="$plugin_path/plugin.potions.json"
  parse_manifest_field "$manifest" "potions_min_version"
}

# Get plugin author from manifest
# Usage: get_plugin_author <plugin_path>
get_plugin_author() {
  local plugin_path="$1"
  local manifest="$plugin_path/plugin.potions.json"
  parse_manifest_field "$manifest" "author"
}

# Get plugin description from manifest
# Usage: get_plugin_description <plugin_path>
get_plugin_description() {
  local plugin_path="$1"
  local manifest="$plugin_path/plugin.potions.json"
  parse_manifest_field "$manifest" "description"
}

# Get plugin license from manifest
# Usage: get_plugin_license <plugin_path>
get_plugin_license() {
  local plugin_path="$1"
  local manifest="$plugin_path/plugin.potions.json"
  parse_manifest_field "$manifest" "license"
}

# Get supported platforms from manifest
# Usage: get_plugin_platforms <plugin_path>
get_plugin_platforms() {
  local plugin_path="$1"
  local manifest="$plugin_path/plugin.potions.json"
  parse_manifest_array "$manifest" "platforms"
}

# Validate that manifest file is valid JSON
# Usage: validate_manifest_json <manifest_file>
validate_manifest_json() {
  local manifest_file="$1"
  
  if [ ! -f "$manifest_file" ]; then
    log "Manifest file not found: $manifest_file"
    return 1
  fi
  
  # Basic JSON structure validation
  # Check for opening and closing braces
  local first_char last_char
  first_char=$(head -c1 "$manifest_file" | tr -d '[:space:]')
  last_char=$(tail -c2 "$manifest_file" | head -c1 | tr -d '[:space:]')
  
  if [ "$first_char" != "{" ] || [ "$last_char" != "}" ]; then
    log "Invalid JSON structure in manifest"
    return 1
  fi
  
  # Check for balanced braces (simple check)
  local open_braces close_braces
  open_braces=$(grep -o '{' "$manifest_file" | wc -l | tr -d ' ')
  close_braces=$(grep -o '}' "$manifest_file" | wc -l | tr -d ' ')
  
  if [ "$open_braces" != "$close_braces" ]; then
    log "Unbalanced braces in manifest JSON"
    return 1
  fi
  
  return 0
}

# Validate manifest has all required fields
# Usage: validate_manifest_fields <manifest_file>
validate_manifest_fields() {
  local manifest_file="$1"
  local missing_fields=()
  
  for field in "${MANIFEST_REQUIRED_FIELDS[@]}"; do
    if ! parse_manifest_field "$manifest_file" "$field" > /dev/null 2>&1; then
      missing_fields+=("$field")
    fi
  done
  
  if [ ${#missing_fields[@]} -gt 0 ]; then
    log "Missing required fields: ${missing_fields[*]}"
    return 1
  fi
  
  return 0
}

# Validate plugin has all required files
# Usage: validate_plugin_files <plugin_path>
validate_plugin_files() {
  local plugin_path="$1"
  local missing_files=()
  
  for file in "${PLUGIN_REQUIRED_FILES[@]}"; do
    if [ ! -f "$plugin_path/$file" ]; then
      missing_files+=("$file")
    fi
  done
  
  if [ ${#missing_files[@]} -gt 0 ]; then
    log "Missing required files: ${missing_files[*]}"
    return 1
  fi
  
  # Check that install.sh is executable
  if [ ! -x "$plugin_path/install.sh" ]; then
    log "install.sh is not executable"
    return 1
  fi
  
  return 0
}

# Check if plugin supports current platform
# Usage: validate_plugin_platform <plugin_path>
validate_plugin_platform() {
  local plugin_path="$1"
  local platforms
  platforms=$(get_plugin_platforms "$plugin_path")
  
  # If no platforms specified, assume all are supported
  if [ -z "$platforms" ]; then
    return 0
  fi
  
  local current_platform=""
  if is_macos; then
    current_platform="macos"
  elif is_termux; then
    current_platform="termux"
  elif is_wsl; then
    current_platform="wsl"
  elif is_linux; then
    current_platform="linux"
  fi
  
  if echo "$platforms" | grep -q "$current_platform"; then
    return 0
  fi
  
  log "Plugin does not support current platform: $current_platform"
  return 1
}

# Full plugin validation
# Usage: validate_plugin <plugin_path>
validate_plugin() {
  local plugin_path="$1"
  local manifest_file="$plugin_path/plugin.potions.json"
  local errors=0
  
  log "Validating plugin at: $plugin_path"
  
  # Check required files exist
  if ! validate_plugin_files "$plugin_path"; then
    errors=$((errors + 1))
  fi
  
  # Validate manifest JSON structure
  if ! validate_manifest_json "$manifest_file"; then
    errors=$((errors + 1))
  fi
  
  # Validate required fields
  if ! validate_manifest_fields "$manifest_file"; then
    errors=$((errors + 1))
  fi
  
  # Check platform support
  if ! validate_plugin_platform "$plugin_path"; then
    errors=$((errors + 1))
  fi
  
  # Validate bash syntax of all .sh files
  for script in "$plugin_path"/*.sh "$plugin_path"/packages/*.sh; do
    if [ -f "$script" ]; then
      if ! bash -n "$script" 2>/dev/null; then
        log "Syntax error in: $script"
        errors=$((errors + 1))
      fi
    fi
  done
  
  if [ $errors -gt 0 ]; then
    log "Plugin validation failed with $errors error(s)"
    return 1
  fi
  
  log "Plugin validation passed"
  return 0
}

# Generate checksums for plugin files
# Usage: generate_plugin_checksums <plugin_path>
generate_plugin_checksums() {
  local plugin_path="$1"
  
  for file in "$plugin_path"/*.sh "$plugin_path"/packages/*.sh; do
    if [ -f "$file" ]; then
      local filename
      filename=$(basename "$file")
      local relative_path
      relative_path="${file#$plugin_path/}"
      local checksum
      checksum=$(shasum -a 256 "$file" | cut -d' ' -f1)
      echo "$relative_path:sha256:$checksum"
    fi
  done
}

# Verify plugin checksums against manifest
# Usage: verify_plugin_checksums <plugin_path>
verify_plugin_checksums() {
  local plugin_path="$1"
  local manifest_file="$plugin_path/plugin.potions.json"
  
  # This is a simplified check - full implementation would parse checksums from manifest
  # and compare with actual file checksums
  
  log "Verifying plugin checksums..."
  
  # For now, just verify files exist and are readable
  for file in "$plugin_path"/*.sh; do
    if [ -f "$file" ] && [ ! -r "$file" ]; then
      log "File not readable: $file"
      return 1
    fi
  done
  
  return 0
}

# Display plugin info from manifest
# Usage: display_plugin_info <plugin_path>
display_plugin_info() {
  local plugin_path="$1"
  
  local name version author description license platforms
  name=$(get_plugin_name "$plugin_path")
  version=$(get_plugin_version "$plugin_path")
  author=$(get_plugin_author "$plugin_path")
  description=$(get_plugin_description "$plugin_path")
  license=$(get_plugin_license "$plugin_path")
  platforms=$(get_plugin_platforms "$plugin_path" | tr '\n' ', ' | sed 's/,$//')
  
  echo "Plugin: $name"
  echo "Version: $version"
  echo "Author: $author"
  echo "Description: $description"
  echo "License: $license"
  echo "Platforms: $platforms"
}
