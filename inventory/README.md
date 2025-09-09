# Ansible Inventory Management

This directory contains all dynamic and static inventory configurations for the Andromeda Orchestration infrastructure automation project.

## Directory Structure

```
inventory/
├── combined/              # Combined inventory configurations
├── dynamic/               # Dynamic inventory sources
│   ├── netbox.yml        # NetBox dynamic inventory
│   └── tailscale/        # Tailscale inventory management
│       ├── ansible_tailscale_inventory.py
│       └── static.yml
└── environments/          # Environment-specific inventories
    ├── all/              # Global configurations
    ├── doggos-homelab/   # 3-node Nomad cluster environment
    ├── og-homelab/       # Original cluster environment
    └── vault-cluster/    # Dedicated Vault production cluster
```

## Current Implementation

### Proxmox Dynamic Inventory

Using `community.general.proxmox` plugin for infrastructure discovery:

- **`og-homelab/infisical.proxmox.yml`** - Original cluster inventory
- **`doggos-homelab/infisical.proxmox.yml`** - 3-node Nomad cluster inventory

### Tailscale Dynamic Inventory

Dynamic inventory for Tailscale-managed nodes:

- **`tailscale/ansible_tailscale_inventory.py`** - Dynamic inventory script
- **`tailscale/static.yml`** - Static inventory for testing scenarios

### Vault Cluster Inventory

Dedicated inventory for Vault production deployment:

- **`vault-cluster/production.yaml`** - 4-VM Vault production cluster configuration

### NetBox Inventory

IPAM and infrastructure documentation integration:

- **`netbox.yml`** - NetBox dynamic inventory (functional, pending post-DNS-migration adjustments)

## In Progress

### DNS & IPAM Infrastructure Deployment

See `docs/implementation/dns-ipam/implementation-plan.md` for current status and roadmap.

## Planned

### Full NetBox Dynamic Inventory Integration

Reference `docs/implementation/dns-ipam/netbox-integration-patterns.md` for implementation patterns and best practices.

## Authentication Configuration

### Environment Variables Required

- **Infisical**: Machine identity credentials via environment variables
- **Tailscale**: API key via environment variables
- **NetBox**: API token via Infisical integration

### Setup Instructions

1. Ensure required API credentials are available via Infisical
2. Set environment variables for dynamic inventory authentication
3. Test inventory connectivity before running playbooks

## Usage Examples

### List all hosts in an environment

```bash
ansible-inventory -i environments/doggos-homelab/ --list
```

### Test dynamic inventory

```bash
ansible-inventory -i dynamic/netbox.yml --list
```

### Run playbook against specific environment

```bash
ansible-playbook -i environments/doggos-homelab/ playbooks/infrastructure/consul.yml
```

## Environment Details

### doggos-homelab

- **Purpose**: 3-node Nomad cluster for application workloads
- **Hosts**: holly, lloyd, mable
- **Services**: Nomad servers/clients, Consul agents

### og-homelab

- **Purpose**: Original infrastructure cluster
- **Hosts**: Multiple Proxmox VMs and physical servers
- **Services**: Core infrastructure, monitoring, DNS

### vault-cluster

- **Purpose**: Dedicated HashiCorp Vault production deployment
- **Hosts**: 4 dedicated VMs for high availability
- **Services**: Vault servers with integrated storage

## Contributing

When adding new inventory configurations:

1. Follow the established directory structure
2. Include comprehensive group and host variables
3. Document authentication requirements
4. Test inventory connectivity
5. Update this README with new configurations

## References

- [Inventory Documentation Standards](../docs/standards/ansible-standards.md)
- [DNS & IPAM Implementation](../docs/implementation/dns-ipam/)
- [NetBox Integration Patterns](../docs/implementation/dns-ipam/netbox-integration-patterns.md)
