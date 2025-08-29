# ADR-2025-01-26: Migration from 1Password to Infisical for Secrets Management

![Status](https://img.shields.io/badge/Status-Accepted-green)
![Date](https://img.shields.io/badge/Date-2025--01--26-lightgrey)
![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/docs/project-management/decisions/ADR-2025-01-26-infisical-migration.md)

## Status

Accepted

## Context

The project was using 1Password CLI (op) for secrets management in Ansible, but encountered several challenges:

- 1Password CLI required interactive authentication, breaking automation
- Complex syntax for secret retrieval in Ansible playbooks
- No native Ansible collection support
- Difficult to manage machine-to-machine authentication
- Cost considerations for team scaling
- Desktop app dependency for CLI authentication

Meanwhile, Infisical emerged as a better fit:

- Native Ansible collection (`infisical.vault`)
- Machine identity support for non-interactive auth
- Open source with self-hosting option
- Built specifically for DevOps workflows
- Free tier suitable for current needs

## Decision

Migrate all secret management from 1Password to Infisical:

### Architecture

1. **Infisical Cloud** for secret storage (initially)
2. **Machine Identity** authentication for Ansible
3. **Project Structure**:

   ```text
   /apollo-13/           # Main project
   ├── /services/        # Service credentials
   │   ├── netbox/       # NetBox API tokens
   │   ├── proxmox/      # Proxmox credentials
   │   └── tailscale/    # Tailscale API keys
   └── /vault/           # Vault tokens and keys
   ```

### Integration Pattern

```yaml
# In Ansible playbooks
netbox_token: >-
  {{ (lookup('infisical.vault.read_secrets',
             universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
             universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
             project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
             env_slug='staging',
             path='/apollo-13/services/netbox',
             secret_name='NETBOX_API_KEY')).value }}
```

### Secret Scanning Integration

```bash
# Pre-commit hook
infisical scan install --pre-commit-hook

# Manual scanning
infisical scan --verbose
```

## Consequences

### Positive

- Non-interactive authentication enables CI/CD automation
- Native Ansible integration reduces complexity
- Machine identities provide better security model
- Secret scanning prevents accidental commits
- Cost-effective for small teams
- Can self-host later if needed

### Negative

- Migration effort required for existing secrets
- Team needs to learn new tool
- Dependency on Infisical cloud (initially)
- Known issues with Python virtual environments (requires workarounds)
- Less mature than 1Password

### Risks

- Infisical service availability
- Potential for secret scanning false positives
- Virtual environment compatibility issues
- Breaking changes in Ansible collection

## Alternatives Considered

### Alternative 1: Continue with 1Password

- Pros: Already partially implemented, mature product
- Rejected: Interactive auth breaks automation, expensive for teams

### Alternative 2: HashiCorp Vault Only

- Pros: Industry standard, powerful features
- Rejected: Overhead for small deployments, complex setup

### Alternative 3: Ansible Vault

- Pros: Built into Ansible, no external dependencies
- Rejected: No centralized management, difficult key rotation

### Alternative 4: AWS Secrets Manager

- Pros: Managed service, AWS integration
- Rejected: Cloud lock-in, cost at scale

## Implementation

1. ✅ Set up Infisical project (apollo-13)
2. ✅ Create machine identity for Ansible
3. ✅ Migrate secrets from 1Password
4. ✅ Update all inventory files to use Infisical
5. ✅ Install and configure secret scanning
6. ✅ Document configuration in `docs/implementation/infisical/`
7. ✅ Add environment variables to shell configuration
8. Remove 1Password CLI dependencies

## Workarounds

### Virtual Environment Issue

When Infisical Ansible collection fails with "worker was found in a dead state":

```bash
# Use CLI to export secret as environment variable
export NETBOX_TOKEN=$(infisical run --env=staging --path="/apollo-13/services/netbox" -- printenv NETBOX_API_KEY)
```

### Always Use uv run

```bash
# Ensures proper Python environment
uv run ansible-playbook playbooks/site.yml -i inventory/doggos-homelab/infisical.proxmox.yml
```

## References

- [Infisical Documentation](https://infisical.com/docs)
- [Implementation Guide](docs/implementation/infisical/infisical-complete-guide.md)
- [Ansible Collection Issues](https://github.com/Infisical/ansible-collection/issues)
- Original 1Password implementation (removed)
