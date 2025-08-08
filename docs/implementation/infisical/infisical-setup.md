# Infisical Setup and Migration Guide

This document provides accurate guidance for using Infisical with the andromeda-orchestration project, including the current state and migration plan to a properly organized secret structure.

## Quick Reference: Free vs Paid Features

### What's Available in Free Tier

- ✅ Basic secret management (`secret-manager` project type)
- ✅ Certificate management (`cert-manager` project type)\*
  - ✅ Private Certificate Authority (CA)
  - ✅ Certificate issuance and management
  - ✅ Certificate templates
  - ❓ Some advanced PKI features may require Pro
- ✅ SSH certificate management (`ssh` project type)\*
  - ✅ Certificate Authorities (CA)
  - ✅ SSH hosts registration
  - ✅ SSH certificate issuance
  - ❌ SSH host groups (confirmed requires Pro)
- ✅ Key Management System (`kms` project type)\*
  - ✅ Cryptographic key management
  - ✅ Encrypt/decrypt operations
  - ✅ Key creation and rotation
  - ❌ KMIP protocol support (requires Enterprise)
- ✅ Dashboard, API, CLI, SDKs
- ✅ Kubernetes Operator & Infisical Agent
- ✅ All integrations (AWS, GitHub, Vercel, etc.)
- ✅ Secret references, overrides, and sharing
- ✅ CLI-based secret scanning
- ✅ Pre-commit hooks
- ✅ Self-hosting option
- ❌ Limited to: 5 users, 3 projects, 3 environments, 10 integrations

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

\*Note: Based on actual user experience, `cert-manager`, `ssh`, and `kms` project types are all available in the free tier with most core features accessible. The only confirmed limitations are SSH host groups (Pro) and KMIP protocol (Enterprise). The official pricing documentation may not reflect the current generous free tier limits.

**Current andromeda-orchestration Setup**: Using Free tier with `secret-manager` project type - sufficient for current needs.

## How Infisical Actually Works

### Core Concepts

1. **Projects**: Top-level container for all secrets
   - Must specify project type when creating
   - Each project has a unique ID
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

**Project-specific configuration**: See [andromeda-infisical-config.md](./andromeda-infisical-config.md) for this project's setup.

### Project Types

Infisical supports 5 different project types, each optimized for specific use cases:

1. **`secret-manager`** (Default and most common) - **FREE**

   - Traditional secret management for application configs, API keys, database credentials
   - Full feature set: versioning (Pro), rotation (Pro), dynamic secrets (Enterprise), references (Free)
   - Best for: General application secrets, environment variables
   - **This is what we're using for andromeda-orchestration-homelab**

2. **`cert-manager`** (FREE)

   - Certificate management with Private Certificate Authority (CA)
   - Issue and manage X.509 certificates
   - Certificate lifecycle management with revocation support
   - Best for: Internal PKI, TLS certificates for services
   - Note: Confirmed available in free tier based on user testing

3. **`kms`** (Key Management System) (FREE)

   - Cryptographic key management
   - Encrypt/decrypt operations
   - Key rotation and versioning
   - KMIP protocol support (Enterprise only)
   - Best for: Data encryption keys, cryptographic operations
   - Note: Core KMS features confirmed available in free tier

4. **`ssh`** (FREE with limitations)

   - SSH certificate management
   - Issue ephemeral SSH certificates for secure access
   - Certificate Authorities (CA) setup
   - SSH hosts registration and management
   - **Pro features**: SSH host groups for bulk management
   - Best for: Managing SSH access to infrastructure

5. **`secret-scanning`** - **FREE** (CLI tool only)
   - Scan repositories and codebases for exposed secrets
   - Detect 140+ secret types
   - Integration with CI/CD pipelines
   - Best for: Security scanning and secret leak prevention
   - Note: Continuous monitoring requires Pro plan

**Important**: Project type is set during creation and cannot be changed. Choose based on primary use case.

### Free Tier Capabilities

**Important**: Based on actual user testing, Infisical's free tier is more generous than officially documented. All project types (`secret-manager`, `cert-manager`, `ssh`, `kms`) are available in the free tier with most core features accessible.

#### Free Tier Limits

- 5 users, 3 projects, 3 environments, 10 integrations
- No secret versioning or point-in-time recovery
- No RBAC or temporary access controls
- No automated secret rotation
- No continuous monitoring (CLI scanning only)
- Community support only

#### Available in Free Tier

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

#### Confirmed Pro/Enterprise Requirements

- 💰 SSH host groups within `ssh` project (Pro)
- 💰 KMIP protocol for KMS (Enterprise)
- 💰 Secret versioning & rotation (Pro)
- 💰 RBAC & temporary access (Pro)
- 💰 Continuous secret monitoring (Pro)
- 💰 Dynamic secrets (Enterprise)
- 💰 Approval workflows (Enterprise)

**Note**: The Free tier typically covers most homelab and small team needs.

### Ansible Collection Parameters

The `infisical.vault.read_secrets` lookup uses these parameters:

```yaml
- universal_auth_client_id: Machine identity client ID
- universal_auth_client_secret: Machine identity client secret
- project_id: The Infisical project ID
- env_slug: Environment identifier (prod, staging, dev)
- path: Folder path (default is "/")
- secret_name: Specific secret key (optional - omit to get all secrets in folder)
```

## Project Configuration

For project-specific configuration including secret organization, authentication setup, and current usage patterns, see:
- [andromeda-infisical-config.md](./andromeda-infisical-config.md)

## Migration Guide

For organizations migrating from other secret management solutions:

### Phase 1: Parallel Implementation
1. Set up Infisical alongside existing solution
2. Configure authentication (Universal Auth recommended)
3. Create project structure matching your needs
4. Enable sync with existing solution if available (e.g., 1Password sync)

