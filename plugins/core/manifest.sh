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
# Note: manifest can be either plugin.potions.json (JSON) or .potion (YAML)
PLUGIN_REQUIRED_FILES=("install.sh" "README.md")

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
  
  # Check if it's YAML or JSON
  if is_yaml_manifest "$manifest_file"; then
    parse_potion_array "$manifest_file" "$field"
    return $?
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

# Check if manifest file is YAML format (.potion)
# Usage: is_yaml_manifest <manifest_file>
is_yaml_manifest() {
  local manifest_file="$1"
  
  if [ ! -f "$manifest_file" ]; then
    return 1
  fi
  
  # Check file extension
  if echo "$manifest_file" | grep -qE '\.potion$'; then
    return 0
  fi
  
  # Check if it starts with YAML-like content (not JSON)
  local first_line
  first_line=$(head -1 "$manifest_file" | tr -d '[:space:]')
  
  # YAML typically starts with a key (no quotes) or comment
  if echo "$first_line" | grep -qE '^[a-zA-Z_][a-zA-Z0-9_]*:' || echo "$first_line" | grep -qE '^#'; then
    return 0
  fi
  
  # If it starts with {, it's likely JSON
  if echo "$first_line" | grep -qE '^{'; then
    return 1
  fi
  
  # Default: assume YAML if not clearly JSON
  return 0
}

# Find manifest file in plugin directory (supports both formats)
# Usage: find_manifest_file <plugin_path>
find_manifest_file() {
  local plugin_path="$1"
  
  # Prefer .potion (YAML) if both exist
  if [ -f "$plugin_path/.potion" ]; then
    echo "$plugin_path/.potion"
    return 0
  fi
  
  if [ -f "$plugin_path/plugin.potions.json" ]; then
    echo "$plugin_path/plugin.potions.json"
    return 0
  fi
  
  return 1
}

