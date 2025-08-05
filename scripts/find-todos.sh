#!/usr/bin/env bash
# Find all TODO tags in documentation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Searching for TODO tags in documentation...${NC}\n"

# Find TODOs in docs directory
echo -e "${YELLOW}=== Documentation TODOs ===${NC}"
rg "\[TODO\]:" docs/ --type md --no-heading --line-number 2>/dev/null || echo "No TODOs found in docs/"

echo ""

# Find TODOs in other markdown files
echo -e "${YELLOW}=== Other TODOs ===${NC}"
rg "\[TODO\]:" . --type md --glob '!docs/**' --glob '!.archive/**' --glob '!.testing/**' --no-heading --line-number 2>/dev/null || echo "No TODOs found in other markdown files"

echo ""

# Count total TODOs
total=$(rg "\[TODO\]:" . --type md --glob '!.archive/**' --glob '!.testing/**' --count-matches | awk -F: '{sum+=$2} END {print sum}')

if [ "$total" -gt 0 ]; then
    echo -e "${YELLOW}Total TODOs found: ${total}${NC}"
else
    echo -e "${GREEN}No TODOs found!${NC}"
fi