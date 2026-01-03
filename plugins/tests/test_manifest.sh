#!/bin/bash

# Potions Plugin Manifest Tests
# Tests for manifest parsing and validation

set -eo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$TESTS_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

source "$REPO_ROOT/packages/accessories.sh"
source "$PLUGINS_DIR/core/manifest.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test helper functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [ "$expected" = "$actual" ]; then
    echo -e "${GREEN}✓${NC} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} $message"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_true() {
  local condition="$1"
  local message="$2"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if eval "$condition"; then
    echo -e "${GREEN}✓${NC} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} $message"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_false() {
  local condition="$1"
  local message="$2"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if ! eval "$condition"; then
    echo -e "${GREEN}✓${NC} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} $message"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Create test manifest
create_test_manifest() {
  local dir="$1"
  cat > "$dir/plugin.potions.json" << 'EOF'
{
  "name": "test-plugin",
  "version": "1.2.3",
  "description": "A test plugin",
  "author": "Test Author",
  "license": "MIT",
  "potions_min_version": "2.6.0",
  "platforms": ["macos", "linux", "wsl", "termux"],
  "dependencies": [],
  "provides": {
    "nvim": ["colorscheme"],
    "shell": ["aliases"],
    "tmux": []
  }
}
EOF
}

# Tests

test_parse_manifest_field() {
  echo "Testing parse_manifest_field..."
  
  local temp_dir
  temp_dir=$(mktemp -d)
  create_test_manifest "$temp_dir"
  
  local manifest="$temp_dir/plugin.potions.json"
  
  assert_equals "test-plugin" "$(parse_manifest_field "$manifest" "name")" "Parse name field"
  assert_equals "1.2.3" "$(parse_manifest_field "$manifest" "version")" "Parse version field"
  assert_equals "A test plugin" "$(parse_manifest_field "$manifest" "description")" "Parse description field"
  assert_equals "Test Author" "$(parse_manifest_field "$manifest" "author")" "Parse author field"
  assert_equals "MIT" "$(parse_manifest_field "$manifest" "license")" "Parse license field"
  assert_equals "2.6.0" "$(parse_manifest_field "$manifest" "potions_min_version")" "Parse potions_min_version field"
  
  # Cleanup
  rm -rf "$temp_dir"
}

test_get_plugin_info() {
  echo "Testing get_plugin_* functions..."
  
  local temp_dir
  temp_dir=$(mktemp -d)
  create_test_manifest "$temp_dir"
  
  assert_equals "test-plugin" "$(get_plugin_name "$temp_dir")" "get_plugin_name works"
  assert_equals "1.2.3" "$(get_plugin_version "$temp_dir")" "get_plugin_version works"
  assert_equals "Test Author" "$(get_plugin_author "$temp_dir")" "get_plugin_author works"
  assert_equals "A test plugin" "$(get_plugin_description "$temp_dir")" "get_plugin_description works"
  assert_equals "MIT" "$(get_plugin_license "$temp_dir")" "get_plugin_license works"
  assert_equals "2.6.0" "$(get_potions_min_version "$temp_dir")" "get_potions_min_version works"
  
  # Cleanup
  rm -rf "$temp_dir"
}

test_validate_manifest_json() {
  echo "Testing validate_manifest_json..."
  
  local temp_dir
  temp_dir=$(mktemp -d)
  
  # Valid JSON
  create_test_manifest "$temp_dir"
  assert_true "validate_manifest_json '$temp_dir/plugin.potions.json'" "Valid JSON passes"
  
  # Invalid JSON (missing closing brace)
  cat > "$temp_dir/invalid.json" << 'EOF'
{
  "name": "test"
EOF
  assert_false "validate_manifest_json '$temp_dir/invalid.json' 2>/dev/null" "Invalid JSON fails"
  
  # Cleanup
  rm -rf "$temp_dir"
}

test_validate_manifest_fields() {
  echo "Testing validate_manifest_fields..."
  
  local temp_dir
  temp_dir=$(mktemp -d)
  
  # Complete manifest
  create_test_manifest "$temp_dir"
  assert_true "validate_manifest_fields '$temp_dir/plugin.potions.json'" "Complete manifest passes"
  
  # Missing required field
  cat > "$temp_dir/incomplete.json" << 'EOF'
{
  "name": "test-plugin",
  "description": "Missing version and author"
}
EOF
  assert_false "validate_manifest_fields '$temp_dir/incomplete.json' 2>/dev/null" "Incomplete manifest fails"
  
  # Cleanup
  rm -rf "$temp_dir"
}

test_validate_plugin_files() {
  echo "Testing validate_plugin_files..."
  
  local temp_dir
  temp_dir=$(mktemp -d)
  mkdir -p "$temp_dir/plugin"
  
  # Complete plugin
  create_test_manifest "$temp_dir/plugin"
  cat > "$temp_dir/plugin/install.sh" << 'EOF'
#!/bin/bash
echo "Installing..."
EOF
  chmod +x "$temp_dir/plugin/install.sh"
  cat > "$temp_dir/plugin/README.md" << 'EOF'
# Test Plugin
EOF
  
  assert_true "validate_plugin_files '$temp_dir/plugin'" "Complete plugin passes"
  
  # Missing install.sh
  local incomplete_dir
  incomplete_dir=$(mktemp -d)
  mkdir -p "$incomplete_dir/plugin"
  create_test_manifest "$incomplete_dir/plugin"
  cat > "$incomplete_dir/plugin/README.md" << 'EOF'
# Test Plugin
EOF
  
  assert_false "validate_plugin_files '$incomplete_dir/plugin' 2>/dev/null" "Missing install.sh fails"
  
  # Cleanup
  rm -rf "$temp_dir" "$incomplete_dir"
}

test_parse_manifest_array() {
  echo "Testing parse_manifest_array..."
  
  local temp_dir
  temp_dir=$(mktemp -d)
  create_test_manifest "$temp_dir"
  
  local platforms
  platforms=$(parse_manifest_array "$temp_dir/plugin.potions.json" "platforms")
  
  assert_true "echo '$platforms' | grep -q 'macos'" "Platform macos found"
  assert_true "echo '$platforms' | grep -q 'linux'" "Platform linux found"
  
  # Cleanup
  rm -rf "$temp_dir"
}

test_validate_plugin() {
  echo "Testing full plugin validation..."
  
  local temp_dir
  temp_dir=$(mktemp -d)
  mkdir -p "$temp_dir/plugin"
  
  # Create complete valid plugin
  create_test_manifest "$temp_dir/plugin"
  cat > "$temp_dir/plugin/install.sh" << 'EOF'
#!/bin/bash
echo "Installing..."
EOF
  chmod +x "$temp_dir/plugin/install.sh"
  cat > "$temp_dir/plugin/README.md" << 'EOF'
# Test Plugin
A test plugin for validation.
EOF
  
  assert_true "validate_plugin '$temp_dir/plugin' >/dev/null 2>&1" "Complete plugin validates"
  
  # Cleanup
  rm -rf "$temp_dir"
}

# Run tests
run_tests() {
  echo ""
  echo "Running Plugin Manifest Tests"
  echo "=============================="
  echo ""
  
  test_parse_manifest_field
  echo ""
  
  test_get_plugin_info
  echo ""
  
  test_validate_manifest_json
  echo ""
  
  test_validate_manifest_fields
  echo ""
  
  test_validate_plugin_files
  echo ""
  
  test_parse_manifest_array
  echo ""
  
  test_validate_plugin
  echo ""
  
  # Summary
  echo "=============================="
  echo "Tests run: $TESTS_RUN"
  echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
  echo ""
  
  if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
  fi
}

run_tests
