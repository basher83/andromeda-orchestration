#!/usr/bin/env bash
# Secret scanning script using Infisical
# This script provides various secret scanning options for the repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  full         - Full repository scan"
    echo "  staged       - Scan only staged files (pre-commit)"
    echo "  ci           - CI/CD mode with SARIF output"
    echo "  baseline     - Update baseline file"
    echo "  help         - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 full      # Scan entire repository"
    echo "  $0 staged    # Scan staged changes before commit"
    echo "  $0 ci        # Run in CI with SARIF report"
}

# Check if infisical is installed
if ! command -v infisical &> /dev/null; then
    echo -e "${RED}Error: infisical CLI not found${NC}"
    echo "Install with: brew install infisical/brew/infisical"
    exit 1
fi

cd "${PROJECT_ROOT}"

case "${1:-full}" in
    full)
        echo -e "${GREEN}Running full repository scan...${NC}"
        infisical scan --verbose --redact
        ;;

    staged)
        echo -e "${GREEN}Scanning staged files...${NC}"
        infisical scan git-changes --staged --verbose --redact
        ;;

    ci)
        echo -e "${GREEN}Running CI scan with SARIF output...${NC}"
        infisical scan \
            --report-format sarif \
            --report-path "${PROJECT_ROOT}/infisical-scan-results.sarif" \
            --no-color \
            --exit-code 1
        ;;

    baseline)
        echo -e "${YELLOW}Updating baseline file...${NC}"
        infisical scan \
            --report-format json \
            --report-path "${PROJECT_ROOT}/.infisical-scan-baseline.json"
        echo -e "${GREEN}Baseline updated${NC}"
        ;;

    help|--help|-h)
        usage
        ;;

    *)
        echo -e "${RED}Unknown command: $1${NC}"
        usage
        exit 1
        ;;
esac