### Phase 2: Gradual Migration
1. Start with non-critical secrets
2. Update automation scripts to use Infisical
3. Validate access patterns and permissions
4. Document new procedures

### Phase 3: Full Migration
1. Migrate remaining secrets
2. Update all references
3. Decommission old solution
4. Archive legacy documentation

### Environment Separation

Implement proper environment isolation:

```yaml
vars:
  infisical_env: "{{ lookup('env', 'INFISICAL_ENV') | default('dev') }}"

tasks:
  - name: Get secret for current environment
    set_fact:
      api_token: >-
        {{ (lookup('infisical.vault.read_secrets',
                   env_slug=infisical_env,
                   path='/backend',
                   secret_name='API_TOKEN')).value }}
```

## Technical Implementation

### Setup Requirements

1. **Python Dependencies** (in pyproject.toml):

   ```bash
   uv pip install infisical-python infisicalsdk
   ```

2. **Ansible Collection** (in requirements.yml):

   ```yaml
   collections:
     - name: infisical.vault
   ```
3. **Environment Variables** (managed by direnv):

   ```bash
   export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID="your-client-id"
   export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET="your-client-secret"
   export INFISICAL_ENV="prod"  # or staging, dev
   ```

### Usage Patterns

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
                 secret_name='MASTER_TOKEN')).value }}

- name: Get Proxmox API credentials
  set_fact:
    proxmox_api_token: >-
      {{ (lookup('infisical.vault.read_secrets',
                 universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
                 universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
                 project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
                 env_slug='prod',
                 path='/apollo-13/proxmox/og-homelab',
                 secret_name='ANSIBLE_TOKEN_SECRET_OG')).value }}
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
      # Note: ANSIBLE_USERNAME and ANSIBLE_TOKEN_ID are in parent /apollo-13/proxmox/ folder
```

### Testing Commands

```bash
# Test inventory with current secrets
uv run ansible-inventory -i inventory/doggos-homelab/infisical.proxmox.yml --list

# Run demo playbook
uv run ansible-playbook playbooks/examples/infisical-demo.yml

# Test with different environment
INFISICAL_ENV=staging uv run ansible-playbook playbooks/site.yml
```


## Troubleshooting

### Common Issues

1. **"Folder not found" errors**

   - Folders must be created before use
   - Check exact path spelling (case-sensitive)
   - Verify folder exists in the correct environment

2. **Empty secret results**

   - Ensure `path` parameter includes leading and trailing slashes
   - Verify secret exists with exact name (case-sensitive)
   - Check you're querying the correct environment

3. **Authentication failures**
   - Verify environment variables are set
   - Check machine identity has access to the environment/folder
   - Ensure client ID/secret are valid

## Best Practices

1. **Secret Naming**
   - Use UPPER_SNAKE_CASE for consistency
   - Be descriptive: `API_TOKEN_SECRET` not just `TOKEN`
   - Don't include environment in names (use Infisical environments)

2. **Folder Organization**

   - Keep hierarchy shallow (3-4 levels max)
   - Group by service/component
   - Use consistent naming across environments

3. **Access Control**
   - Create separate machine identities for different services
   - Grant minimal required permissions (RBAC requires Pro)
   - Use folder-level access controls
   - Temporary access requires Pro tier

4. **Migration Safety**
   - Test in dev environment first
   - Keep backups of critical secrets
   - Validate each phase before proceeding
   - Don't delete old secrets until fully migrated

## Evaluating Additional Project Types

### Beyond Secret Management

Infisical offers specialized project types for different security needs:

1. **Certificate Management (`cert-manager`)** (FREE)
   - Managing internal TLS certificates
   - Automated certificate lifecycle
   - ACME/Let's Encrypt support
   - Consider for: Internal PKI, service certificates

2. **SSH Management (`ssh`)** (FREE with limitations)
   - Ephemeral SSH certificates
   - Centralized access control
   - Audit trails
   - Pro feature: Host groups for bulk management

3. **Key Management (`kms`)** (FREE)
   - Encryption key management
   - Data-at-rest encryption
   - Key rotation policies
   - Enterprise feature: KMIP protocol

4. **Secret Scanning (`secret-scanning`)** (FREE)
   - Repository scanning
   - Pre-commit hooks
   - CI/CD integration
   - Pro feature: Continuous monitoring

### PKI and Certificate Considerations

When choosing between Infisical's cert-manager and other PKI solutions (like Vault):

**Infisical cert-manager**:
- ✅ Integrated with existing secret management
- ✅ ACME/Let's Encrypt automation
- ✅ Simple certificate lifecycle management
- ✅ Good for internal service certificates
- ❌ Less flexible than full PKI solutions

**HashiCorp Vault PKI**:
- ✅ Full-featured PKI engine
- ✅ Complex certificate hierarchies
- ✅ Custom certificate policies
- ✅ Integration with existing Vault deployment
- ❌ Requires separate infrastructure

**Recommendation**: Start with Infisical cert-manager for simplicity, evaluate Vault PKI for complex
requirements.

## Security Scanning

For comprehensive security scanning procedures including:
- Infisical CLI secret detection
- KICS infrastructure security scanning
- Pre-commit hook integration
- CI/CD security workflows

See: [Security Scanning Operations](../../operations/security-scanning.md)

## Related Documentation

- [Project-specific Configuration](./andromeda-infisical-config.md) - Current project setup and usage
- [Secrets Management Comparison](./comparison.md) - Detailed comparison of 1Password vs Infisical
- [Security Scanning Operations](../../operations/security-scanning.md) - Security scanning procedures
- [1Password Integration (Archived)](../../archive/1password-integration.md) - Legacy secret management
- [Security Standards](../../standards/security-standards.md) - Overall security practices
