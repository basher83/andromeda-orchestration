# Infisical Setup and Migration Guide

This document provides accurate guidance for using Infisical with the NetBox-Ansible project, including the current state and migration plan to a properly organized secret structure.

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

**Current NetBox-Ansible Setup**: Using Free tier with `secret-manager` project type - sufficient for current needs.

## How Infisical Actually Works

### Core Concepts

1. **Projects**: Top-level container for all secrets
   - Project ID: `7b832220-24c0-45bc-a5f1-ce9794a31259` (netbox-ansible-homelab)
   - Project Type: Must be specified when creating a project
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

### Project Types

Infisical supports 5 different project types, each optimized for specific use cases:

1. **`secret-manager`** (Default and most common) - **FREE**

   - Traditional secret management for application configs, API keys, database credentials
   - Full feature set: versioning (Pro), rotation (Pro), dynamic secrets (Enterprise), references (Free)
   - Best for: General application secrets, environment variables
   - **This is what we're using for netbox-ansible-homelab**

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

**Note**: For our current NetBox-Ansible setup, the Free tier covers all current and anticipated needs.

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

## Current State

### Authentication

- Using Universal Auth with machine identity
- Credentials stored in environment variables:
  - `INFISICAL_UNIVERSAL_AUTH_CLIENT_ID`
  - `INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET`

### Secret Organization

Secrets have been organized into a hierarchical folder structure (keeping original secret names):

```plain
Project: netbox-ansible-homelab (7b832220-24c0-45bc-a5f1-ce9794a31259)
├─ 📁 /apollo-13/
│  ├─ 📂 proxmox/ (shared credentials at this level)
│  │  ├─ 🌍 dev, prod, staging
│  │  │  🔑 ANSIBLE_TOKEN_ID
│  │  │  🔑 ANSIBLE_USERNAME
│  │  ├─ 📂 og-homelab/
│  │  │  └─ 🌍 dev, prod, staging
│  │  │     🔑 ANSIBLE_TOKEN_SECRET_OG
│  │  └─ 📂 doggos-homelab/
│  │     └─ 🌍 dev, prod, staging
│  │        🔑 ANSIBLE_TOKEN_SECRET_DOGGOS
│  │
│  └─ 📂 consul/
│     └─ 🌍 dev, prod, staging
│        🔑 CONSUL_MASTER_TOKEN
│
└─ 📁 /services/
   ├─ 📂 netbox/ (ready for secrets)
   └─ 📂 powerdns/ (ready for secrets)
```

Note: Certificates will be managed in a separate `cert-manager` type project for proper PKI functionality.

### Current Usage

Example from inventory file:

```yaml
token_secret: >-
  {{ (lookup('infisical.vault.read_secrets',
             universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
             universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
             project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
             env_slug='prod',
             path='/apollo-13/proxmox/doggos-homelab',
             secret_name='ANSIBLE_TOKEN_SECRET_DOGGOS')).value }}
```

## Migration Status

### ✅ Phase 1: Folder Structure (COMPLETED)

The proper folder structure has been created in Infisical:

```
Project: netbox-ansible-homelab
├── Environment: prod
│   ├── /apollo-13/
│   │   ├── /proxmox/
│   │   │   ├── /og-homelab/
│   │   │   └── /doggos-homelab/
│   │   ├── /consul/
│   │   └── /nomad/
│   ├── /services/
│   │   ├── /netbox/
│   │   └── /powerdns/
│   └── /certificates/
├── Environment: staging
│   └── [same structure as prod]
└── Environment: dev
    └── [same structure as prod]
```

### ✅ Phase 2: Secret Organization (MOSTLY COMPLETE)

Secrets have been organized into folders and replicated across environments:

| Secret Name                  | Location                            | Environments      | Status | Notes                   |
| ---------------------------- | ----------------------------------- | ----------------- | ------ | ----------------------- |
| ANSIBLE_TOKEN_ID             | /apollo-13/proxmox/                 | dev, prod, staging| ✅     | Shared between clusters |
| ANSIBLE_USERNAME             | /apollo-13/proxmox/                 | dev, prod, staging| ✅     | Shared between clusters |
| ANSIBLE_TOKEN_SECRET_OG      | /apollo-13/proxmox/og-homelab/      | dev, prod, staging| ✅     | Cluster-specific        |
| ANSIBLE_TOKEN_SECRET_DOGGOS  | /apollo-13/proxmox/doggos-homelab/  | dev, prod, staging| ✅     | Cluster-specific        |
| CONSUL_MASTER_TOKEN          | /apollo-13/consul/                  | dev, prod, staging| ✅     | Kept original name      |
| API_URL (og-homelab)         | -                                   | -                 | ❌     | Need to add             |
| API_URL (doggos-homelab)     | -                                   | -                 | ❌     | Need to add             |
| NOMAD tokens                 | -                                   | -                 | ❌     | Need to create folder   |

### Phase 3: Update Ansible Code (IN PROGRESS)

Update inventory files to use the new organized folder structure:

