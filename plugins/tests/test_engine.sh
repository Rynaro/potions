#!/bin/bash

# Potions Plugin Engine Tests
# Tests for the core plugin engine functionality

set -eo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$TESTS_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

source "$REPO_ROOT/packages/accessories.sh"
source "$PLUGINS_DIR/core/engine.sh"

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

# Tests

test_parse_plugin_spec_simple() {
  echo "Testing parse_plugin_spec with simple name..."
  
  local result
  result=$(parse_plugin_spec "my-plugin")
  
  local name source
  IFS='|' read -r name source _ _ <<< "$result"
  
  assert_equals "my-plugin" "$name" "Simple name parsed correctly"
  assert_equals "registry:my-plugin" "$source" "Simple source parsed correctly"
}

test_parse_plugin_spec_github() {
  echo "Testing parse_plugin_spec with GitHub repo..."
  
  local result
  result=$(parse_plugin_spec "Rynaro/potions-docker")
  
  local name source
  IFS='|' read -r name source _ _ <<< "$result"
  
  assert_equals "potions-docker" "$name" "GitHub name parsed correctly"
  assert_equals "github:Rynaro/potions-docker" "$source" "GitHub source parsed correctly"
}

test_parse_plugin_spec_with_tag() {
  echo "Testing parse_plugin_spec with tag..."
  
  local result
  result=$(parse_plugin_spec "Rynaro/potions-docker, tag: 'v1.0.0'")
  
  local name source ref_type ref_value
  IFS='|' read -r name source ref_type ref_value <<< "$result"
  
  assert_equals "potions-docker" "$name" "Name with tag parsed correctly"
  assert_equals "tag" "$ref_type" "Tag type parsed correctly"
  assert_equals "v1.0.0" "$ref_value" "Tag value parsed correctly"
}

test_parse_plugin_spec_with_branch() {
  echo "Testing parse_plugin_spec with branch..."
  
  local result
  result=$(parse_plugin_spec "Rynaro/potions-docker, branch: 'develop'")
  
  local name source ref_type ref_value
  IFS='|' read -r name source ref_type ref_value <<< "$result"
  
  assert_equals "potions-docker" "$name" "Name with branch parsed correctly"
  assert_equals "branch" "$ref_type" "Branch type parsed correctly"
  assert_equals "develop" "$ref_value" "Branch value parsed correctly"
}

test_state_management() {
  echo "Testing state management..."
  
  # Setup test state file
  local test_state_file
  test_state_file=$(mktemp)
  STATE_FILE="$test_state_file"
  
  # Test state_set (redirect log output)
  state_set "test-plugin" "active" "1.0.0" >/dev/null 2>&1
  assert_true "grep -q 'test-plugin:active:1.0.0' '$test_state_file'" "state_set works"
  
  # Test state_get (grep only the state line, ignoring logs)
  local state
  state=$(state_get "test-plugin" 2>/dev/null | grep "^test-plugin:")
  assert_equals "test-plugin:active:1.0.0" "$state" "state_get works"
  
  # Test state_remove
  state_remove "test-plugin" >/dev/null 2>&1
  assert_false "grep -q 'test-plugin' '$test_state_file'" "state_remove works"
  
  # Cleanup
  rm -f "$test_state_file"
}

test_ensure_plugin_dirs() {
  echo "Testing ensure_plugin_dirs..."
  
  # Save original
  local original_dir="$INSTALLED_PLUGINS_DIR"
  
  # Use temp directory
  local temp_dir
  temp_dir=$(mktemp -d)
  INSTALLED_PLUGINS_DIR="$temp_dir/plugins"
  
  ensure_plugin_dirs
  
  assert_true "[ -d '$INSTALLED_PLUGINS_DIR' ]" "Plugin directory created"
  
  # Cleanup
  rm -rf "$temp_dir"
  INSTALLED_PLUGINS_DIR="$original_dir"
}

# Run tests
run_tests() {
  echo ""
  echo "Running Plugin Engine Tests"
  echo "==========================="
  echo ""
  
  test_parse_plugin_spec_simple
  echo ""
  
  test_parse_plugin_spec_github
  echo ""
  
  test_parse_plugin_spec_with_tag
  echo ""
  
  test_parse_plugin_spec_with_branch
  echo ""
  
  test_state_management
  echo ""
  
  test_ensure_plugin_dirs
  echo ""
  
  # Summary
  echo "==========================="
  echo "Tests run: $TESTS_RUN"
  echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
  echo ""
  
  if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
  fi
}

run_tests
