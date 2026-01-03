#!/bin/bash

# Potions Plugin Security Scanner
# Scans plugin scripts for dangerous patterns and security issues

# Guard against multiple inclusion
if [ -n "$SCANNER_SOURCED" ]; then
  return 0
fi
export SCANNER_SOURCED=1

# Source core accessories if not already sourced
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$(dirname "$CORE_DIR")"
REPO_ROOT="$(dirname "$PLUGINS_DIR")"

if [ -z "$ACCESSORIES_SOURCED" ]; then
  source "$REPO_ROOT/packages/accessories.sh"
fi

# Dangerous patterns to check for
# Format: "pattern|severity|description"
DANGEROUS_PATTERNS=(
  'curl.*\|.*bash|high|Remote code execution via curl pipe to bash'
  'wget.*\|.*bash|high|Remote code execution via wget pipe to bash'
  'curl.*\|.*sh|high|Remote code execution via curl pipe to shell'
  'wget.*\|.*sh|high|Remote code execution via wget pipe to shell'
  'eval.*\$|high|Eval with variable input - potential code injection'
  'eval.*".*\$|high|Eval with variable in quotes - potential code injection'
  'rm[[:space:]]+-rf[[:space:]]+/|critical|Dangerous: rm -rf on root filesystem'
  'rm[[:space:]]+-rf[[:space:]]+\$|high|rm -rf with variable path - verify safety'
  'chmod[[:space:]]+777|medium|World-writable permissions'
  'chmod[[:space:]]+-R[[:space:]]+777|high|Recursive world-writable permissions'
  ':(){.*:\|:.*};:|critical|Fork bomb detected'
  'mkfs\.|critical|Filesystem formatting command'
  'dd[[:space:]]+if=|high|Direct disk access'
  '>[[:space:]]*/dev/sd|critical|Direct write to block device'
  'sudo[[:space:]]+rm|medium|Sudo rm - verify user confirmation'
  'sudo[[:space:]]+chmod|medium|Sudo chmod - verify necessity'
  'sudo[[:space:]]+chown|medium|Sudo chown - verify necessity'
  'base64[[:space:]]+-d.*\|.*bash|high|Obfuscated code execution'
  'base64[[:space:]]+-d.*\|.*sh|high|Obfuscated code execution'
  'python.*-c.*exec|medium|Python exec - review carefully'
  'perl.*-e|medium|Perl one-liner - review carefully'
  'ruby.*-e|medium|Ruby one-liner - review carefully'
  '\$\{.*:.*\}|low|Parameter expansion - verify safety'
)

# Patterns that suggest sensitive data
SENSITIVE_PATTERNS=(
  'password|medium|Possible hardcoded password'
  'api_key|medium|Possible hardcoded API key'
  'api-key|medium|Possible hardcoded API key'
  'apikey|medium|Possible hardcoded API key'
  'secret|medium|Possible hardcoded secret'
  'token|low|Possible hardcoded token'
  'private_key|high|Possible hardcoded private key'
  'BEGIN RSA|critical|RSA private key detected'
  'BEGIN.*PRIVATE KEY|critical|Private key detected'
  'AWS_ACCESS_KEY|high|AWS access key'
  'AWS_SECRET|high|AWS secret key'
)

