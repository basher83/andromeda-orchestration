# ADR-2025-01-27: Mise.toml Simplification from Infrastructure to Development Focus

![Status](https://img.shields.io/badge/Status-Accepted-green)
![Date](https://img.shields.io/badge/Date-2025--01--27-lightgrey)
![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/docs/project-management/decisions/ADR-2025-01-27-mise-toml-simplification.md)

## Status

Accepted

## Context

The mise.toml configuration file had grown to nearly 2000 lines (1,814 lines) with 93 tasks, becoming unmanageable:
- Many tasks duplicated Ansible playbook functionality
- Infrastructure management tasks belonged in Ansible, not mise
- Difficult to find and maintain tasks
- Violated separation of concerns (mise for dev env, Ansible for infrastructure)
- As an Ansible repository, using mise for infrastructure tasks was contradictory

## Decision

Refactor mise.toml to focus exclusively on:
1. **Development environment setup** - Tools, dependencies, pre-commit hooks
2. **Code quality** - Linting, testing, security scanning
3. **Cluster status checks** - Quick health checks for Nomad, Consul, Vault
4. **Developer utilities** - Clean, help, PM status

Remove all infrastructure management tasks and delegate them to Ansible playbooks where they belong.

### Final Structure (462 lines, 20 tasks)
```toml
# Categories:
- Setup & Environment (setup, install-hooks)
- Inventory Management (inventory-*)
- Testing (test, test-*)
- Linting (lint, lint-*)
- Security (security, scan-secrets)
- Cluster Status (status)
- Utilities (clean, help, pm-status)
```

### Key Configuration Changes
```toml
[settings]
python.uv_venv_auto = true  # Auto-activate Python venv

[env]
ANSIBLE_INVENTORY = "inventory/environments/doggos-homelab"
ANSIBLE_HOST_KEY_CHECKING = "False"
ANSIBLE_STDOUT_CALLBACK = "yaml"
```

## Consequences

### Positive
- 75% reduction in configuration size (1,814 → 462 lines)
- Clear separation of concerns (mise for dev, Ansible for ops)
- Faster mise startup and task discovery
- Easier to maintain and understand
- Consistent with repository purpose (Ansible-first)
- Auto-activation of Python environment prevents issues

### Negative
- Users need to learn Ansible commands for infrastructure tasks
- Some convenience lost for quick infrastructure operations
- Migration period where muscle memory needs adjustment

### Risks
- Documentation needs updating to reflect new commands
- Existing automation scripts may break
- Team members need retraining on where tasks moved

## Alternatives Considered

### Alternative 1: Keep All Tasks but Organize Better
- Create subcategories and better organization within mise
- Rejected: Still violates separation of concerns, maintains bloat

### Alternative 2: Split into Multiple Config Files
- Create mise.infrastructure.toml, mise.dev.toml, etc.
- Rejected: Adds complexity, doesn't solve fundamental issue

### Alternative 3: Move Everything to Makefile
- Use traditional Make instead of mise
- Rejected: Mise provides better tool management and environment handling

## Implementation

1. ✅ Identified core development tasks to keep
2. ✅ Removed 73 infrastructure-related tasks
3. ✅ Added Python venv auto-activation
4. ✅ Added default Ansible environment variables
5. ✅ Created inventory management tasks for new structure
6. ✅ Added pm-status task for project management health
7. Document new workflow in README
8. Update team training materials

## Migration Guide

### Before (mise task)
```bash
mise run deploy-traefik
mise run consul-register-service
mise run vault-unseal
```

### After (Ansible playbook)
```bash
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml -e job=traefik
uv run ansible-playbook playbooks/infrastructure/consul/service-register.yml
uv run ansible-playbook playbooks/infrastructure/vault/unseal-vault.yml
```

## References

- Original 1,814-line mise.toml (see git history)
- [Mise documentation](https://mise.jdx.dev/)
- Discussion about mise growth getting "BEYOND useful"
