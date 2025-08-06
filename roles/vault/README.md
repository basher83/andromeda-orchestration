# Ansible Role: Vault

Deploy and configure HashiCorp Vault for secrets management, PKI, and encryption services.

## Overview

This role installs and configures HashiCorp Vault with support for both development and production modes. Based on research from production deployments including Skatteetaten/vagrant-hashistack and Deltamir/ansible-hashistack patterns.

## Requirements

- Ansible 2.15+
- Ubuntu 20.04/22.04, Debian 11/12, or RHEL/Rocky 8/9
- Systemd-based system
- For production: 3+ nodes for HA configuration

## Role Variables

### Essential Variables

```yaml
# Deployment mode
vault_mode: "dev"  # Options: dev, production

# Network configuration
vault_bind_address: "0.0.0.0"
vault_port: 8200
vault_cluster_port: 8201

# Storage backend (for production)
vault_storage_backend: "raft"  # Options: raft, consul, file

# Auto-unseal (for production)
vault_auto_unseal_enabled: false
vault_auto_unseal_type: "transit"  # Options: transit, awskms, azurekeyvault, gcpckms
```

See `defaults/main.yml` for all available variables.

## Dependencies

None required. Optionally integrates with:

- `consul` role for service discovery
- `nomad` role for workload integration

## Example Playbooks

### Development Mode

```yaml
- hosts: vault_servers
  become: true
  vars:
    vault_mode: "dev"
    vault_dev_root_token: "root"
    vault_ui_enabled: true
  roles:
    - vault
```

### Production Mode with Raft

```yaml
- hosts: vault_servers
  become: true
  vars:
    vault_mode: "production"
    vault_storage_backend: "raft"
    vault_raft_retry_join:
      - "http://vault-1.example.com:8200"
      - "http://vault-2.example.com:8200"
      - "http://vault-3.example.com:8200"
    vault_auto_unseal_enabled: true
    vault_auto_unseal_type: "transit"
    vault_auto_unseal_config:
      address: "http://vault-transit.example.com:8200"
      token: "{{ lookup('infisical.infisical.generic', '/apollo-13/vault/transit-token') }}"
      key_name: "autounseal"
  roles:
    - vault
```

## Storage Backends

### Raft (Recommended)

Integrated storage with no external dependencies:

```yaml
vault_storage_backend: "raft"
vault_raft_node_id: "{{ ansible_hostname }}"
vault_raft_retry_join:
  - "http://vault-1:8200"
  - "http://vault-2:8200"
```

### Consul

External storage using Consul:

```yaml
vault_storage_backend: "consul"
vault_consul_address: "127.0.0.1:8500"
vault_consul_path: "vault/"
vault_consul_token: "{{ consul_acl_token }}"
```

## Auto-Unseal Options

### Transit Secret Engine

Use another Vault instance for unsealing:

```yaml
vault_auto_unseal_type: "transit"
vault_auto_unseal_config:
  address: "http://vault-transit:8200"
  token: "s.xxxxx"
  key_name: "autounseal"
```

### Cloud KMS

AWS, Azure, or GCP key management:

```yaml
vault_auto_unseal_type: "awskms"
vault_auto_unseal_config:
  region: "us-east-1"
  kms_key_id: "arn:aws:kms:..."
```

## Nomad Integration

Enable workload identity for Nomad jobs:

```yaml
vault_nomad_integration_enabled: true
vault_nomad_jwt_auth_backend_path: "nomad"
```

## Security Considerations

### Development Mode

- ⚠️ **NOT for production use**
- Data stored in memory only
- No unsealing required
- Root token exposed

### Production Mode

- ✅ Persistent encrypted storage
- ✅ Unsealing required (manual or auto)
- ✅ TLS encryption supported
- ✅ Audit logging available

## Post-Deployment Steps

### Development Mode

```bash
export VAULT_ADDR='http://vault-server:8200'
export VAULT_TOKEN='root'
vault status
```

### Production Mode

1. Initialize Vault:

   ```bash
   vault operator init -key-shares=5 -key-threshold=3
   ```

2. Unseal Vault (if not using auto-unseal):

   ```bash
   vault operator unseal <key-1>
   vault operator unseal <key-2>
   vault operator unseal <key-3>
   ```

3. Login with root token:

   ```bash
   vault login <root-token>
   ```

4. Configure auth methods and policies

## Directory Structure

```
/opt/vault/           # Base directory
├── data/            # Storage (Raft/File backend)
└── tls/             # TLS certificates

/etc/vault.d/        # Configuration
├── vault.hcl        # Main configuration
└── policies/        # Vault policies

/var/log/vault/      # Logs and audit
```

## Monitoring

Prometheus metrics available at:

- `http://vault:8200/v1/sys/metrics` (requires auth)

Key metrics:

- `vault.core.unsealed` - Seal status
- `vault.token.count` - Active tokens
- `vault.runtime.alloc_bytes` - Memory usage

## Troubleshooting

### Vault is sealed

Check seal status:

```bash
vault status
```

Unseal manually:

```bash
vault operator unseal <key>
```

### Cannot connect to Vault

Verify service is running:

```bash
systemctl status vault
journalctl -u vault -f
```

Check network binding:

```bash
ss -tlnp | grep 8200
```

### Permission denied errors

Ensure capabilities are set:

```bash
getcap /usr/local/bin/vault
# Should show: cap_ipc_lock+ep
```

## License

MIT

## Author Information

Created for andromeda-orchestration based on HashiCorp best practices and community patterns.
