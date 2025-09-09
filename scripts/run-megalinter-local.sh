#!/bin/bash

# Local MegaLinter Runner Script
# Uses efrecon/mega-linter-runner for fast local testing
# Bypasses Docker Hub rate limits by using GHCR

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Local MegaLinter Runner${NC}"
echo -e "${BLUE}==============================${NC}"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Download the efrecon runner if not present
RUNNER_SCRIPT="/tmp/mega-linter-runner.sh"
if [ ! -f "$RUNNER_SCRIPT" ]; then
    echo -e "${YELLOW}📥 Downloading efrecon mega-linter-runner...${NC}"
    curl -s https://raw.githubusercontent.com/efrecon/mega-linter-runner/main/mega-linter-runner.sh -o "$RUNNER_SCRIPT"
    chmod +x "$RUNNER_SCRIPT"
fi

# Change to project root
cd "$PROJECT_ROOT"

echo -e "${GREEN}✅ Running MegaLinter with terraform flavor...${NC}"
echo -e "${YELLOW}💡 This uses GHCR (no Docker Hub rate limits)${NC}"
echo -e "${YELLOW}⚡ Faster than npx (no Node.js dependency downloads)${NC}"
echo ""

# Run MegaLinter
"$RUNNER_SCRIPT" --flavor terraform "$@"

echo ""
echo -e "${GREEN}✅ MegaLinter completed!${NC}"
echo -e "${BLUE}📊 Check megalinter-reports/ directory for detailed results${NC}"
