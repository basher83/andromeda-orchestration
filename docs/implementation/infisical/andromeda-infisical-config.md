# Andromeda Orchestration Infisical Configuration

This document contains project-specific Infisical configuration details for the andromeda-orchestration-homelab project.

## Project Details

- **Project Name**: andromeda-orchestration-homelab
- **Project ID**: `7b832220-24c0-45bc-a5f1-ce9794a31259`
- **Project Type**: `secret-manager`
- **Environments**: dev, staging, prod

## Current Secret Organization

```plain
Project: andromeda-orchestration-homelab (7b832220-24c0-45bc-a5f1-ce9794a31259)
├─ 📁 /apollo-13/
│  ├─ 📂 proxmox/ (shared credentials at this level)
│  │  ├─ 🌍 dev, prod, staging
│  │  │  🔑 ANSIBLE_TOKEN_ID
│  │  │  🔑 ANSIBLE_USERNAME
│  │  ├─ 📂 og-homelab/
│  │  │  └─ 🌍 dev, prod, staging
│  │  │     🔑 ANSIBLE_TOKEN_SECRET_OG
│  │  │     🔑 API_URL
│  │  └─ 📂 doggos-homelab/
│  │     └─ 🌍 dev, prod, staging
│  │        🔑 ANSIBLE_TOKEN_SECRET_DOGGOS
│  │        🔑 API_URL
│  │
│  ├─ 📂 consul/
│  │  └─ 🌍 dev, prod, staging
│  │     🔑 CONSUL_MASTER_TOKEN
│  │
│  ├─ 📂 nomad/
│  │  └─ 🌍 dev, prod, staging
│  │     🔑 MANAGEMENT_TOKEN
│  │
│  └─ 📂 vault/
│     └─ 🌍 dev, prod, staging
│        🔑 VAULT_DEV_ROOT_TOKEN
│
└─ 📁 /services/
   ├─ 📂 netbox/
   │  └─ 🌍 dev, prod, staging
   │     🔑 NETBOX_USERNAME
   │     🔑 NETBOX_API_KEY
   └─ 📂 powerdns/ (ready for secrets)
```

## Authentication

Using Universal Auth with machine identity:
- `INFISICAL_UNIVERSAL_AUTH_CLIENT_ID` - Set via environment
- `INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET` - Set via environment

## Usage Patterns

### Inventory Files

Example from `inventory/doggos-homelab/infisical.proxmox.yml`:

```yaml
plugin: community.general.proxmox
api_host: >-
  {{ (lookup('infisical.vault.read_secrets',
             universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
             universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
             project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
             env_slug='prod',
             path='/apollo-13/proxmox/doggos-homelab',
             secret_name='API_URL')).value }}
api_user: >-
  {{ (lookup('infisical.vault.read_secrets',
             universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
             universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
             project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
             env_slug='prod',
             path='/apollo-13/proxmox',
             secret_name='ANSIBLE_USERNAME')).value }}
```

### Playbook Usage

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
```

## Testing Commands

```bash
# Test inventory with current secrets
uv run ansible-inventory -i inventory/doggos-homelab/infisical.proxmox.yml --list

# Run demo playbook
uv run ansible-playbook playbooks/examples/infisical-demo.yml

# Test with different environment
INFISICAL_ENV=staging uv run ansible-playbook playbooks/site.yml
```

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

### Pending
- ⏳ PowerDNS credentials (when deployed)
- ⏳ Complete deprecation of 1Password files

## Future Considerations

### Certificate Management
- Plan to create separate `cert-manager` type project: `andromeda-orchestration-certificates`
- Will handle internal PKI and TLS certificates
- Supports ACME/Let's Encrypt integration

### SSH Management
- Could create `ssh` type project for ephemeral SSH certificates
- Would replace static SSH keys with short-lived certificates
- Free tier supports basic features; host groups require Pro

### Key Management
- If encryption-at-rest is needed, create `kms` type project
- Would handle database encryption keys, backup encryption
- Core features available in free tier

## Related Documentation

- [General Infisical Setup Guide](./infisical-setup.md)
- [Secrets Management Comparison](./comparison.md)
- [Project README](./README.md)
