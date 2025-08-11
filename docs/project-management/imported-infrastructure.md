# Imported Infrastructure Components

This document describes the Ansible roles, modules, and configurations imported from the `terraform-homelab` repository on 2025-07-30.

## Overview

We've imported a complete Ansible infrastructure framework that was originally used to deploy and manage the Consul-Nomad clusters. This provides a solid foundation for implementing the DNS & IPAM overhaul project.

## Imported Roles

### 1. consul

**Purpose**: Deploy and configure HashiCorp Consul for service discovery and health checking

**Key Features**:

- Supports both server and client modes
- ACL configuration with token management
- Dual-network support (management and high-speed networks)
- Consul Connect service mesh enabled
- Prometheus metrics endpoint for Netdata integration

**Telemetry Configuration**:

- Prometheus endpoint exposed with configurable retention time
- Currently enabled only on nomad-server-1 for Netdata access
- Default retention: 360 hours
- Template includes telemetry block (needs to be enabled per host)

**Important Variables**:

- `consul_datacenter`: Datacenter name (default: dc1)
- `consul_server_enabled`: Whether node is a server
- `consul_acl_enabled`: Enable ACLs (default: true)
- `consul_encrypt`: Gossip encryption key

**Network Configuration**:

- Uses 192.168.11.x (high-speed network) for inter-cluster communication
- Binds to all interfaces on servers
- Retry join configured for servers: 192.168.11.11-13

### 2. nomad

**Purpose**: Deploy and configure HashiCorp Nomad for workload orchestration

**Key Features**:

- Server and client configuration
- CNI networking support
- Docker driver configuration
- LXC-specific optimizations
- Configuration validation

**Tasks Structure**:

- `install.yml`: Package installation
- `config.yml`: Configuration management
- `cni.yml`: Container networking setup
- `lxc.yml`: LXC-specific configurations
- `validate.yml`: Configuration validation

### 3. system_base

**Purpose**: Base system configuration and hardening

**Key Components**:

- **nftables firewall**: Already configured with Consul/Nomad ports including 8600/udp
- **Docker**: Container runtime configuration
- **Chrony**: Time synchronization
- **SSH hardening**: Security configurations

**Firewall Ports** (already configured):

- SSH: 22
- Consul: 8300-8302, 8500, 8600 (TCP/UDP)
- Nomad: 4646-4648
- Docker: 2375-2376

### 4. nfs

**Purpose**: Configure NFS client for shared storage

**Features**:

- NFS client package installation
- Mount point management
- Removal tasks for cleanup

## Imported Custom Modules

### Consul Modules

- `consul_acl_bootstrap`: Bootstrap Consul ACL system
- `consul_acl_policy`: Manage ACL policies
- `consul_acl_token`: Manage ACL tokens
- `consul_acl_get_token`: Retrieve ACL tokens
- `consul_connect_intention`: Manage Connect intentions
- `consul_get_service_detail`: Query service details

### Nomad Modules

- `nomad_job`: Deploy and manage Nomad jobs
- `nomad_job_parse`: Parse job specifications
- `nomad_acl_bootstrap`: Bootstrap Nomad ACL system
- `nomad_acl_policy`: Manage ACL policies
- `nomad_acl_token`: Manage ACL tokens
- `nomad_namespace`: Manage namespaces
- `nomad_scheduler`: Configure schedulers
- `nomad_csi_volume`: Manage CSI volumes

### Module Utilities

- `consul.py`: Consul API client utilities
- `nomad.py`: Nomad API client utilities
- `utils.py`: Common utility functions
- `debug.py`: Debugging helpers

## Created Roles

### consul_dns

**Purpose**: Configure DNS resolution for Consul service discovery (Phase 1)

**Features**:

- Configures systemd-resolved for `.consul` domain resolution
- Registers infrastructure services in Consul
- Validates DNS resolution
- Supports multiple DNS backends (systemd-resolved, dnsmasq, resolv)

**Default Services Registered**:

- Pi-hole instances (3 LXC containers)
- Pi-hole VIP (keepalived virtual IP)

## Integration Notes

### Network Architecture

The infrastructure uses two networks:

- **192.168.10.x**: Management network (used in staging inventory)
- **192.168.11.x**: High-speed network (used for Consul/Nomad communication)
- **192.168.30.x**: Infrastructure services (Pi-hole cluster)

### Current State vs. Repository

- The staging inventory uses 192.168.10.x addresses
- Our current working environment uses 192.168.11.x addresses
- This suggests the infrastructure may have been reconfigured after the original deployment

### ACL Token Management

- Tokens are stored in Infisical at `/apollo-13/consul/`
- The custom modules support token operations
- ACLs are enabled by default in the consul role

## Usage Examples

### Deploy Consul DNS (Phase 1)

```bash
# Using the new role
uv run ansible-playbook playbooks/infrastructure/consul/phase1-consul-dns.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# Or using the detailed playbook
uv run ansible-playbook playbooks/infrastructure/consul/phase1-consul-foundation.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Validate DNS Resolution

```bash
# Test on a specific host
uv run ansible nomad-server-1-lloyd -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m command -a "dig @127.0.0.1 -p 8600 consul.service.consul"
```

## Next Steps

1. **Phase 1 Implementation**: Configure Consul DNS on all nodes
2. **Phase 2 Planning**: PowerDNS Authoritative deployment for internal zones
3. **Phase 3**: Integrate NetBox for IPAM/DCIM
4. **Documentation**: Update role READMEs and playbooks with any changes
