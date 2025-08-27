# ADR-2025-08-23: Vault Production Deployment with Raft Storage

![Status](https://img.shields.io/badge/Status-Accepted-green)
![Date](https://img.shields.io/badge/Date-2025--08--23-lightgrey)
![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/docs/project-management/decisions/ADR-2025-08-23-vault-production-deployment.md)

## Status

Accepted (Phase 2 Complete)

## Context

Vault was running in development mode across the infrastructure, which caused critical limitations:

- **No persistence**: All secrets lost on restart (inmem storage)
- **No production features**: Auto-unsealing, audit logging, HA disabled
- **Blocking production services**: PostgreSQL, PowerDNS, and other services couldn't store credentials persistently
- **Security concerns**: Dev mode uses fixed tokens, no unsealing, HTTP only

This was identified as the root blocker preventing:

- Domain migration completion (.local → spaceships.work)
- PowerDNS deployment with PostgreSQL backend
- Production service deployments
- Proper secret management across the infrastructure

## Decision

Deploy Vault in production mode with:

### Storage Backend: Raft

- Integrated storage (no external dependencies like Consul)
- Built-in snapshots and backup
- Suitable for 3-5 node clusters
- Simpler disaster recovery than Consul backend

### Deployment Architecture

```plain
3-Node Raft Cluster:
- nomad-server-1-lloyd (192.168.10.11) - Leader
- nomad-server-2-holly (192.168.10.12) - Follower
- nomad-server-3-mable (192.168.10.13) - Follower

Storage: /opt/vault/data (persistent)
Ports: 8200 (API), 8201 (Cluster)
Version: 1.20.2 (standardized)
```

### Security Configuration

- **Initial Phase**: Manual unseal with 5 keys (3 of 5 threshold)
- **Audit Logging**: File backend at `/var/log/vault/audit.log`
- **TLS**: Disabled initially, enable in Phase 3
- **Policies**: PostgreSQL and PowerDNS service policies
- **Secret Storage**: Root token and unseal keys in Infisical

### Integration Points

- **Secrets Engines**: Database (PostgreSQL), KV v2 (application secrets)
- **Auth Methods**: Token (initial), JWT for Nomad workloads (planned)
- **Service Policies**: postgresql-service, powerdns-service

## Consequences

### Positive

- Persistent secret storage across restarts
- Production-ready security features
- Unblocks all downstream services
- Enables dynamic database credentials
- Audit trail for compliance
- HA with automatic failover

### Negative

- Manual unsealing required after restart (until auto-unseal configured)
- Operational complexity vs dev mode
- Backup procedures needed
- Monitoring requirements increased

### Risks

- Unseal key management (mitigated by Infisical storage)
- Raft consensus issues (mitigated by 3-node cluster)
- Storage corruption (mitigated by daily snapshots)
- Network partitions (mitigated by dual-NIC configuration)

## Alternatives Considered

### Alternative 1: Continue with Dev Mode

- Pros: Simple, no unsealing required
- Rejected: Blocks all production deployments, no persistence

### Alternative 2: Consul Storage Backend

- Pros: External storage, leverages existing Consul cluster
- Rejected: Additional dependency, complex troubleshooting

### Alternative 3: Dedicated Vault Cluster VMs

- Pros: Complete isolation, easier scaling
- Rejected: Resource overhead, complexity for current scale

### Alternative 4: PostgreSQL Storage Backend

- Pros: Familiar database, easy backups
- Rejected: HA complexity, performance concerns

## Implementation

### Phase 1: Production Deployment ✅

1. ✅ Pre-deployment assessment (all prerequisites met)
2. ✅ Stop dev mode services
3. ✅ Deploy production configuration with Ansible
4. ✅ Initialize cluster (lloyd as first node)
5. ✅ Secure initialization data in Infisical
6. ✅ Unseal all three nodes
7. ✅ Verify Raft cluster formation

### Phase 2: Configuration ✅

1. ✅ Enable audit logging
2. ✅ Create service policies (PostgreSQL, PowerDNS)
3. ✅ Enable secret engines (database, kv-v2)
4. ✅ Configure for 24.3GB storage capacity

### Phase 3: Service Integration 🚧

1. ⏳ Configure PostgreSQL database backend
2. ⏳ Set up Nomad JWT authentication
3. ⏳ Store PowerDNS secrets
4. ⏳ Enable auto-unseal (Transit or Cloud KMS)

### Phase 4: Operational Readiness ⏳

1. ⏳ Configure automated snapshots
2. ⏳ Integrate with monitoring (Netdata)
3. ⏳ Document runbooks
4. ⏳ Test disaster recovery

## Success Metrics

- ✅ 3-node cluster operational with Raft consensus
- ✅ Audit logging active
- ✅ Secret engines enabled
- ✅ Service policies created
- ⏳ PostgreSQL credentials generated dynamically
- ⏳ PowerDNS retrieving secrets
- ⏳ Automated backups running

## Migration Path

From dev mode to production:

```bash
# Stop dev mode
systemctl stop vault-dev

# Deploy production
ansible-playbook playbooks/infrastructure/vault/deploy-vault-prod.yml

# Initialize (one time)
vault operator init

# Unseal (after any restart)
vault operator unseal <key-1>
vault operator unseal <key-2>
vault operator unseal <key-3>
```

## Infrastructure Repository

The actual Vault cluster infrastructure (VMs, networking, storage) is managed via Terraform in a separate repository:

### [Hercules-Vault-Infra](https://github.com/basher83/Hercules-Vault-Infra)

- **Purpose**: Terraform code for provisioning the dedicated 4-VM Vault cluster
- **Backend**: Scalr remote state management
- **Workspace**: `production-vault`
- **Provider**: Proxmox (bpg/proxmox v0.78+)

### Architecture Details

```plain
Network: 192.168.10.30-33
├── vault-master (192.168.10.30) - Transit auto-unseal provider
│   └── 2 vCPU, 4GB RAM, 40GB SSD on node: lloyd
├── vault-prod-1 (192.168.10.31) - Production Raft node
│   └── 4 vCPU, 8GB RAM, 100GB SSD on node: holly
├── vault-prod-2 (192.168.10.32) - Production Raft node
│   └── 4 vCPU, 8GB RAM, 100GB SSD on node: mable
└── vault-prod-3 (192.168.10.33) - Production Raft node
    └── 4 vCPU, 8GB RAM, 100GB SSD on node: lloyd
```

### Deployment Flow

1. **Terraform (Hercules-Vault-Infra)**: Provisions VMs with cloud-init
2. **Cloud-init**: Installs Vault binary and QEMU guest agent
3. **Ansible (andromeda-orchestration)**: Configures and manages Vault cluster

### Key Features

- Automated VM provisioning via cloud-init
- HA distribution across Proxmox nodes
- Ubuntu 22.04 template (ID: 8000)
- Total resources: 14 vCPUs, 28GB RAM, 340GB storage

## References

- [Production Deployment Guide](docs/implementation/vault/production-deployment.md)
- [Vault Architecture](docs/diagrams/vault-architecture.md)
- [Vault Infrastructure Terraform](https://github.com/basher83/Hercules-Vault-Infra)
- [Raft Storage Documentation](https://developer.hashicorp.com/vault/docs/configuration/storage/raft)
- [Deployment Playbook](playbooks/infrastructure/vault/deploy-vault-prod.yml)
