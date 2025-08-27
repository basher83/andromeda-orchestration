# GitHub Copilot Instructions

This document provides comprehensive guidance for GitHub Copilot and automated agents working with the Andromeda Orchestration repository, a NetBox-focused Ansible automation project for infrastructure management.

## Tool Installation with Mise

**CRITICAL**: All tools are managed via mise configuration (`.mise.toml`). Never commit binaries to the repository.

### Quick Setup (60-120 seconds)

```bash
# Install mise first (if not available)
curl https://mise.run | sh

# Complete project setup
mise run setup

# Or for minimal setup (dependencies only)
mise run setup:quick
```

### Environment Management

```bash
# Check current environment and connectivity
mise run env:status

# Switch between environments
mise run env:local     # LAN access (192.168.11.11)
mise run env:remote    # Tailscale access (100.108.219.48)

# Test connectivity
mise run env:test
```

### Available Tools

All tools are automatically installed via mise:

- **Infrastructure**: nomad (1.10.4), consul (1.21.4), vault (1.20.2)
- **Python**: python (3.13.7), uv (0.8.13), ansible-core (2.19.0)
- **Utilities**: jq, ruff, fd, rg, eza, age, sops

## Ansible Playbook Execution

### Infisical Integration Patterns

**ALWAYS use `uv run` prefix** for Ansible commands to ensure proper Python environment:

```bash
# Standard playbook execution with Infisical secrets
uv run ansible-playbook playbooks/site.yml -i inventory/og-homelab/infisical.proxmox.yml

# Assessment playbooks (Phase 0)
uv run ansible-playbook playbooks/assessment/consul-health-check.yml -i inventory/og-homelab/infisical.proxmox.yml
uv run ansible-playbook playbooks/assessment/dns-ipam-audit.yml -i inventory/og-homelab/infisical.proxmox.yml

# Localhost-only playbooks (skip inventory)
uv run ansible-playbook playbooks/infrastructure/netbox-dns-discover.yml
```

### Dynamic Inventory Management

```bash
# Test inventory configurations
uv run ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --list
uv run ansible-inventory -i inventory/doggos-homelab/infisical.proxmox.yml --list

# Graph inventory structure
uv run ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --graph
```

### Common Execution Patterns

```bash
# Infrastructure readiness assessment
uv run ansible-playbook playbooks/assessment/infrastructure-readiness.yml \
  -i inventory/og-homelab/infisical.proxmox.yml

# NetBox data discovery
uv run ansible-playbook playbooks/infrastructure/netbox-playbook.yml

# Vault operations
uv run ansible-playbook playbooks/infrastructure/vault-setup.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

## Nomad Job Management

### Core Operations

```bash
# Deploy any Nomad job via Ansible
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/core-infrastructure/traefik.nomad.hcl

# Direct Nomad operations via mise
mise run validate:nomad              # Validate all jobs
mise run plan:nomad -- <job-file>    # Plan specific job
mise run deploy:traefik              # Deploy Traefik
mise run deploy:postgresql           # Deploy PostgreSQL
mise run deploy:powerdns             # Deploy PowerDNS via Ansible
```

### Job Development Workflow

```bash
# Format and validate
mise run fmt:nomad
mise run lint:nomad
mise run validate:nomad:job -- nomad-jobs/core-infrastructure/traefik.nomad.hcl

# Monitor and debug
mise run status:nomad
mise run logs:nomad -- <alloc-id>
mise run debug:nomad -- <job-name>

# Cleanup
mise run clean:nomad
```

### Deployment Patterns

**Core Infrastructure (Phase 1)**:
```bash
mise run deploy:core        # Traefik load balancer
```

**Platform Services (Phase 2)**:
```bash
mise run deploy:platform    # PostgreSQL + PowerDNS
```

## Consul Service Discovery and KV Store Operations

### Health and Status

```bash
# Cluster health
mise run status:consul
mise run health:consul
mise run debug:consul

