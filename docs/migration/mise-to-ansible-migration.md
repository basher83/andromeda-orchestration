# Mise to Ansible Migration Guide

This guide documents the tasks that were removed from `.mise.toml` and their Ansible playbook equivalents.

## Overview

We've streamlined `.mise.toml` from 1,814 lines (93 tasks) to 462 lines (20 tasks), removing all infrastructure management tasks in favor of using Ansible playbooks directly.

## What Stays in Mise

- **Development Setup**: `setup`, `setup:quick`
- **Environment Switching**: `env:status`, `env:local`, `env:remote`
- **Health Checks**: `status`, `status:consul`, `status:nomad`, `status:vault`
- **Code Quality**: `lint`, `lint:*`, `test`, `test:syntax`
- **Security Scanning**: `security`, `security:secrets`, `security:kics`
- **Utilities**: `clean`, `help`

## Removed Tasks and Their Ansible Equivalents

### Deployment Tasks

| Removed Task | Ansible Equivalent |
|-------------|-------------------|
| `deploy:traefik` | `uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml -e job=traefik` |
| `deploy:postgresql` | `uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml -e job=postgresql` |
| `deploy:powerdns` | `uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml -e job=powerdns` |
| `deploy:core` | `uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml -e job_dir=core-infrastructure` |
| `deploy:platform` | `uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml -e job_dir=platform-services` |

### Consul Management

| Removed Task | Ansible Equivalent |
|-------------|-------------------|
| `service:consul` | `uv run ansible-playbook playbooks/infrastructure/consul/service-register.yml` |
| `cleanup:consul` | `uv run ansible-playbook playbooks/infrastructure/consul/cleanup-vault-services.yml` |
| `health:consul` | `uv run ansible-playbook playbooks/assessment/consul-assessment.yml` |
| `backup:consul` | `consul snapshot save backup.snap` (direct CLI when needed) |
| `kv:*` tasks | `uv run ansible-playbook playbooks/infrastructure/consul/phase1-consul-foundation.yml` |
| `checks:consul` | `uv run ansible-playbook playbooks/infrastructure/consul/consul-telemetry-setup.yml` |

### Nomad Management

| Removed Task | Ansible Equivalent |
|-------------|-------------------|
| `nomad-services` | `uv run ansible-playbook playbooks/infrastructure/nomad/register-service.yml` |
| `logs:nomad` | `nomad alloc logs <alloc-id>` (direct CLI when debugging) |
| `validate:nomad` | `uv run ansible-playbook playbooks/infrastructure/nomad/cluster-manage.yml` |
| `clean:nomad` | `nomad system gc` (direct CLI when needed) |
| `debug:nomad` | `uv run ansible-playbook playbooks/assessment/nomad-cluster-check.yml` |

### Vault Management

| Removed Task | Ansible Equivalent |
|-------------|-------------------|
| `auth:vault` | `uv run ansible-playbook playbooks/infrastructure/vault/test-connectivity.yml` |
| `unseal:vault` | `uv run ansible-playbook playbooks/infrastructure/vault/unseal-vault.yml` |
| `backup:vault` | `vault operator raft snapshot save backup.snap` (direct CLI when needed) |
| `secret:*` tasks | `uv run ansible-playbook playbooks/infrastructure/vault/manage-secrets.yml` |
| `db:*` tasks | `uv run ansible-playbook playbooks/infrastructure/vault/create-powerdns-secrets.yml` |
| `policy:*` tasks | Use Vault UI or direct API calls |
| `lease:*` tasks | Use Vault UI or direct API calls |
| `token:*` tasks | Use Vault UI or direct API calls |

### Debug/Troubleshooting Tasks

| Removed Task | Ansible Equivalent |
|-------------|-------------------|
| `debug:consul` | `uv run ansible-playbook playbooks/assessment/consul-assessment.yml` |
| `debug:nomad` | `uv run ansible-playbook playbooks/assessment/nomad-cluster-check.yml` |
| `debug:vault` | `uv run ansible-playbook playbooks/assessment/infrastructure-readiness.yml` |

### CI/Testing Tasks

| Removed Task | Ansible Equivalent |
|-------------|-------------------|
| `ci:consul` | `uv run ansible-playbook playbooks/assessment/consul-assessment.yml` |
| `ci:nomad` | `uv run ansible-playbook playbooks/assessment/nomad-cluster-check.yml` |
| `ci:vault` | Use GitHub Actions workflows |

### Other Removed Tasks

| Removed Task | Ansible Equivalent |
|-------------|-------------------|
| `dashboard:*` | Open browser to service URLs directly |
| `dns:consul` | `dig @<consul-ip> -p 8600 <service>.service.consul` |
| `traefik-services` | `uv run ansible-playbook playbooks/infrastructure/consul-nomad/fix-traefik-consul-dns.yml` |
| `tailscale:*` | Use tailscale CLI directly |
| `network_utils:install` | Part of system setup, not needed |
| `mcp:*` tasks | Keep only if using MCP features |

## Migration Workflow

### Before (using mise tasks)

```bash
mise run deploy:traefik
mise run status:nomad
mise run debug:consul
mise run secret:create -- my-secret
```

### After (using Ansible)

```bash
# Deploy services
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml -e job=traefik -i inventory/doggos-homelab/infisical.proxmox.yml

# Check status (still in mise for quick checks)
mise run status

# Debug issues
uv run ansible-playbook playbooks/assessment/consul-assessment.yml -i inventory/doggos-homelab/infisical.proxmox.yml

# Manage secrets
uv run ansible-playbook playbooks/infrastructure/vault/manage-secrets.yml -i inventory/doggos-homelab/infisical.proxmox.yml
```

## Benefits of This Approach

1. **Clear Separation**: Mise handles dev environment, Ansible handles infrastructure
2. **No Duplication**: One way to do things - through Ansible
3. **Better Maintainability**: Infrastructure logic in version-controlled playbooks
4. **Idempotency**: Ansible ensures operations are safe to repeat
5. **Error Handling**: Ansible provides better error messages and recovery
6. **Audit Trail**: All changes go through playbooks, not ad-hoc commands

## Quick Reference

For common operations, run:

```bash
mise run help
```

This will show you the most common Ansible commands for infrastructure management.
