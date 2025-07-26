# Assessment Playbooks

## Overview
Phase 0 infrastructure assessment playbooks evaluate the current state of DNS, IPAM, and service infrastructure before implementing changes.

## Available Playbooks

### consul-health-check.yml
Evaluates Consul cluster health and configuration:
- Service status and cluster membership
- DNS configuration (port 8600)
- ACL and encryption settings
- Generates per-node and cluster-wide reports

### dns-ipam-audit.yml
Audits current DNS and IPAM infrastructure:
- Pi-hole statistics and custom DNS entries
- DHCP lease analysis
- DNS zone configuration
- Network segment documentation
- Identifies gaps in current setup

### infrastructure-readiness.yml
Evaluates readiness for new services:
- System resources (CPU, RAM, disk)
- Docker availability
- Network connectivity
- Determines capacity for NetBox, PowerDNS deployment

## Usage
```bash
# Run assessment against specific inventory
./bin/ansible-connect playbook playbooks/assessment/consul-health-check.yml -i inventory/doggos-homelab/proxmox.yml

# Target specific hosts or groups
./bin/ansible-connect playbook playbooks/assessment/dns-ipam-audit.yml -i inventory/og-homelab/proxmox.yml --limit tag_pihole
```

## Output Structure
Reports are generated in:
- `reports/<service>/<hostname>.yml` - Raw YAML data
- `reports/<service>/<hostname>_summary.md` - Human-readable summaries
- `reports/<service>/<service>_cluster_summary.md` - Cluster-wide analysis

## Key Features
- Non-intrusive read-only operations
- Comprehensive data collection
- Both machine-readable and human-friendly outputs
- Cluster-wide analysis and recommendations
- Production-ready with full linting compliance