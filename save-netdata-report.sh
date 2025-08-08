#!/bin/bash
# Save Netdata configuration reports

TIMESTAMP=$(date +%Y-%m-%d_%H%M)
REPORT_DIR="reports/netdata"

mkdir -p "$REPORT_DIR"

echo "Collecting Netdata configurations..."

# Run playbook and capture output
uv run ansible-playbook playbooks/infrastructure/.debug/check-netdata-state.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -i inventory/og-homelab/infisical.proxmox.yml \
  --limit "proxmoxt430,pve1,nomad-server-1-lloyd,nomad-server-2-holly,nomad-server-3-mable,nomad-client-1-lloyd,nomad-client-2-holly,nomad-client-3-mable" \
  2>/dev/null | tee "$REPORT_DIR/netdata_state_${TIMESTAMP}.txt"

echo "Report saved to: $REPORT_DIR/netdata_state_${TIMESTAMP}.txt"