# Scan a file for dangerous patterns
# Usage: scan_file <file_path>
scan_file() {
  local file="$1"
  local findings=()
  local critical_count=0
  local high_count=0
  local medium_count=0
  local low_count=0
  
  if [ ! -f "$file" ]; then
    log "File not found: $file"
    return 1
  fi
  
  local filename
  filename=$(basename "$file")
  
  # Scan for dangerous patterns
  for pattern_info in "${DANGEROUS_PATTERNS[@]}"; do
    IFS='|' read -r pattern severity description <<< "$pattern_info"
    
    if grep -qE "$pattern" "$file" 2>/dev/null; then
      local line_num
      line_num=$(grep -nE "$pattern" "$file" 2>/dev/null | head -1 | cut -d: -f1)
      findings+=("[$severity] Line $line_num: $description")
      
      case "$severity" in
        critical) critical_count=$((critical_count + 1)) ;;
        high) high_count=$((high_count + 1)) ;;
        medium) medium_count=$((medium_count + 1)) ;;
        low) low_count=$((low_count + 1)) ;;
      esac
    fi
  done
  
  # Scan for sensitive data patterns
  for pattern_info in "${SENSITIVE_PATTERNS[@]}"; do
    IFS='|' read -r pattern severity description <<< "$pattern_info"
    
    if grep -qiE "$pattern" "$file" 2>/dev/null; then
      local line_num
      line_num=$(grep -niE "$pattern" "$file" 2>/dev/null | head -1 | cut -d: -f1)
      findings+=("[$severity] Line $line_num: $description")
      
      case "$severity" in
        critical) critical_count=$((critical_count + 1)) ;;
        high) high_count=$((high_count + 1)) ;;
        medium) medium_count=$((medium_count + 1)) ;;
        low) low_count=$((low_count + 1)) ;;
      esac
    fi
  done
  
  # Report findings
  if [ ${#findings[@]} -gt 0 ]; then
    echo "Scan results for: $filename"
    echo "----------------------------"
    for finding in "${findings[@]}"; do
      echo "  $finding"
    done
    echo ""
    echo "Summary: $critical_count critical, $high_count high, $medium_count medium, $low_count low"
    
    # Return error if critical or high issues found
    if [ $critical_count -gt 0 ] || [ $high_count -gt 0 ]; then
      return 1
    fi
  fi
  
  return 0
}

# Scan all scripts in a plugin
# Usage: scan_plugin_scripts <plugin_path>
scan_plugin_scripts() {
  local plugin_path="$1"
  local total_issues=0
  local files_scanned=0
  
  log "Scanning plugin scripts: $plugin_path"
  
  # Scan .sh files in plugin root
  for script in "$plugin_path"/*.sh; do
    if [ -f "$script" ]; then
      files_scanned=$((files_scanned + 1))
      if ! scan_file "$script"; then
        total_issues=$((total_issues + 1))
      fi
    fi
  done
  
  # Scan .sh files in packages directory
  if [ -d "$plugin_path/packages" ]; then
    for script in "$plugin_path/packages"/*.sh; do
      if [ -f "$script" ]; then
        files_scanned=$((files_scanned + 1))
        if ! scan_file "$script"; then
          total_issues=$((total_issues + 1))
        fi
      fi
    done
  fi
  
  # Scan config files (lua, zsh, etc.)
  if [ -d "$plugin_path/config" ]; then
    for config in "$plugin_path/config"/*; do
      if [ -f "$config" ]; then
        files_scanned=$((files_scanned + 1))
        if ! scan_file "$config"; then
          total_issues=$((total_issues + 1))
        fi
      fi
    done
  fi
  
  echo ""
  echo "Scan complete: $files_scanned files scanned, $total_issues files with issues"
  
  if [ $total_issues -gt 0 ]; then
    log "Security scan found issues. Review before installing."
    return 1
  fi
  
  log "Security scan passed"
  return 0
}

# Quick scan for critical issues only
# Usage: quick_scan <plugin_path>
quick_scan() {
  local plugin_path="$1"
  
  log "Quick security scan: $plugin_path"
  
  # Check for most critical patterns only
  local critical_patterns=(
    'curl.*|.*bash'
    'wget.*|.*bash'
    'rm -rf /'
    ':(){.*:|:.*};:'
    'mkfs.'
    '> /dev/sd'
    'BEGIN.*PRIVATE KEY'
  )
  
  for pattern in "${critical_patterns[@]}"; do
    if grep -rqE "$pattern" "$plugin_path"/*.sh 2>/dev/null; then
      log "CRITICAL: Found dangerous pattern: $pattern"
      return 1
    fi
    
    if [ -d "$plugin_path/packages" ]; then
      if grep -rqE "$pattern" "$plugin_path/packages"/*.sh 2>/dev/null; then
        log "CRITICAL: Found dangerous pattern in packages: $pattern"
        return 1
      fi
    fi
  done
  
  log "Quick scan passed"
  return 0
}

# Check for unquoted variables
# Usage: check_unquoted_variables <file>
check_unquoted_variables() {
  local file="$1"
  local warnings=0
  
  # Look for common dangerous unquoted patterns
  # $VAR instead of "$VAR" in risky contexts
  
  local patterns=(
    'rm.*\$[A-Za-z_][A-Za-z0-9_]*[^"]'
    'cd \$[A-Za-z_]'
    'source \$[A-Za-z_]'
  )
  
  for pattern in "${patterns[@]}"; do
    if grep -qE "$pattern" "$file" 2>/dev/null; then
      log "Warning: Potentially unquoted variable in $file"
      warnings=$((warnings + 1))
    fi
  done
  
  return $warnings
}

# Validate script syntax
# Usage: validate_script_syntax <file>
validate_script_syntax() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    log "File not found: $file"
    return 1
  fi
  
  if bash -n "$file" 2>/dev/null; then
    return 0
  fi
  
  log "Syntax error in: $file"
  bash -n "$file" 2>&1 | head -5
  return 1
}

# Full security audit of a plugin
# Usage: security_audit <plugin_path>
security_audit() {
  local plugin_path="$1"
  local audit_passed=true
  
  echo ""
  echo "=================================="
  echo "Security Audit: $(basename "$plugin_path")"
  echo "=================================="
  echo ""
  
  # 1. Validate bash syntax
  echo "1. Validating script syntax..."
  for script in "$plugin_path"/*.sh "$plugin_path"/packages/*.sh; do
    if [ -f "$script" ]; then
      if ! validate_script_syntax "$script"; then
        audit_passed=false
      fi
    fi
  done
  echo ""
  
  # 2. Scan for dangerous patterns
  echo "2. Scanning for dangerous patterns..."
  if ! scan_plugin_scripts "$plugin_path"; then
    audit_passed=false
  fi
  echo ""
  
  # 3. Check for unquoted variables
  echo "3. Checking variable quoting..."
  for script in "$plugin_path"/*.sh; do
    if [ -f "$script" ]; then
      check_unquoted_variables "$script"
    fi
  done
  echo ""
  
  # Final verdict
  echo "=================================="
  if [ "$audit_passed" = true ]; then
    echo "AUDIT RESULT: ✓ PASSED"
    return 0
  else
    echo "AUDIT RESULT: ✗ FAILED"
    echo ""
    echo "Review the issues above before installing this plugin."
    return 1
  fi
}
