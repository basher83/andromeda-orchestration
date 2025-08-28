# Ansible Inventory Management

This document describes the inventory structure and management approach for the Andromeda Orchestration project.

## Overview

We use multiple inventory sources to manage different aspects of our infrastructure:

- **Proxmox dynamic inventories** for VM and container discovery
- **NetBox dynamic inventory** for IPAM and network device management
- **Tailscale inventory** for VPN-connected nodes
- **Static inventories** for specific clusters (e.g., Vault)

## Directory Structure

```plain
inventory/
├── environments/           # Environment-specific inventories
│   ├── doggos-homelab/    # Primary homelab cluster
│   │   ├── proxmox.yml    # Proxmox dynamic inventory
│   │   ├── group_vars/    # Group variables
│   │   └── host_vars/     # Host-specific variables
│   ├── og-homelab/        # Original homelab
│   │   ├── proxmox.yml
│   │   ├── group_vars/
│   │   └── host_vars/
│   ├── vault-cluster/     # Dedicated Vault cluster
│   │   └── production.yaml
│   └── all/               # Shared across environments
│       └── localhost.yml
├── dynamic/               # Dynamic inventory sources
│   ├── netbox.yml        # NetBox with caching enabled
│   └── tailscale/
│       └── ansible_tailscale_inventory.py
└── combined/             # Reserved for symlinks/combinations
```

## Configuration

### Default Inventory

The default inventory is configured in `.mise.toml`:

```toml
[env]
ANSIBLE_INVENTORY = "inventory/environments/doggos-homelab"
```

This can be overridden using:

- Environment variable: `export ANSIBLE_INVENTORY=...`
- Command line: `ansible-playbook -i inventory/path ...`
- Local mise config: `.mise.local.toml`

### NetBox Inventory Caching

The NetBox inventory (`inventory/dynamic/netbox.yml`) includes caching to handle connection failures gracefully:

```yaml
cache: true
cache_plugin: ansible.builtin.jsonfile
cache_timeout: 86400  # 24 hours
cache_connection: .ansible_cache/netbox
```

When NetBox is unreachable, cached data will be used if available within the timeout period.

## Using Different Inventories

### Quick Switching with mise

```bash
# List available inventories
mise run inventory:list

# Switch to different inventories (shows export command)
mise run inventory:doggos    # doggos-homelab
mise run inventory:og        # og-homelab
mise run inventory:netbox    # NetBox dynamic
mise run inventory:combined  # Multiple sources
```

### Direct Usage

```bash
# Single inventory
ansible-playbook playbook.yml -i inventory/environments/doggos-homelab

# Multiple inventories (combined)
ansible-playbook playbook.yml \
  -i inventory/environments/doggos-homelab \
  -i inventory/dynamic/netbox.yml

# Using environment variable
export ANSIBLE_INVENTORY="inventory/environments/og-homelab"
ansible-playbook playbook.yml
```

## Environment-Specific Inventories

### doggos-homelab

- **Type**: Proxmox dynamic inventory
- **Purpose**: Primary 3-node cluster running Nomad/Consul/Vault
- **Hosts**: lloyd, holly, mable nodes
- **Use Case**: Production workloads

### og-homelab

- **Type**: Proxmox dynamic inventory
- **Purpose**: Original homelab infrastructure
- **Hosts**: proxmoxt430, pve1
- **Use Case**: Legacy systems and testing

### vault-cluster

- **Type**: Static inventory
- **Purpose**: Dedicated 4-VM Vault cluster
- **Hosts**: vault-master-lloyd, vault-prod-[1-3]
- **Use Case**: Secrets management

## Dynamic Inventories

### NetBox

- **Purpose**: IPAM and network device management
- **Features**:
  - Caching for offline operation
  - Grouping by site, role, platform, tags
  - Custom field support
- **Authentication**: API token retrieved from Infisical at `/apollo-13/services/netbox/NETBOX_API_KEY`
- **Required**: Infisical authentication (INFISICAL_UNIVERSAL_AUTH_CLIENT_ID/SECRET)

### Tailscale

