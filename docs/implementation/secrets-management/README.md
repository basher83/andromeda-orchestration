# Secrets Management Documentation

This directory contains documentation for secrets management implementation using Infisical (primary) and legacy 1Password integration.

## Documents

### 🔑 [infisical-setup.md](infisical-setup.md)
Complete guide for Infisical setup and migration:
- Machine identity configuration
- Project and environment structure
- Secret organization patterns
- Ansible integration using `infisical.vault` collection
- Migration from 1Password

### 📊 [comparison.md](comparison.md)
Detailed comparison between secrets management solutions:
- 1Password Connect vs Infisical
- Feature comparison
- Security considerations
- Cost analysis
- Migration rationale

## Current Status

- ✅ **Infisical** - Primary secrets management (Active)
- ⚠️ **1Password** - Legacy, being phased out (Deprecated)

## Secret Organization

Current Infisical structure:
```
Production Environment
└── /apollo-13/
    ├── consul/          # Consul tokens and credentials
    ├── nomad/           # Nomad tokens
    ├── proxmox/         # Proxmox API credentials
    ├── ansible/         # Ansible-specific secrets
    └── powerdns/        # PowerDNS credentials
```

## Usage Examples

### In Inventory Files
```yaml
# inventory/og-homelab/infisical.proxmox.yml
plugin: community.general.proxmox
api_password: >-
  {{ lookup('infisical.vault.read_secrets',
            universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
            universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
            project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
            env_slug='prod',
            path='/apollo-13/proxmox',
            secret_name='PROXMOX_API_PASSWORD').value }}
```

### In Playbooks
```yaml
vars:
  consul_token: >-
    {{ lookup('infisical.vault.read_secrets',
              path='/apollo-13/consul',
              secret_name='CONSUL_MANAGEMENT_TOKEN').value }}
```

## Migration Status

- ✅ Proxmox credentials migrated
- ✅ Consul tokens migrated
- ✅ PowerDNS secrets implemented
- ⏳ Complete 1Password deprecation pending

## Related Resources

- **Example Playbooks**: [`../../../playbooks/examples/infisical-demo.yml`](../../../playbooks/examples/infisical-demo.yml)
- **Inventory Files**: [`../../../inventory/*/infisical.proxmox.yml`](../../../inventory/)
- **Archived 1Password Docs**: [`../../archive/`](../../archive/)

## Best Practices

1. Always use environment variables for Infisical authentication
2. Never commit secrets or machine identity credentials
3. Use descriptive secret names following the pattern: `SERVICE_COMPONENT_TYPE`
4. Organize secrets by service in folder structure
5. Document secret requirements in relevant playbooks