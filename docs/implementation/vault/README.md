# Vault Implementation Documentation

HashiCorp Vault deployment and integration documentation for secrets management, PKI, and encryption services.

## 🏗️ Infrastructure Provisioning

The Vault cluster VMs are provisioned via Terraform in a separate repository:

- **Repository**: [Hercules-Vault-Infra](https://github.com/basher83/Hercules-Vault-Infra)
- **Purpose**: Terraform code for 4-VM dedicated Vault cluster
- **Architecture**: 1 Transit Master + 3 Raft nodes (192.168.10.30-33)
- **Management**: Scalr workspace `production-vault`
- **Resources**: 14 vCPUs, 28GB RAM, 340GB storage

This repository (andromeda-orchestration) handles the Ansible configuration after VMs are provisioned.

## 📚 Documentation

### Core Implementation

- **[deployment-strategy.md](deployment-strategy.md)** - Complete Vault deployment strategy with phased approach
  - Dev mode exploration
  - Production deployment with Raft
  - Nomad and Consul integration
  - Operational procedures

- **[production-deployment.md](production-deployment.md)** - Production deployment runbook and tracking
  - Pre-deployment checklists and validation
  - Step-by-step deployment procedures
  - Configuration and integration steps
  - Success criteria and verification

### Advanced Patterns

- **[enhanced-deployment-strategy.md](enhanced-deployment-strategy.md)** - Production-grade patterns from community research
  - Master Vault architecture
  - Three-tier PKI hierarchy
  - Automated secret rotation with consul-template
  - Advanced snapshot and disaster recovery

### Research & Analysis

- **[repository-comparison.md](repository-comparison.md)** - Analysis of production Vault implementations
  - Pattern comparison across Deltamir, Skatteetaten, and wescale
  - Implementation validation
  - Best practices extraction

## 🚀 Quick Start

### Development Deployment

```bash
# Deploy Vault in dev mode for exploration
uv run ansible-playbook playbooks/infrastructure/vault/deploy-vault-dev.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Production Deployment

```bash
# Deploy Vault with Raft storage
uv run ansible-playbook playbooks/infrastructure/vault/deploy-vault-prod.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

## 📋 Implementation Status

### ✅ Completed

- Ansible role structure
- Dev mode configuration
- Production Raft configuration
- Nomad JWT integration templates
- Consul service registration
- Comprehensive documentation

### 🚧 In Progress

- Production deployment (Phase 2 Complete - see [production-deployment.md](production-deployment.md))
- Testing in homelab environment
- PKI hierarchy setup

### ⏳ Planned

- Master Vault deployment
- Automated secret rotation
- Snapshot automation
- Service integrations completion

## 🏗️ Architecture Overview

### Storage Backends

- **Development**: In-memory (ephemeral)
- **Production**: Raft (integrated, no external dependencies)
- **Alternative**: Consul (for large-scale deployments)

### Integration Points

- **Nomad**: JWT workload identity for dynamic secrets
- **Consul**: Service registration and health checks
- **Infisical**: Secure storage of unseal keys and root tokens

### Security Layers

1. **Auto-unseal**: Transit, AWS KMS, Azure Key Vault options
2. **Audit Logging**: File and syslog backends
3. **Policy Framework**: Three-tier (admin/producer/consumer)
4. **Certificate Management**: Automated renewal via PKI

## 📁 Related Resources

### Playbooks

- `playbooks/infrastructure/vault/deploy-vault-dev.yml`
- `playbooks/infrastructure/vault/deploy-vault-prod.yml`

### Role

- `roles/vault/` - Complete Ansible role with tasks, templates, handlers

### Configuration

- `roles/vault/defaults/main.yml` - Default variables
- `roles/vault/templates/` - Configuration templates

## 🔑 Key Decisions

### Why Raft Storage?

- No external dependencies (vs Consul backend)
- Integrated snapshots and backup
- Suitable for 3-5 node clusters
- Simpler disaster recovery

### Why Support Dev Mode?

- Safe exploration environment
- Learning and testing features
- Clear migration path to production
- No unsealing required during development

### Why Optional TLS?

- Flexibility for internal homelab networks
- Simplified initial deployment
- Can enable for production/external access
- Clear security documentation

## 📊 Deployment Phases

| Phase | Focus | Duration | Status |
|-------|-------|----------|--------|
| 0 | Infrastructure Assessment | 1 day | ✅ Complete |
| 1 | Production Cluster Setup | 1 week | ✅ Complete |
| 2 | Configuration & Integration | 1 week | ✅ Complete |
| 3 | Service Integration | 1 week | 🚧 In Progress |
| 4 | Secret Rotation | 1 week | ⏳ Planned |
| 5 | Disaster Recovery | 1 week | ⏳ Planned |
| 6 | Full Integration | 1 week | ⏳ Planned |

## 🔧 Troubleshooting

### Common Issues

- **Vault is sealed**: Check auto-unseal configuration or manually unseal
- **Cannot connect**: Verify network, firewall rules, and service status
- **Permission denied**: Ensure mlock capability is set on binary

### Useful Commands

```bash
# Check Vault status
export VAULT_ADDR='http://vault:8200'
vault status

# Unseal Vault (if not using auto-unseal)
vault operator unseal <key>

# View audit logs
tail -f /var/log/vault/audit.log | jq
```

## 📚 Further Reading

- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault)
- [Vault Best Practices](https://developer.hashicorp.com/vault/docs/concepts/seal)
- [Raft Storage Backend](https://developer.hashicorp.com/vault/docs/configuration/storage/raft)
