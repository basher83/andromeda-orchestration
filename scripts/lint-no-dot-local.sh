#!/usr/bin/env bash
#
# Lint check to prevent .local domain usage
# .local domains conflict with mDNS on macOS systems
#
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Files to check (excluding archives, docs, and virtual environments)
FILES_TO_CHECK=$(find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.hcl" -o -name "*.nomad" -o -name "*.tf" \) \
  ! -path "*/.archive/*" \
  ! -path "*/reports/*" \
  ! -path "*/.venv/*" \
  ! -path "*/docs/*" \
  ! -path "*/.git/*" \
  2>/dev/null || true)

# Track if we found any violations
FOUND_VIOLATIONS=0

# Check each file for .local domains
for file in $FILES_TO_CHECK; do
  # Skip if file doesn't exist (race condition protection)
  [ -f "$file" ] || continue

  # Look for .local domains that are actual hostnames/domains
  # Only match: lab.local, homelab.local, or traefik.local etc (hostname patterns)
  if grep -E '(^[^#]*)(lab\.local|homelab\.local|traefik\.local|vault\.local|consul\.local|nomad\.local)' "$file" > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Found .local domain in: $file"
    grep -n -E '(^[^#]*)(lab\.local|homelab\.local|traefik\.local|vault\.local|consul\.local|nomad\.local)' "$file" | head -3
    FOUND_VIOLATIONS=1
  fi
done

# Summary
if [ $FOUND_VIOLATIONS -eq 0 ]; then
  echo -e "${GREEN}✓${NC} No .local domains found in active code"
  exit 0
else
  echo -e "\n${RED}ERROR:${NC} Found hardcoded .local domains"
  echo "Please use the 'homelab_domain' variable instead"
  echo "Example: {{ homelab_domain }} instead of lab.local"
  exit 1
fi