- **Purpose**: VPN-connected nodes
- **Dynamic Script**: `inventory/dynamic/tailscale/ansible_tailscale_inventory.py`
- **Static Fallback**: `inventory/dynamic/tailscale/static.yml`
- **Required**: Tailscale API key (for dynamic inventory)
- **Use Case**: Remote access via Tailscale VPN

## Best Practices

1. **Default to Environment Inventories**: Use environment-specific inventories for most operations
2. **Explicit NetBox Usage**: Only use NetBox inventory when network device information is needed
3. **Combine When Necessary**: Use multiple inventories together for comprehensive coverage
4. **Cache for Resilience**: NetBox caching ensures operations continue even when NetBox is down
5. **Document Special Cases**: Add host_vars/group_vars for environment-specific configurations

## Secret Management

All dynamic inventories use Infisical for secret management:

### Proxmox Inventories

- **Token Location**: `/apollo-13/proxmox/ANSIBLE_TOKEN_ID` and `ANSIBLE_TOKEN_SECRET`
- **Environment**: `prod` for doggos-homelab, `prod` for og-homelab

### NetBox Inventory

- **Token Location**: `/apollo-13/services/netbox/NETBOX_API_KEY`
- **Environment**: `staging`

### Required Environment Variables

```bash
# Infisical authentication (required for all dynamic inventories)
export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID="your-client-id"
export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET="your-client-secret"
```

## Testing Inventories

### Verify Inventory Configuration

```bash
# Test specific inventory
ansible-inventory -i inventory/environments/doggos-homelab --graph

# Test NetBox with caching
ansible-inventory -i inventory/dynamic/netbox.yml --list

# Test combined inventories
ansible-inventory -i inventory/environments/doggos-homelab \
                  -i inventory/dynamic/netbox.yml --graph

# Check what inventory is currently configured
echo $ANSIBLE_INVENTORY
```

### Debugging Inventory Issues

```bash
# Verbose output to see plugin details
ansible-inventory -i inventory/dynamic/netbox.yml --list -vvvv

# Check cache contents
ls -la .ansible_cache/netbox/

# Force cache refresh (delete cache files)
rm -rf .ansible_cache/netbox/*
```

## Troubleshooting

### NetBox Connection Warnings

If you see NetBox connection warnings when not using NetBox:

- These are harmless - NetBox inventory is not loaded unless explicitly specified
- The warnings only appear if NetBox inventory is in a scanned directory

### Missing Hosts

If hosts are missing from inventory:

- Check the correct environment is selected: `echo $ANSIBLE_INVENTORY`
- Verify Proxmox/NetBox connectivity
- Clear cache if needed: `rm -rf .ansible_cache/netbox`
- Ensure Infisical credentials are set: `env | grep INFISICAL`

### Multiple Inventory Sources

When using multiple inventories:

- Order matters - later sources can override earlier ones
- Use `ansible-inventory --graph` to verify the combined view
- Group variables are merged, with later sources taking precedence

## Common Use Cases

### Development Against Specific Environment

```bash
# Work with doggos-homelab only
export ANSIBLE_INVENTORY="inventory/environments/doggos-homelab"
ansible-playbook playbooks/site.yml

# Quick ad-hoc command
ansible nomad-server-1 -m ping
```

### Network Device Management

```bash
# Use NetBox for network device operations
ansible-playbook playbooks/network/configure-switches.yml \
  -i inventory/dynamic/netbox.yml
```

### Cross-Environment Operations

```bash
# Target all Proxmox environments
ansible-playbook playbooks/updates/system-updates.yml \
  -i inventory/environments/doggos-homelab \
  -i inventory/environments/og-homelab
```

### Remote Access via Tailscale

```bash
# Use Tailscale IPs for remote management
ansible-playbook playbooks/site.yml \
  -i inventory/dynamic/tailscale/static.yml
```

## Migration Notes

As of 2025-08-26, we migrated from a flat inventory structure to an environment-based hierarchy to:

- Eliminate unwanted NetBox warnings during normal operations
- Provide better organization for multiple environments
- Enable easy switching between inventory sources
- Support graceful fallback when dynamic sources are unavailable
- Centralize secret management through Infisical