# Service discovery
mise run services:consul
mise run service:consul -- traefik
mise run dns:consul -- postgres
```

### KV Store Management

```bash
# PowerDNS configuration setup
mise run kv:setup-powerdns

# Generic KV operations
mise run kv:list                           # List all keys
mise run kv:list -- pdns/                 # List with prefix
mise run kv:get -- pdns/db/host           # Get specific value
mise run kv:put -- pdns/api/key secret123 # Set value
```

### Integration Monitoring

```bash
# Nomad service registration
mise run nomad-services:consul

# Traefik service configuration
mise run traefik-services:consul

# Service health monitoring
mise run health:nomad
```

## Vault Secret Management and Database Secrets Engine

### Authentication and Status

```bash
# Cluster status
mise run status:vault
mise run health:vault
mise run debug:vault

# Authentication
mise run auth:vault
mise run token:vault
```

### KV Secrets Management

```bash
# Secret operations
mise run secrets:list                      # List all secrets
mise run secret:get -- pdns               # Get PowerDNS secrets
mise run secret:put -- pdns db_password=secret api_key=abc123
mise run secret:delete -- old-secret
```

### Database Secrets Engine (PowerDNS Integration)

```bash
# Setup PowerDNS database secrets engine
mise run db:setup-powerdns

# Database operations
mise run db:status                         # Show engine status
mise run db:config -- powerdns-database   # Show connection config
mise run db:role -- powerdns-role         # Show role definition
mise run db:creds -- powerdns-role        # Generate credentials

# Complete PowerDNS setup
mise run setup:vault-powerdns
mise run test:vault-integration
```

### Lease Management

```bash
# Lease operations
mise run leases:vault                      # List active leases
mise run lease:revoke -- <lease-id>       # Revoke specific lease
mise run leases:revoke-prefix -- database/creds/powerdns-role/
```

## Environment Switching Between Local and Remote Clusters

### Environment Configurations

**Local Environment (LAN)**:
- Nomad: `http://192.168.11.11:4646`
- Consul: `http://192.168.11.11:8500`
- Vault: `http://192.168.11.11:8200`

**Remote Environment (Tailscale)**:
- Nomad: `http://100.108.219.48:4646`
- Consul: `http://100.108.219.48:8500`
- Vault: `http://100.108.219.48:8200`

### Switching Commands

```bash
# Environment management
mise run env:status    # Show current environment
mise run env:local     # Switch to LAN access
mise run env:remote    # Switch to Tailscale access
mise run env:test      # Test current connectivity

# Apply changes to current shell
eval "$(mise env)"
```

### Connectivity Verification

Each environment command automatically tests connectivity and provides status:
- ✅ Connected services
- ❌ Failed connections with troubleshooting hints
- Network requirements (LAN access vs Tailscale)

## Security Scanning and Maintenance Procedures

### Security Scanning

```bash
# Comprehensive security scans
mise run security                # Run all security scans
mise run security:secrets        # Infisical secrets detection
mise run security:kics          # Infrastructure security scan

# Results location: kics-results/
```

### Code Quality and Linting

```bash
# Linting
mise run lint:markdown
mise run lint:python
mise run lint:nomad
mise run validate:consul

# Fixing
mise run fix:markdown
mise run fmt:nomad
```

### Testing and Validation

```bash
# Comprehensive testing
mise run test                    # Run all tests
mise run test:syntax            # Ansible syntax check
mise run test:quick             # Smoke tests
mise run ci:nomad              # Nomad CI pipeline
mise run ci:consul             # Consul health checks
mise run ci:vault              # Vault health checks
```

### Maintenance Tasks

```bash
# Cleanup
mise run clean                 # Remove caches and generated files
mise run clean:nomad          # Clean failed allocations
mise run cleanup:consul       # Consul maintenance

# Backup operations
mise run backup:consul        # KV store backup
mise run backup:vault         # Vault data backup

# Documentation helpers
mise run todos                # Find TODO tags
mise run tags:critical        # Find SECURITY/FIXME/BUG tags
```

## Performance Expectations and Troubleshooting Guidance

### Setup Performance

