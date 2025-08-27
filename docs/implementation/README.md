# Implementation Guides

This directory contains detailed implementation guides for various infrastructure components and integrations.

## Directory Structure

### 📋 [dns-ipam/](dns-ipam/)

DNS and IP Address Management implementation documentation (including NetBox IPAM)

- **implementation-plan.md** - Master plan for DNS & IPAM overhaul (5 phases)
- **domain-migration-master-plan.md** - Critical .local to spaceships.work migration plan
- **phase1-guide.md** - Phase 1: Consul DNS Foundation
- **phase3-netbox-deployment.md** - Phase 3: NetBox IPAM deployment and configuration
- **netbox-integration-patterns.md** - Comprehensive NetBox automation patterns with Ansible
- **testing-strategy.md** - Testing approach for DNS/IPAM changes
- **archive/** - Historical domain migration documents

### 🌐 [powerdns/](powerdns/)

PowerDNS deployment architecture and configuration

- **deployment-architecture.md** - Architecture decision (Mode A vs Mode B) and implementation guide
- Complete deployment steps with PostgreSQL backend
- Migration strategies and operational considerations

### 🔐 [consul/](consul/)

HashiCorp Consul configuration and integration

- **acl-integration.md** - Consul ACL setup and integration patterns
- **telemetry-setup.md** - Configuring Consul telemetry and monitoring

### 🔒 [vault/](vault/)

HashiCorp Vault deployment and secrets management

- **deployment-strategy.md** - Complete deployment strategy with phased approach
- **enhanced-deployment-strategy.md** - Production-grade patterns from community research
- **repository-comparison.md** - Analysis of production implementations

### 📦 [nomad/](nomad/)

HashiCorp Nomad orchestration and job configuration

- **storage-configuration.md** - Complete storage configuration guide
- **storage-strategy.md** - Strategic approach to Nomad storage
- **storage-patterns.md** - Common storage implementation patterns
- **port-allocation.md** - Port allocation best practices

### 🔑 [infisical/](infisical/)

Infisical secrets management implementation

- **infisical-setup.md** - Infisical configuration and migration guide
- **andromeda-infisical-config.md** - Project-specific configuration
- **comparison.md** - Comparison between 1Password and Infisical approaches

## Implementation Phases

Following the DNS & IPAM roadmap:

1. **Phase 0** ✅ - Assessment (Complete)
2. **Phase 1** 🚧 - Consul DNS Foundation (In Progress)
3. **Phase 2** ✅ - PowerDNS Deployment (Playbooks Ready)
4. **Phase 3** 🚀 - NetBox Integration (Accelerated - NetBox deployed!)
5. **Phase 4** ⏳ - Pi-hole Migration (Planned)
6. **Phase 5** ⏳ - Scale & Automate (Future)

## Using These Guides

### For New Implementations

1. Start with the relevant implementation plan
2. Follow phase-specific guides in order
3. Use testing strategies before production

### For Troubleshooting

- Check specific service directories for configuration details
- Review integration patterns in respective guides
- Refer to operational docs in [`../operations/`](../operations/)

## Infrastructure Documentation

### 📚 [imported-infrastructure.md](imported-infrastructure.md)

Documentation of Ansible roles and configurations imported from terraform-homelab repository:

- Consul and Nomad roles
- Network configuration patterns
- ACL and security configurations
- Integration components

## Related Resources

- Playbooks: [`../../playbooks/infrastructure/`](../../playbooks/infrastructure/)
- Assessment Reports: [`../../reports/`](../../reports/)
- Operational Guides: [`../operations/`](../operations/)
- Project Tracking: [`../project-management/`](../project-management/)
