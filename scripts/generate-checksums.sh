#!/bin/bash

# generate-checksums.sh - Generate checksums for critical Potions files
# Author: Henrique A. Lavezzo (Rynaro)
#
# This script generates SHA256 checksums for all critical files that need
# to be verified during upgrades. Run this script after updating the version
# or modifying critical files.

set -eo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if terminal supports colors
if [ -t 1 ]; then
  HAS_COLOR=true
else
  HAS_COLOR=false
fi

log_info() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${CYAN}⟹${NC} $1"
  else
    echo "==> $1"
  fi
}

log_success() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${GREEN}✓${NC} $1"
  else
    echo "[OK] $1"
  fi
}

log_warning() {
  if [ "$HAS_COLOR" = true ]; then
    echo -e "${YELLOW}⚠${NC} $1"
  else
    echo "[WARN] $1"
  fi
}

# Check for checksum tool
if command -v sha256sum &> /dev/null; then
  CHECKSUM_CMD="sha256sum"
elif command -v shasum &> /dev/null; then
  CHECKSUM_CMD="shasum -a 256"
else
  echo "ERROR: No checksum tool found (sha256sum or shasum)"
  exit 1
fi

# Critical files that need checksums
CRITICAL_FILES=(
  "drink.sh"
  "install.sh"
  "upgrade.sh"
  "plugins.sh"
  ".version"
  ".potions/.zshrc"
  ".potions/bin/potions"
)

CHECKSUMS_FILE="$REPO_ROOT/.checksums"

log_info "Generating checksums for critical files..."

cd "$REPO_ROOT"

# Calculate and write checksums
> "$CHECKSUMS_FILE"
MISSING_FILES=0

for file in "${CRITICAL_FILES[@]}"; do
  if [ -f "$file" ]; then
    CHECKSUM=$($CHECKSUM_CMD "$file" | awk '{print $1}')
    echo "$file $CHECKSUM" >> "$CHECKSUMS_FILE"
    log_success "Calculated checksum for $file"
  else
    log_warning "File not found: $file"
    MISSING_FILES=$((MISSING_FILES + 1))
  fi
done

# Sort for consistency (use LC_ALL=C for consistent ASCII sorting across platforms)
LC_ALL=C sort -o "$CHECKSUMS_FILE" "$CHECKSUMS_FILE"

echo ""
log_info "Checksums file generated: $CHECKSUMS_FILE"
echo ""

if [ $MISSING_FILES -gt 0 ]; then
  log_warning "$MISSING_FILES file(s) were not found and skipped"
  echo ""
fi

echo "Contents of .checksums:"
cat "$CHECKSUMS_FILE"
echo ""

log_success "Done! Commit this file along with your version change."