```yaml
# inventory/doggos-homelab/infisical.proxmox.yml
plugin: community.general.proxmox
api_host: "{{ proxmox_api_host }}"
api_user: >-
  {{ (lookup('infisical.vault.read_secrets',
             universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
             universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
             project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
             env_slug='prod',
             path='/apollo-13/proxmox',
             secret_name='ANSIBLE_USERNAME')).value }}
api_token_id: >-
  {{ (lookup('infisical.vault.read_secrets',
             universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
             universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
             project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
             env_slug='prod',
             path='/apollo-13/proxmox',
             secret_name='ANSIBLE_TOKEN_ID')).value }}
api_token_secret: >-
  {{ (lookup('infisical.vault.read_secrets',
             universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
             universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
             project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
             env_slug='prod',
             path='/apollo-13/proxmox/doggos-homelab',
             secret_name='ANSIBLE_TOKEN_SECRET_DOGGOS')).value }}
```

### Phase 4: Implement Environment Separation

1. Clone secrets from `prod` to `staging` and `dev` environments
2. Update values as appropriate for each environment
3. Modify playbooks to use environment-specific lookups:

```yaml
vars:
  infisical_env: "{{ lookup('env', 'INFISICAL_ENV') | default('dev') }}"

tasks:
  - name: Get secret for current environment
    set_fact:
      api_token: >-
        {{ (lookup('infisical.vault.read_secrets',
                   env_slug=infisical_env,
                   path='/apollo-13/proxmox/og-homelab',
                   secret_name='API_TOKEN_SECRET')).value }}
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

## Migration Checklist

### ✅ Completed
- [x] Create folder structure in Infisical UI/API
- [x] Organize secrets into folders (keeping original names):
  - [x] Proxmox shared credentials in `/apollo-13/proxmox/`
  - [x] Cluster-specific tokens in `/apollo-13/proxmox/{cluster}/`
  - [x] Consul tokens in `/apollo-13/consul/`
- [x] Replicate secrets across all environments (dev, prod, staging)
- [x] Create `/services/` structure with netbox and powerdns folders

### 🔄 In Progress
- [ ] Update inventory files with new paths
  - [ ] `inventory/og-homelab/infisical.proxmox.yml`
  - [ ] `inventory/doggos-homelab/infisical.proxmox.yml`
- [ ] Update playbooks to use new paths
  - [ ] Consul playbooks
  - [ ] Nomad playbooks
  - [ ] Infrastructure playbooks

### 📋 To Do
- [ ] Add missing secrets:
  - [ ] API_URL for each Proxmox cluster (in all environments)
  - [ ] Create `/apollo-13/nomad/` folder and add MANAGEMENT_TOKEN
- [ ] Add service secrets:
  - [ ] NetBox API credentials in `/services/netbox/`
  - [ ] PowerDNS credentials in `/services/powerdns/`
- [ ] Test inventory connections with new paths
- [ ] Implement environment-aware lookups
- [ ] Create separate `cert-manager` project for PKI/certificates
- [ ] Consider renaming secrets for consistency (optional future task)

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

### Current Setup

- Using `secret-manager` type for general secrets management
- Covers all current needs: API tokens, credentials, configuration values

### Future Considerations

1. **Certificate Management (`cert-manager`)** (FREE) - **PLANNED**

   - **Use Case**: Managing internal TLS certificates for services
   - **Example**: PowerDNS API certificates, internal service-to-service TLS, Proxmox CA certificates
   - **Benefits**: Automated certificate lifecycle, revocation support, proper PKI infrastructure
   - **Implementation**: Will create separate project named `netbox-ansible-certificates`
   - **Status**: Planned as separate project to keep concerns separated
   - **Cost**: Available in free tier (confirmed through testing)

2. **SSH Management (`ssh`)** (FREE with Pro features)

   - **Use Case**: Managing SSH access to Proxmox nodes and VMs
   - **Current State**: Using traditional SSH keys
   - **Free Features**: CA setup, host registration, certificate issuance
   - **Pro Features**: Host groups for bulk management
   - **Benefits**: Ephemeral certificates, centralized access control, audit trails
   - **Implementation**: Can start with free features, upgrade for host groups if needed
   - **Cost**: Basic features available free, host groups require Pro

3. **Key Management (`kms`)** (FREE)

   - **Use Case**: If we need to encrypt sensitive data at rest
   - **Example**: Encrypting backups, database encryption keys
   - **Benefits**: Centralized key management, rotation policies
   - **Free Features**: Key creation, encryption/decryption, basic key rotation
   - **Enterprise Features**: KMIP protocol support
   - **Implementation**: Separate project for cryptographic operations
   - **Cost**: Core features available free, KMIP requires Enterprise

4. **Secret Scanning (`secret-scanning`)** - **FREE**
   - **Use Case**: Scanning this repository and related codebases
   - **Benefits**: Prevent accidental secret commits
   - **Implementation**: Integrate with CI/CD pipeline
   - **Note**: CLI scanning is free, continuous monitoring requires Pro

### Recommendation

- Continue with `secret-manager` for current needs (Free tier sufficient)
- Consider `cert-manager` project when implementing internal PKI (Phase 2 of DNS/IPAM plan) - available in free tier
- Evaluate `ssh` project type if moving away from static SSH keys - available in free tier (host groups require Pro)
- `secret-scanning` can be implemented immediately as a separate project for security (Free CLI tool, continuous monitoring requires Pro)

## Secret Scanning Project Configuration

**Note**: The following features are available based on your subscription:

- **Free**: CLI-based scanning, pre-commit hooks, manual scans
- **Pro**: Continuous monitoring, automated remediation, alerting

### Recommended Setup for `netbox-ansible-scanning` Project

1. **Create Secret Scanning Project** (Free)

   ```bash
   # Project details
   Name: netbox-ansible-scanning
   Type: secret-scanning
   Description: Secret leak detection for NetBox-Ansible infrastructure code
   ```

2. **Configure Scanning Targets** (Pro - continuous monitoring)

   ```yaml
   repositories:
     - url: https://github.com/yourusername/netbox-ansible
       branch: main
       scan_frequency: on_push # Scan on every push (Pro feature)

   local_paths:
     - /ansible/playbooks/
     - /ansible/inventory/
     - /terraform/

   exclude_patterns:
     - "*.tfstate"
     - "*.tfstate.backup"
     - ".env.example"
     - "docs/examples/*"
   ```

3. **Secret Detection Rules**

   ```yaml
   detection_rules:
     # Standard patterns (140+ built-in)
     - type: api_keys
     - type: private_keys
     - type: passwords
     - type: tokens

     # Custom patterns for your infrastructure
     custom_patterns:
       - name: "Proxmox API Token"
         pattern: "PVEAPIToken=.*"
         severity: high

       - name: "Consul Token"
         pattern: "CONSUL_.*_TOKEN=.*"
         severity: high

       - name: "NetBox Token"
         pattern: "NETBOX_TOKEN=.*"
         severity: high
   ```

4. **Integration with CI/CD**

   ```yaml
   # .github/workflows/secret-scan.yml
   name: Secret Scanning
   on: [push, pull_request]

   jobs:
     scan:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4

         - name: Run Infisical Secret Scan
           uses: Infisical/infisical-scan-action@v1
           with:
             client-id: ${{ secrets.INFISICAL_CLIENT_ID }}
             client-secret: ${{ secrets.INFISICAL_CLIENT_SECRET }}
             project-id: <scanning-project-id>
             fail-on-finding: true
   ```

5. **Pre-commit Hook Configuration** (Free)

   ```yaml
   # .pre-commit-config.yaml
   repos:
     - repo: local
       hooks:
         - id: infisical-scan
           name: Infisical Secret Scan
           entry: infisical scan
           language: system
           pass_filenames: false
           always_run: true
   ```

6. **Alerting Configuration** (Pro)

   ```yaml
   alerts:
     channels:
       - type: email
         recipients:
           - security@team.com
         on_events:
           - secret_detected
           - high_severity_finding

       - type: slack
         webhook: <slack-webhook-url>
         channel: "#security-alerts"
         on_events:
           - secret_detected

   thresholds:
     auto_block_push: true # Block git push if secrets detected
     severity_threshold: medium # Alert on medium+ severity
   ```

7. **Remediation Workflow** (Pro)

   ```yaml
   remediation:
     auto_actions:
       - rotate_affected_secrets: true # Requires Pro for rotation
       - create_incident_ticket: true
       - notify_secret_owner: true

     quarantine:
       - move_to_draft_pr: true
       - require_security_review: true
   ```

### Implementation Steps

1. **Create the Secret Scanning Project** (Free)

   ```bash
   # Using Infisical CLI
   infisical project create \
     --name "netbox-ansible-scanning" \
     --type "secret-scanning"
   ```

2. **Configure Repository Integration** (Pro for continuous monitoring)

   - Connect GitHub repository (Pro)
   - Set up webhook for real-time scanning (Pro)
   - Configure branch protection rules (Pro)
   - Alternative: Use CLI for manual scans (Free)

3. **Install Local Tools** (Free)

   ```bash
   # Install Infisical CLI
   brew install infisical/get-cli/infisical

   # Install pre-commit
   pip install pre-commit
   pre-commit install
   ```

4. **Run Initial Scan** (Free)

   ```bash
   # Full repository scan
   infisical scan --deep

   # Scan with custom config
   infisical scan --config .infisical-scan.yml
   ```

### Best Practices for Secret Scanning

1. **Scan Early and Often**

   - Enable pre-commit hooks
   - Scan in CI/CD pipeline
   - Regular scheduled scans

2. **Custom Patterns**

   - Define patterns specific to your infrastructure
   - Include vendor-specific formats
   - Update patterns as new services are added

3. **False Positive Management**

   ```yaml
   # .infisical-scan-ignore
   # Ignore specific files
   docs/examples/sample-config.yml

   # Ignore specific patterns
   pattern:EXAMPLE_.*_TOKEN

   # Ignore specific findings by ID
   finding:abc123def456
   ```

4. **Response Plan**

   - Document incident response procedures
   - Automate secret rotation where possible
   - Track remediation metrics

5. **Training**
   - Educate team on secure coding practices
   - Regular security awareness sessions
   - Share scanning reports and trends
