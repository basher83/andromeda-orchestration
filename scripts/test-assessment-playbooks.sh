#!/usr/bin/env bash
#
# Test script for assessment playbooks
# This script runs the assessment playbooks with various options to ensure they work correctly

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default inventory
INVENTORY="${1:-inventory/doggos-homelab/infisical.proxmox.yml}"

echo -e "${YELLOW}Testing Assessment Playbooks${NC}"
echo "Using inventory: $INVENTORY"
echo

# Function to run a playbook and check result
run_playbook() {
    local playbook=$1
    local description=$2
    local extra_args="${3:-}"
    
    echo -e "${YELLOW}Testing: $description${NC}"
    echo "Running: uv run ansible-playbook $playbook -i $INVENTORY $extra_args"
    
    if uv run ansible-playbook "$playbook" -i "$INVENTORY" $extra_args; then
        echo -e "${GREEN}✓ $description passed${NC}"
        return 0
    else
        echo -e "${RED}✗ $description failed${NC}"
        return 1
    fi
    echo
}

# Track failures
FAILURES=0

# Test 1: DNS/IPAM Audit - Basic run
if ! run_playbook "playbooks/assessment/dns-ipam-audit.yml" "DNS/IPAM Audit - Basic"; then
    ((FAILURES++))
fi

# Test 2: DNS/IPAM Audit - With specific tags
if ! run_playbook "playbooks/assessment/dns-ipam-audit.yml" "DNS/IPAM Audit - DNS Services Only" "--tags dns,services"; then
    ((FAILURES++))
fi

# Test 3: Infrastructure Readiness - Basic run
if ! run_playbook "playbooks/assessment/infrastructure-readiness.yml" "Infrastructure Readiness - Basic"; then
    ((FAILURES++))
fi

# Test 4: Infrastructure Readiness - Network tests only
if ! run_playbook "playbooks/assessment/infrastructure-readiness.yml" "Infrastructure Readiness - Network Only" "--tags network"; then
    ((FAILURES++))
fi

# Test 5: Infrastructure Readiness - Skip network tests
if ! run_playbook "playbooks/assessment/infrastructure-readiness.yml" "Infrastructure Readiness - Skip Network" "--skip-tags network"; then
    ((FAILURES++))
fi

# Test 6: Robust Connectivity Test
if ! run_playbook "playbooks/assessment/robust-connectivity-test.yml" "Robust Connectivity Test"; then
    ((FAILURES++))
fi

# Test 7: Check mode (dry run)
if ! run_playbook "playbooks/assessment/dns-ipam-audit.yml" "DNS/IPAM Audit - Check Mode" "--check"; then
    ((FAILURES++))
fi

# Summary
echo
echo -e "${YELLOW}Test Summary${NC}"
echo "=============="
if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$FAILURES test(s) failed${NC}"
    echo
    echo "Troubleshooting tips:"
    echo "1. Ensure Infisical environment variables are set:"
    echo "   export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=your_client_id"
    echo "   export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=your_client_secret"
    echo
    echo "2. Run with increased verbosity:"
    echo "   uv run ansible-playbook playbook.yml -i $INVENTORY -vv"
    echo
    echo "3. Test connectivity manually:"
    echo "   uv run ansible all -i $INVENTORY -m ping"
    echo
    echo "4. Check specific hosts:"
    echo "   uv run ansible-inventory -i $INVENTORY --list"
    exit 1
fi