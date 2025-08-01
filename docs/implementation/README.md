# Implementation Guides

This directory contains detailed implementation guides for various infrastructure components and integrations.

## Directory Structure

### 📋 [dns-ipam/](dns-ipam/)
DNS and IP Address Management implementation documentation
- **implementation-plan.md** - Master plan for DNS & IPAM overhaul (5 phases)
- **phase1-guide.md** - Detailed Phase 1 implementation guide
- **testing-strategy.md** - Testing approach for DNS/IPAM changes

### 🔐 [consul/](consul/)
HashiCorp Consul configuration and integration
- **acl-integration.md** - Consul ACL setup and integration patterns
- **telemetry-setup.md** - Configuring Consul telemetry and monitoring

### 🔑 [secrets-management/](secrets-management/)
Secrets management implementation
- **infisical-setup.md** - Infisical configuration and migration guide
- **comparison.md** - Comparison between 1Password and Infisical approaches

### 🗄️ [netbox-integration.md](netbox-integration.md)
NetBox as source of truth - integration patterns and best practices

## Implementation Phases

Following the DNS & IPAM roadmap:

1. **Phase 0** ✅ - Assessment (Complete)
2. **Phase 1** 🚧 - Consul DNS Foundation (In Progress)
3. **Phase 2** ✅ - PowerDNS Deployment (Playbooks Ready)
4. **Phase 3** ⏳ - NetBox Integration (Planned)
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

## Related Resources

- Playbooks: [`../../playbooks/infrastructure/`](../../playbooks/infrastructure/)
- Assessment Reports: [`../../reports/`](../../reports/)
- Operational Guides: [`../operations/`](../operations/)
- Project Tracking: [`../project-management/`](../project-management/)