- **Initial setup**: `mise run setup` completes in 60-120 seconds
- **Tool installation**: Automatic via mise hooks on directory enter
- **Python environment**: `uv sync --extra dev` ~30-45 seconds
- **Ansible collections**: Installation ~15-30 seconds

### Common Issues and Solutions

#### Infisical Integration Issues

**Problem**: "worker was found in a dead state" errors with Infisical lookups

**Solution**: Use CLI workaround:
```bash
export NETBOX_TOKEN=$(infisical run --env=staging --path="/apollo-13/services/netbox" -- printenv NETBOX_API_KEY)
ansible-playbook playbooks/infrastructure/netbox-playbook.yml
```

#### Environment Connectivity

**Problem**: Cannot reach Nomad/Consul/Vault

**Solutions**:
1. Check environment: `mise run env:status`
2. Switch environment: `mise run env:local` or `mise run env:remote`
3. Verify network: Tailscale for remote, LAN for local
4. Test connectivity: `mise run env:test`

#### Tool Management

**Problem**: Tools not found or outdated

**Solutions**:
1. Reinstall tools: `mise install`
2. Full setup: `mise run setup`
3. Check tool status: `mise list`

#### Python Environment Issues

**Problem**: Virtual environment broken

**Solutions**:
```bash
# Recreate venv
rm -rf .venv
uv venv
uv sync --extra dev

# Or full setup
mise run setup
```

### Performance Optimization

1. **Use mise tasks** for common operations instead of manual commands
2. **Leverage caching**: Mise automatically caches tool installations
3. **Batch operations**: Use combined tasks like `mise run ci:nomad`
4. **Environment-specific configs**: Use `.mise.local.toml` for local overrides

### Debug Commands

```bash
# Infrastructure debugging
mise run debug:nomad -- <job-name>
mise run debug:consul
mise run debug:vault

# General troubleshooting
mise run env:status
mise run test:quick
mise tasks                    # List all available tasks
```

### Expected Response Times

- **Nomad deployment**: 10-30 seconds per job
- **Consul KV operations**: < 1 second
- **Vault secret retrieval**: < 2 seconds
- **Ansible playbook syntax check**: 1-5 seconds
- **Infrastructure health checks**: 2-5 seconds

### Resource Requirements

- **Memory**: 2GB minimum, 4GB recommended
- **Storage**: 1GB for tools, 2GB for full environment
- **Network**: Stable connection to Tailscale (remote) or LAN (local)
- **Ports**: 4646 (Nomad), 8500 (Consul), 8200 (Vault)

## DNS & IPAM Implementation Context

This project is implementing a comprehensive DNS & IPAM overhaul (see `docs/implementation/dns-ipam/implementation-plan.md`):

- **Phase 0**: Assessment and auditing (current)
- **Phase 1**: Core infrastructure deployment (Traefik)
- **Phase 2**: Database and DNS services (PostgreSQL, PowerDNS)
- **Phase 3**: NetBox integration and data migration
- **Phase 4**: Advanced DNS features and automation

Use assessment playbooks to understand current state before making infrastructure changes.

## Integration Patterns

### NetBox as Source of Truth

- Query device information from NetBox APIs
- Use dynamic inventory patterns from `docs/implementation/dns-ipam/netbox-integration-patterns.md`
- Implement event-driven automation based on NetBox changes

### Infisical Secrets Management

- Secrets organized under `/apollo-13/` path structure
- Machine identity authentication preferred
- Environment-specific secret paths (`staging`, `production`)

### Container-First Approach

- All services deployed via Nomad
- No binaries committed to repository
- Use mise for tool management and task automation

## Best Practices

1. **Always use mise tasks** over direct tool invocation
2. **Test connectivity** before running infrastructure commands
3. **Use Infisical integration** for any secrets access
4. **Validate syntax** before deploying Nomad jobs
5. **Monitor health** after infrastructure changes
6. **Follow DNS & IPAM implementation phases** for systematic deployment

For additional guidance, see `CLAUDE.md` for detailed project context and patterns.