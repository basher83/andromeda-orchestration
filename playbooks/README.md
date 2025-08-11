# Ansible Playbooks

This directory contains all Ansible playbooks organized by their purpose and lifecycle stage. Each subdirectory has a specific focus area with detailed documentation.

## Directory Structure

### 📊 `assessment/`

**Purpose**: Infrastructure assessment and validation playbooks

These playbooks are used to evaluate the current state of infrastructure, identify issues, and verify readiness for changes. They are non-destructive and generate reports.

**Key Playbooks**:

- `infrastructure-readiness.yml` - Comprehensive infrastructure assessment
- `consul-assessment.yml` - Consul cluster health evaluation
- `dns-ipam-audit.yml` - DNS and IPAM configuration audit
- `nomad-cluster-check.yml` - Nomad cluster status verification
- `robust-connectivity-test.yml` - Network connectivity validation

**When to Use**: Before major changes, during troubleshooting, or for regular health checks

---

### 🏗️ `infrastructure/`

**Purpose**: Production infrastructure deployment and management

The main directory for operational playbooks that deploy, configure, and manage infrastructure components. Contains subdirectories for each major service or component.

**Subdirectories**:

- `consul/` - Consul service mesh and DNS configuration
- `consul-nomad/` - Integration between Consul and Nomad
- `monitoring/` - Netdata monitoring deployment
- `network/` - Network and firewall configuration
- `nomad/` - Nomad cluster management
- `powerdns/` - PowerDNS deployment (Phase 2)
- `user-management/` - User and SSH key management
- `maintenance/` - Update and maintenance tasks

**When to Use**: For production deployments, configuration changes, and routine maintenance

See [`infrastructure/README.md`](infrastructure/README.md) for detailed usage instructions.

---

### 💡 `examples/`

**Purpose**: Reference implementations and demos

Contains example playbooks demonstrating specific features or integration patterns. These are educational and can be used as templates for custom playbooks.

**Key Examples**:

- `infisical-demo.yml` - Demonstrates Infisical secret management
- `netdata-consul-template.yml` - Shows Consul Template integration

**When to Use**: Learning new patterns, testing features, or as starting points for custom playbooks

---

## Playbook Naming Conventions

- **Service-based**: `<service>-<action>.yml` (e.g., `consul-assessment.yml`)
- **Phase-based**: `phase<N>-<description>.yml` (e.g., `phase1-consul-dns.yml`)
- **Action-based**: `<action>-<target>.yml` (e.g., `deploy-netdata-all.yml`)

## Common Usage Patterns

### Running Assessment Playbooks

```bash
# Run all assessments for a cluster
uv run ansible-playbook playbooks/assessment/infrastructure-readiness.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# Check specific service health
uv run ansible-playbook playbooks/assessment/consul-assessment.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Deploying Infrastructure

```bash
# Deploy monitoring to all clusters
uv run ansible-playbook playbooks/infrastructure/monitoring/deploy-netdata-all.yml \
  -i inventory/*/infisical.proxmox.yml

# Setup PowerDNS (Phase 2)
uv run ansible-playbook playbooks/infrastructure/powerdns/powerdns-setup-consul-kv.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Using Examples

```bash
# Test Infisical integration
uv run ansible-playbook playbooks/examples/infisical-demo.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

## Best Practices

1. **Always run assessments first** - Use assessment playbooks before making changes
2. **Use the right inventory** - Match playbooks to appropriate clusters
3. **Check playbook documentation** - Most directories have their own README
4. **Test in staging** - Use doggos-homelab for testing before og-homelab
5. **Follow the phases** - Respect the DNS/IPAM implementation phases

## Quick Reference

| Need to... | Use Playbook | Location |
|------------|--------------|----------|
| Check infrastructure health | `infrastructure-readiness.yml` | `assessment/` |
| Deploy Netdata monitoring | `deploy-netdata-all.yml` | `infrastructure/monitoring/` |
| Setup PowerDNS | See PowerDNS README | `infrastructure/powerdns/` |
| Configure Consul DNS | `phase1-consul-dns.yml` | `infrastructure/consul/` |
| Manage Nomad jobs | `job-deploy.yml` | `infrastructure/nomad/` |
| Setup users/SSH | `setup-ansible-user.yml` | `infrastructure/user-management/` |

## Implementation Status

- ✅ **Phase 0**: Assessment playbooks (Complete)
- 🚧 **Phase 1**: Consul DNS foundation (In Progress)
- ✅ **Phase 2**: PowerDNS deployment (Complete - Playbooks Ready)
- ⏳ **Phase 3**: NetBox integration (Planned)
- ⏳ **Phase 4**: Pi-hole migration (Planned)
- ⏳ **Phase 5**: Scaling & automation (Planned)

## Related Documentation

- Project roadmap: [`/ROADMAP.md`](../ROADMAP.md)
- DNS/IPAM implementation plan: [`/docs/implementation/dns-ipam/implementation-plan.md`](../docs/implementation/dns-ipam/implementation-plan.md)
- Infrastructure playbook details: [`infrastructure/README.md`](infrastructure/README.md)
- PowerDNS deployment guide: [`infrastructure/powerdns/README.md`](infrastructure/powerdns/README.md)
