# Current Infrastructure State

This document provides a comprehensive overview of the current infrastructure deployment state across all clusters and services.

## Clusters

### og-homelab

**Type**: Original Proxmox cluster
**Nodes**: proxmoxt430, pve1
**Workload**: Mixed LXCs and VMs

### doggos-homelab

**Type**: 3-node Proxmox cluster
**Nodes**: lloyd, holly, mable
**Infrastructure**: Running Nomad orchestration platform

- **Nomad Servers**: 3 (one per node)
- **Nomad Clients**: 3 (one per node)
- **Tags**: nomad, staging, terraform, server/client roles

## Services Overview

| Service | Status | Description |
|---------|--------|-------------|
| **Consul** | Production | Service mesh with ACLs enabled |
| **Nomad** | Production | Container orchestration on doggos-homelab |
| **Vault** | Production | Secrets management with Raft storage and auto-unseal |
| **DNS** | Migration | Currently Pi-hole + Unbound (migrating to PowerDNS) |
| **IPAM** | Planning | Ad-hoc management (to be replaced with NetBox) |

## Nomad Cluster Details

### Production Deployment

Nomad orchestration platform for containerized workloads.

#### Servers (Raft consensus)

| Node | IP Address | Ports | Network | Notes |
|------|------------|-------|---------|-------|
| nomad-server-1-lloyd | 192.168.11.11 | 4646-4648 | 10G ops | v1.10.4 |
| nomad-server-2-holly | 192.168.11.12 | 4646-4648 | 10G ops | v1.10.3, typically leader |
| nomad-server-3-mable | 192.168.11.13 | 4646-4648 | 10G ops | v1.10.3 |

#### Clients (Workers)

| Node | IP Address | Network |
|------|------------|---------|
| nomad-client-1-lloyd | 192.168.11.20 | 10G ops |
| nomad-client-2-holly | 192.168.11.21 | 10G ops |
| nomad-client-3-mable | 192.168.11.22 | 10G ops |

#### Configuration

- **Network**: Dual NICs - 192.168.10.x (management), 192.168.11.x (10G operations)
- **Features**: Docker driver, host volumes, dynamic volumes, Consul integration
- **ACLs**: Currently disabled (to be enabled)
- **Web UI**: Available on any server node port 4646

## Consul Cluster Details

### Production Deployment

Service mesh and service discovery platform.

#### Servers (Raft consensus)

| Node | IP Address | Ports | Network | Notes |
|------|------------|-------|---------|-------|
| nomad-server-1 | 192.168.11.11 | 8300-8302, 8500-8502, 8600 | 10G ops | v1.21.4 |
| nomad-server-2 | 192.168.11.12 | 8300-8302, 8500-8502, 8600 | 10G ops | v1.21.3, typically leader |
| nomad-server-3 | 192.168.11.13 | 8300-8302, 8500-8502, 8600 | 10G ops | v1.21.3 |

#### Clients

| Node | IP Address | Ports | Version |
|------|------------|-------|---------|
| nomad-client-1 | 192.168.11.20 | 8301, 8500, 8600 | v1.21.3 |
| nomad-client-2 | 192.168.11.21 | 8301, 8500, 8600 | v1.21.3 |
| nomad-client-3 | 192.168.11.22 | 8301, 8500, 8600 | v1.21.3 |

#### Configuration

- **Network**: Dual NICs - 192.168.10.x (management), 192.168.11.x (10G operations)
- **Datacenter**: dc1
- **ACLs**: Enabled with bootstrap tokens
- **DNS**: Available on port 8600
- **Web UI**: Available on any node port 8500

## Vault Cluster Details

### Production Deployment

Secrets management platform with dedicated 4-VM cluster.

#### Transit Master

| Node | IP Address | Port | Purpose |
|------|------------|------|---------|
| vault-master-lloyd | 192.168.10.30 | 8200 | Provides auto-unseal service |

#### Production Raft Cluster

| Node | IP Address | Ports |
|------|------------|-------|
| vault-prod-1-holly | 192.168.10.31 | 8200, 8201 |
| vault-prod-2-mable | 192.168.10.32 | 8200, 8201 |
| vault-prod-3-lloyd | 192.168.10.33 | 8200, 8201 |

#### Configuration

- **Domain**: vault.spaceships.work (configured, deployment pending verification)
- **Storage**: Raft consensus with integrated storage
- **Security**: TLS enabled, auto-unseal via transit engine
- **Inventory**: `inventory/vault-cluster/production.yaml`
- **Authentication**: Access tokens and recovery keys stored in Infisical at `/apollo-13/vault/`

## Related Documentation

- [Vault Access Guide](vault-access.md) - Detailed Vault access procedures
- [DNS Deployment Status](dns-deployment-status.md) - DNS migration progress
- [Nomad Implementation](../implementation/nomad/) - Nomad configuration guides
- [Consul Implementation](../implementation/consul/) - Consul setup documentation
- [Infrastructure Standards](../standards/infrastructure-standards.md) - Architecture decisions

## Maintenance

This document should be updated whenever infrastructure changes occur, including:

- Version upgrades
- New node deployments
- Service configuration changes
- Network modifications
- Security updates

Last updated: 2025-09-10