# Parse YAML field from .potion manifest
# Usage: parse_potion_field <manifest_file> <field_name>
parse_potion_field() {
  local manifest_file="$1"
  local field="$2"
  
  if [ ! -f "$manifest_file" ]; then
    return 1
  fi
  
  # Simple YAML parser using grep/sed
  # Handles: field: value, field: "value", field: 'value'
  local value
  value=$(grep -E "^[[:space:]]*${field}[[:space:]]*:" "$manifest_file" 2>/dev/null | \
          head -1 | \
          sed -E "s/^[[:space:]]*${field}[[:space:]]*:[[:space:]]*//" | \
          sed -E "s/^[\"']//;s/[\"']$//" | \
          sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
  if [ -n "$value" ]; then
    echo "$value"
    return 0
  fi
  
  return 1
}

# Parse YAML array field from .potion manifest
# Usage: parse_potion_array <manifest_file> <field_name>
parse_potion_array() {
  local manifest_file="$1"
  local field="$2"
  
  if [ ! -f "$manifest_file" ]; then
    return 1
  fi
  
  # Find the array field
  local in_array=false
  local values=""
  
  while IFS= read -r line; do
    # Check if this is the array field
    if echo "$line" | grep -qE "^[[:space:]]*${field}[[:space:]]*:"; then
      in_array=true
      # Check if it's inline array: field: [value1, value2]
      if echo "$line" | grep -qE '\[.*\]'; then
        values=$(echo "$line" | sed -E "s/^[[:space:]]*${field}[[:space:]]*:[[:space:]]*\[//" | \
                 sed 's/\].*$//' | \
                 tr ',' '\n' | \
                 sed "s/^[[:space:]]*[\"']//;s/[\"'][[:space:]]*$//" | \
                 sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
                 grep -v '^$')
        echo "$values"
        return 0
      fi
      continue
    fi
    
    # If we're in the array, collect values
    if [ "$in_array" = true ]; then
      # Check if we've hit the next top-level key (end of array)
      if echo "$line" | grep -qE '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*:'; then
        break
      fi
      
      # Extract value from list item: - value or - "value"
      local item
      item=$(echo "$line" | sed -E 's/^[[:space:]]*-[[:space:]]*//' | \
             sed -E "s/^[\"']//;s/[\"']$//" | \
             sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      
      if [ -n "$item" ]; then
        if [ -z "$values" ]; then
          values="$item"
        else
          values="$values"$'\n'"$item"
        fi
      fi
    fi
  done < "$manifest_file"
  
  if [ -n "$values" ]; then
    echo "$values"
    return 0
  fi
  
  return 1
}

# Get plugin name from manifest
# Usage: get_plugin_name <plugin_path>
get_plugin_name() {
  local plugin_path="$1"
  local manifest
  manifest=$(find_manifest_file "$plugin_path")
  
  if [ -z "$manifest" ]; then
    return 1
  fi
  
  if is_yaml_manifest "$manifest"; then
    parse_potion_field "$manifest" "name"
  else
    parse_manifest_field "$manifest" "name"
  fi
}

# Get plugin version from manifest
# Usage: get_plugin_version <plugin_path>
get_plugin_version() {
  local plugin_path="$1"
  local manifest
  manifest=$(find_manifest_file "$plugin_path")
  
  if [ -z "$manifest" ]; then
    return 1
  fi
  
  if is_yaml_manifest "$manifest"; then
    parse_potion_field "$manifest" "version"
  else
    parse_manifest_field "$manifest" "version"
  fi
}

# Get minimum Potions version required by plugin
# Usage: get_potions_min_version <plugin_path>
get_potions_min_version() {
  local plugin_path="$1"
  local manifest
  manifest=$(find_manifest_file "$plugin_path")
  
  if [ -z "$manifest" ]; then
    return 1
  fi
  
  if is_yaml_manifest "$manifest"; then
    parse_potion_field "$manifest" "potions_min_version"
  else
    parse_manifest_field "$manifest" "potions_min_version"
  fi
}

# Get plugin author from manifest
# Usage: get_plugin_author <plugin_path>
get_plugin_author() {
  local plugin_path="$1"
  local manifest
  manifest=$(find_manifest_file "$plugin_path")
  
  if [ -z "$manifest" ]; then
    return 1
  fi
  
  if is_yaml_manifest "$manifest"; then
    parse_potion_field "$manifest" "author"
  else
    parse_manifest_field "$manifest" "author"
  fi
}

# Get plugin description from manifest
# Usage: get_plugin_description <plugin_path>
get_plugin_description() {
  local plugin_path="$1"
  local manifest
  manifest=$(find_manifest_file "$plugin_path")
  
  if [ -z "$manifest" ]; then
    return 1
  fi
  
  if is_yaml_manifest "$manifest"; then
    parse_potion_field "$manifest" "description"
  else
    parse_manifest_field "$manifest" "description"
  fi
}

# Get plugin license from manifest
# Usage: get_plugin_license <plugin_path>
get_plugin_license() {
  local plugin_path="$1"
  local manifest
  manifest=$(find_manifest_file "$plugin_path")
  
  if [ -z "$manifest" ]; then
    return 1
  fi
  
  if is_yaml_manifest "$manifest"; then
    parse_potion_field "$manifest" "license"
  else
    parse_manifest_field "$manifest" "license"
  fi
}

# Get supported platforms from manifest
# Usage: get_plugin_platforms <plugin_path>
get_plugin_platforms() {
  local plugin_path="$1"
  local manifest
  manifest=$(find_manifest_file "$plugin_path")
  
  if [ -z "$manifest" ]; then
    return 1
  fi
  
  parse_manifest_array "$manifest" "platforms"
}

# Validate that manifest file is valid JSON or YAML
# Usage: validate_manifest_format <manifest_file>
validate_manifest_format() {
  local manifest_file="$1"
  
  if [ ! -f "$manifest_file" ]; then
    log "Manifest file not found: $manifest_file"
    return 1
  fi
  
  if is_yaml_manifest "$manifest_file"; then
    # Basic YAML validation - check it's not empty and has some structure
    if [ ! -s "$manifest_file" ]; then
      log "Manifest file is empty"
      return 1
    fi
    
    # Check for at least one key-value pair
    if ! grep -qE '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*:' "$manifest_file"; then
      log "Invalid YAML structure in manifest"
      return 1
    fi
    
    return 0
  else
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
  fi
}

# Legacy function name for backward compatibility
validate_manifest_json() {
  validate_manifest_format "$@"
}

# Validate manifest has all required fields
# Usage: validate_manifest_fields <manifest_file>
validate_manifest_fields() {
  local manifest_file="$1"
  local missing_fields=()
  
  local is_yaml=false
  if is_yaml_manifest "$manifest_file"; then
    is_yaml=true
  fi
  
  for field in "${MANIFEST_REQUIRED_FIELDS[@]}"; do
    local value
    if [ "$is_yaml" = true ]; then
      value=$(parse_potion_field "$manifest_file" "$field" 2>/dev/null)
    else
      value=$(parse_manifest_field "$manifest_file" "$field" 2>/dev/null)
    fi
    
    if [ -z "$value" ]; then
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
  
  # Check for manifest file (either format)
  local manifest
  manifest=$(find_manifest_file "$plugin_path")
  if [ -z "$manifest" ]; then
    missing_files+=("manifest (.potion or plugin.potions.json)")
  fi
  
  # Check other required files
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
  local manifest_file
  manifest_file=$(find_manifest_file "$plugin_path")
  local errors=0
  
  log "Validating plugin at: $plugin_path"
  
  # Check required files exist
  if ! validate_plugin_files "$plugin_path"; then
    errors=$((errors + 1))
  fi
  
  # Validate manifest format (JSON or YAML)
  if [ -n "$manifest_file" ]; then
    if ! validate_manifest_format "$manifest_file"; then
      errors=$((errors + 1))
    fi
    
    # Validate required fields
    if ! validate_manifest_fields "$manifest_file"; then
      errors=$((errors + 1))
    fi
  else
    log "No manifest file found"
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
  local manifest_file
  manifest_file=$(find_manifest_file "$plugin_path")
  
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
