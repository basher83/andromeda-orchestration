# Consul ACL Token Management with 1Password

> **⚠️ DEPRECATED**: This project has migrated to Infisical for secrets management. See [infisical-setup-and-migration.md](infisical-setup-and-migration.md) for current documentation. This guide is retained for reference during the migration period.

## Overview

The Consul ACL master token has been securely stored in 1Password for use in Ansible automation.

## 1Password Item Details

- **Item Name**: `Consul ACL - doggos-homelab`
- **Vault**: `DevOps`
- **Category**: API Credential
- **Tags**: consul, ansible, api, doggos-homelab

## Fields Stored

- `url`: https://192.168.11.11:8500 (Consul API endpoint)
- `username`: master-token (identifier)
- `token`: The actual ACL token (concealed)
- `hostname`: consul.doggos-homelab
- `notesPlain`: Description of the token usage

## Usage in Ansible

### In Playbooks

```yaml
vars:
  consul_acl_token: "{{ lookup('community.general.onepassword', 'Consul ACL - doggos-homelab', field='token', vault='DevOps') }}"
```

### In Commands

```yaml
- name: Run Consul command with ACL
  ansible.builtin.command: consul members
  environment:
    CONSUL_HTTP_TOKEN: "{{ consul_acl_token }}"
```

### In API Calls

```yaml
- name: Call Consul API
  ansible.builtin.uri:
    url: "https://{{ consul_host }}:8500/v1/catalog/services"
    headers:
      X-Consul-Token: "{{ consul_acl_token }}"
    validate_certs: false
```

## Retrieving the Token via CLI

```bash
# Get the full token
op item get "Consul ACL - doggos-homelab" --vault DevOps --fields label=token --reveal

# Use in environment variable
export CONSUL_HTTP_TOKEN=$(op item get "Consul ACL - doggos-homelab" --vault DevOps --fields label=token --reveal)
```

## Security Considerations

1. Never commit the token to version control
2. Always use 1Password lookup in playbooks
3. Use `no_log: true` for tasks that display token values
4. Rotate tokens periodically
5. Create separate tokens for different automation use cases

## Related Files

- `/playbooks/examples/consul-with-1password.yml` - Example usage
- `/playbooks/assessment/consul-health-check-v2.yml` - Updated assessment using 1Password
