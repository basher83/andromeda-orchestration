# Infisical Complete Configuration Guide

This document consolidates all Infisical documentation for the andromeda-orchestration project, providing a single comprehensive reference for setup, configuration, and usage.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Project Configuration](#project-configuration)
3. [Authentication Setup](#authentication-setup)
4. [Secret Organization](#secret-organization)
5. [Usage Patterns](#usage-patterns)
6. [Free vs Paid Features](#free-vs-paid-features)
7. [Technical Implementation](#technical-implementation)
8. [Testing and Verification](#testing-and-verification)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)
11. [Migration Guide](#migration-guide)
12. [Future Considerations](#future-considerations)

## Project Overview

Infisical serves as the primary secret management solution for the andromeda-orchestration project, managing credentials for Ansible playbooks, dynamic inventories, and infrastructure automation.

### Core Concepts

1. **Projects**: Top-level container for all secrets
   - Must specify project type when creating
   - Each project has a unique ID
   - Cannot change type after creation

2. **Environments**: Logical separation within a project
   - `prod` (production)
   - `staging`
   - `dev` (development)

3. **Folders**: Real entities within environments that must be created
   - Have unique IDs
   - Created via API or UI
   - NOT just path prefixes in secret names

4. **Secrets**: Key-value pairs stored within folders
   - Accessed by combining environment, folder path, and secret name

## Project Configuration

### Andromeda Orchestration Project Details

- **Project Name**: andromeda-orchestration-homelab
- **Project ID**: `7b832220-24c0-45bc-a5f1-ce9794a31259`
- **Project Type**: `secret-manager`
- **Environments**: dev, staging, prod
- **Status**: Active in production

## Authentication Setup

### Universal Auth with Machine Identity

Using machine identity for automation and CI/CD:

```bash
# Required environment variables
export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID="your-client-id"
export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET="your-client-secret"
export INFISICAL_ENV="prod"  # or staging, dev
```

These are typically managed by direnv or mise for automatic loading.

## Secret Organization

### Current Folder Structure

```plain
Project: andromeda-orchestration-homelab (7b832220-24c0-45bc-a5f1-ce9794a31259)
├─ 📁 /apollo-13/
│  ├─ 📂 consul/
│  │  ├─ CONSUL_MASTER_TOKEN
│  │  └─ CONSUL_HTTP_TOKEN
│  ├─ 📂 nomad/
│  │  ├─ NOMAD_TOKEN
│  │  └─ NOMAD_ACL_TOKEN
│  ├─ 📂 vault/
│  │  ├─ VAULT_DEV_ROOT_TOKEN
│  │  └─ VAULT_RECOVERY_KEYS
│  └─ 📂 proxmox/
│     ├─ ANSIBLE_USERNAME
│     ├─ ANSIBLE_TOKEN_ID
│     ├─ 📂 doggos-homelab/
│     │  ├─ API_URL
│     │  └─ ANSIBLE_TOKEN_SECRET_DOGGOS
│     └─ 📂 og-homelab/
│        ├─ API_URL
│        └─ ANSIBLE_TOKEN_SECRET_OG
└─ 📁 /services/
    ├─ 📂 netbox/
    │  ├─ NETBOX_API_KEY
    │  └─ NETBOX_URL
    ├─ 📂 netdata/
    │  └─ NETDATA_API_KEY
    ├─ 📂 postgresql/
    │  ├─ POSTGRES_USER
    │  └─ POSTGRES_PASSWORD
    └─ 📂 powerdns/
       ├─ PDNS_API_KEY
       └─ PDNS_API_URL
```

## Usage Patterns

### Ansible Collection Parameters

The `infisical.vault.read_secrets` lookup uses these parameters:

```yaml
- universal_auth_client_id: Machine identity client ID
- universal_auth_client_secret: Machine identity client secret
- project_id: The Infisical project ID
- env_slug: Environment identifier (prod, staging, dev)
- path: Folder path (must include leading slash)
- secret_name: Specific secret key (optional - omit to get all secrets in folder)
```

### Inventory File Configuration

Example from `inventory/doggos-homelab/infisical.proxmox.yml`:

```yaml
plugin: community.general.proxmox
url: >-
  {{ (lookup('infisical.vault.read_secrets',
             universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
             universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
             project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
             env_slug='prod',
             path='/apollo-13/proxmox/doggos-homelab',
             secret_name='API_URL')).value }}
username: >-
  {{ (lookup('infisical.vault.read_secrets',
             universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
             universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
             project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
             env_slug='prod',
             path='/apollo-13/proxmox',
             secret_name='ANSIBLE_USERNAME')).value }}
```

### Playbook Usage Examples

#### Retrieve Single Secret

```yaml
- name: Get Consul master token
  set_fact:
    consul_token: >-
      {{ (lookup('infisical.vault.read_secrets',
                 universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
                 universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
                 project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
                 env_slug='prod',
                 path='/apollo-13/consul',
                 secret_name='CONSUL_MASTER_TOKEN')).value }}

- name: Get NetBox API key
  set_fact:
    netbox_token: >-
      {{ (lookup('infisical.vault.read_secrets',
                 universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
                 universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
                 project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
                 env_slug='staging',
                 path='/services/netbox',
                 secret_name='NETBOX_API_KEY')).value }}
```

#### Retrieve All Secrets in Folder

```yaml
- name: Get all Proxmox secrets for og-homelab
  set_fact:
    proxmox_secrets: >-
      {{ lookup('infisical.vault.read_secrets',
                universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
                universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
                project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
                env_slug='prod',
                path='/apollo-13/proxmox/og-homelab') }}

- name: Use specific values from the folder
  debug:
    msg: |
      Token Secret: {{ (proxmox_secrets | selectattr('key', 'equalto', 'ANSIBLE_TOKEN_SECRET_OG') | first).value }}
```

#### Environment-Aware Secret Retrieval

```yaml
vars:
  infisical_env: "{{ lookup('env', 'INFISICAL_ENV') | default('dev') }}"

tasks:
  - name: Get secret for current environment
    set_fact:
      api_token: >-
        {{ (lookup('infisical.vault.read_secrets',
                   universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
                   universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
                   project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
                   env_slug=infisical_env,
                   path='/services/netbox',
                   secret_name='NETBOX_API_KEY')).value }}
```

### CLI Workaround for Virtual Environment Issues

If you encounter "worker was found in a dead state" errors with Infisical lookups in virtual environments:

```bash
# Get token via CLI and use environment variable
export NETBOX_TOKEN=$(infisical run --env=staging --path="/services/netbox" -- printenv NETBOX_API_KEY)
ansible-playbook playbooks/infrastructure/netbox-playbook.yml
```

## Free vs Paid Features

### What's Available in Free Tier

The free tier is more generous than officially documented. All project types are available with most core features:

#### Available Features

- ✅ All project types: `secret-manager`, `cert-manager`, `ssh`, `kms`
- ✅ Dashboard, API, CLI, SDKs
- ✅ Kubernetes Operator & Infisical Agent
- ✅ All integrations (AWS, GitHub, Vercel, etc.)
- ✅ Secret references, overrides, and sharing
- ✅ CLI-based secret scanning
- ✅ Pre-commit hooks
- ✅ Self-hosting option
- ✅ Certificate management with Private CA (`cert-manager`)
- ✅ SSH certificate issuance (`ssh`)
- ✅ Key management and encryption (`kms`)

#### Free Tier Limits

- 5 users, 3 projects, 3 environments, 10 integrations
- No secret versioning or point-in-time recovery
- No RBAC or temporary access controls
- No automated secret rotation
- No continuous monitoring (CLI scanning only)
- Community support only

### What Requires Pro/Enterprise

- 💰 Secret versioning & point-in-time recovery (Pro)
- 💰 RBAC & temporary access (Pro)
- 💰 Secret rotation (Pro)
- 💰 SSH host groups within `ssh` project (Pro)
- 💰 Continuous secret monitoring (Pro)
- 💰 SAML SSO (Pro)
- 💰 Dynamic secrets (Enterprise)
- 💰 Approval workflows (Enterprise)
- 💰 KMIP protocol for KMS (Enterprise)

**Current Setup**: Using Free tier with `secret-manager` project type - sufficient for current homelab needs.

## Technical Implementation

### Setup Requirements

1. **Python Dependencies** (in pyproject.toml):

   ```toml
   [project.optional-dependencies]
   secrets = [
       "infisical-python>=2.2.7",
       "infisicalsdk>=0.1.0",
   ]
   ```

   Install with:

   ```bash
   uv sync --extra secrets
   ```

2. **Ansible Collection** (in requirements.yml):

   ```yaml
   collections:
     - name: infisical.vault
       version: ">=1.1.2"
   ```

3. **Environment Variables** (managed by direnv or mise):

   ```bash
   export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID="your-client-id"
   export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET="your-client-secret"
   export INFISICAL_ENV="prod"  # or staging, dev
   ```

## Testing and Verification

### Testing Commands

```bash
# Test inventory with current secrets
uv run ansible-inventory -i inventory/doggos-homelab/infisical.proxmox.yml --list

# Run demo playbook
uv run ansible-playbook playbooks/examples/infisical-demo.yml

# Test with different environment
INFISICAL_ENV=staging uv run ansible-playbook playbooks/site.yml

# Verify specific secret access
uv run ansible localhost -m debug -a "msg={{ lookup('infisical.vault.read_secrets',
    universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
    universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
    project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
    env_slug='prod',
    path='/apollo-13/consul',
    secret_name='CONSUL_MASTER_TOKEN') }}"
```

## Troubleshooting

### Common Issues

1. **"Folder not found" errors**
   - Folders must be created before use
   - Check exact path spelling (case-sensitive)
   - Verify folder exists in the correct environment
   - Ensure path includes leading slash

2. **Empty secret results**
   - Ensure `path` parameter includes leading slash
   - Verify secret exists with exact name (case-sensitive)
   - Check you're querying the correct environment

3. **Authentication failures**
   - Verify environment variables are set
   - Check machine identity has access to the environment/folder
   - Ensure client ID/secret are valid

4. **"Worker was found in a dead state" errors**
   - Known issue with virtual environments
   - Use CLI workaround (see above)
   - Consider using `infisical run` wrapper

## Best Practices

### Secret Naming

- Use UPPER_SNAKE_CASE for consistency
- Be descriptive: `API_TOKEN_SECRET` not just `TOKEN`
- Don't include environment in names (use Infisical environments)
- Group related secrets in folders

### Folder Organization

- Keep hierarchy shallow (3-4 levels max)
- Group by service/component
- Use consistent naming across environments
- Create folders before adding secrets

### Access Control

- Create separate machine identities for different services
- Grant minimal required permissions (folder-level)
- Use different environments for separation
- Document access patterns

### Security

- Never commit credentials
- Use environment variables for authentication
- Rotate machine identity credentials periodically
- Audit secret access regularly

## Migration Guide

### From 1Password or Other Solutions

#### Phase 1: Parallel Implementation

1. Set up Infisical alongside existing solution
2. Configure authentication (Universal Auth recommended)
3. Create project structure matching your needs
4. Enable sync with existing solution if available

#### Phase 2: Gradual Migration

1. Start with non-critical secrets
2. Update automation scripts to use Infisical
3. Validate access patterns and permissions
4. Document new procedures

#### Phase 3: Full Migration

1. Migrate remaining secrets
2. Update all references
3. Decommission old solution
4. Archive legacy documentation

### Migration Safety

- Test in dev environment first
- Keep backups of critical secrets
- Validate each phase before proceeding
- Don't delete old secrets until fully migrated

## Future Considerations

### Additional Project Types

Consider creating specialized projects for:

1. **Certificate Management (`cert-manager`)**
   - Project: `andromeda-orchestration-certificates`
   - Managing internal TLS certificates
   - ACME/Let's Encrypt integration
   - Certificate lifecycle management

2. **SSH Management (`ssh`)**
   - Project: `andromeda-orchestration-ssh`
   - Ephemeral SSH certificates
   - Replace static SSH keys
   - Centralized access control

3. **Key Management (`kms`)**
   - Project: `andromeda-orchestration-kms`
   - Database encryption keys
   - Backup encryption
   - Data-at-rest protection

### Integration with Vault

As the project has deployed HashiCorp Vault in production:

- Use Infisical for Ansible/repository secrets
- Use Vault for application/service secrets
- Consider sync between systems if needed
- Document clear boundaries between systems

## Migration Status

### Completed

- ✅ All Proxmox credentials migrated
- ✅ Consul tokens migrated
- ✅ Nomad tokens migrated
- ✅ Vault dev tokens migrated
- ✅ NetBox credentials added
- ✅ Folder structure organized
- ✅ Secrets replicated across environments
- ✅ Inventory files updated to use new paths
- ✅ 1Password Connect deprecated

### Pending

- ⏳ PowerDNS credentials (when fully deployed)
- ⏳ PostgreSQL production credentials

## Related Documentation

- [Secrets Management Comparison](./comparison.md) - Historical comparison document
- [Security Scanning Operations](../../operations/security-scanning.md) - Security scanning procedures
- [Security Standards](../../standards/security-standards.md) - Overall security practices
