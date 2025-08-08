# NetBox Infrastructure Playbooks

This directory contains playbooks for managing NetBox as the source of truth for infrastructure.

## Directory Structure

```
netbox/
├── dns/                    # DNS zone and record management
│   ├── discover-zones.yml  # Discover current DNS configuration in NetBox
│   ├── setup-zones.yml     # Create DNS zones and nameservers
│   ├── populate-records.yml # Populate DNS records from infrastructure
│   ├── powerdns-netbox-integration.yml # Configure PowerDNS backend
│   └── test-dns-resolution.yml # Test DNS resolution through PowerDNS
├── ipam/                   # IP address management (future)
├── netbox-discover.yml     # Discover all NetBox configuration
├── netbox-populate-infrastructure.yml # Populate devices and VMs
└── netbox-check-plugins.yml # Check installed NetBox plugins
```

## Quick Start

### 1. Check NetBox Status

```bash
# Discover current NetBox configuration
uv run ansible-playbook playbooks/infrastructure/netbox/netbox-discover.yml

# Check installed plugins
uv run ansible-playbook playbooks/infrastructure/netbox/netbox-check-plugins.yml
```

### 2. DNS Management

```bash
# Setup DNS zones (creates forward and reverse zones)
uv run ansible-playbook playbooks/infrastructure/netbox/dns/setup-zones.yml

# Discover current DNS configuration
uv run ansible-playbook playbooks/infrastructure/netbox/dns/discover-zones.yml

# Populate DNS records from infrastructure
uv run ansible-playbook playbooks/infrastructure/netbox/dns/populate-records.yml

# Configure PowerDNS to use NetBox as backend
uv run ansible-playbook playbooks/infrastructure/netbox/dns/powerdns-netbox-integration.yml

# Test DNS resolution
uv run ansible-playbook playbooks/infrastructure/netbox/dns/test-dns-resolution.yml
```

### 3. Infrastructure Population

```bash
# Populate NetBox with Proxmox hosts and VMs
uv run ansible-playbook playbooks/infrastructure/netbox/netbox-populate-infrastructure.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

## Important Notes

- **ALWAYS use `uv run`** prefix for Ansible commands to ensure proper Python environment
- Infisical environment variables must be set (see CLAUDE.md)
- NetBox API token is stored at `/apollo-13/services/netbox/NETBOX_API_KEY` in Infisical
- If Infisical Ansible collection fails, use the CLI workaround documented in CLAUDE.md

## NetBox Access

- URL: https://192.168.30.213
- DNS Plugin: v1.3.5 (installed and operational as of Aug 8, 2025)

## PowerDNS Integration

PowerDNS is running on Nomad at 192.168.11.20 and can be configured to use NetBox as its backend for DNS data.
