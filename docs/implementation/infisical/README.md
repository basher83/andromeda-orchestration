# Infisical Secrets Management Documentation

This directory contains documentation for implementing and using Infisical as the secrets management solution for the andromeda-orchestration project.

## Primary Documentation

### 📖 [infisical-complete-guide.md](./infisical-complete-guide.md)

**Comprehensive single-source documentation** including:

- Project configuration and setup
- Authentication with Universal Auth
- Current secret organization
- Usage patterns and examples
- Free vs paid tier features
- Troubleshooting and best practices
- Migration guide and status

### 📊 [comparison.md](./comparison.md)

Detailed comparison between secrets management solutions:

- 1Password Connect vs Infisical
- Feature comparison
- Security considerations
- Cost analysis
- Migration rationale

## Current Status

- ✅ **Infisical** - Primary secrets management (Active)
- ✅ **Vault** - Production secrets for lab services (Active)
- ⚠️ **1Password** - Legacy, fully deprecated (Archived)

## Secret Organization

Current Infisical structure:

```text
Production Environment
├── /apollo-13/
│   ├── consul/          # Consul tokens and credentials
│   ├── nomad/           # Nomad tokens
│   ├── vault/           # Vault recovery keys and tokens
│   └── proxmox/         # Proxmox API credentials
│       ├── doggos-homelab/
│       └── og-homelab/
└── /services/
    ├── netbox/          # NetBox API credentials
    ├── postgresql/      # Database credentials
    └── powerdns/        # PowerDNS credentials
```

## Quick Usage Examples

### In Inventory Files

```yaml
# inventory/og-homelab/infisical.proxmox.yml
plugin: community.general.proxmox
url: >-
  {{ lookup('infisical.vault.read_secrets',
            universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
            universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
            project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
            env_slug='prod',
            path='/apollo-13/proxmox/og-homelab',
            secret_name='API_URL').value }}
```

### In Playbooks

```yaml
vars:
  consul_token: >-
    {{ lookup('infisical.vault.read_secrets',
              universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
              universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
              project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
              env_slug='prod',
              path='/apollo-13/consul',
              secret_name='CONSUL_MASTER_TOKEN').value }}
```

## Migration Status

- ✅ All Proxmox credentials migrated
- ✅ Consul tokens migrated
- ✅ Nomad tokens migrated
- ✅ Vault credentials migrated
- ✅ NetBox credentials added
- ✅ 1Password fully deprecated
- ⏳ PowerDNS production credentials (when fully deployed)

## Archive Note

Previous separate documentation files (`infisical-setup.md` and `andromeda-infisical-config.md`) have been consolidated into the complete guide above and archived at [`docs/archive/infisical/`](../../archive/infisical/).

## Related Resources

- **Example Playbooks**: [`../../../playbooks/examples/infisical-demo.yml`](../../../playbooks/examples/infisical-demo.yml)
- **Inventory Files**: [`../../../inventory/*/infisical.proxmox.yml`](../../../inventory/)
- **Archived Docs**: [`../../archive/infisical/`](../../archive/infisical/)

## Best Practices

1. Always use environment variables for Infisical authentication
2. Never commit secrets or machine identity credentials
3. Use descriptive secret names: `SERVICE_COMPONENT_TYPE`
4. Organize secrets by service in folder structure
5. Use Infisical for repository/automation secrets
6. Use Vault for application/service runtime secrets
