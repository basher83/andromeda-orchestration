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
vault_mode: "dev" # Options: dev, production

# Network configuration
vault_bind_address: "0.0.0.0"
vault_port: 8200
vault_cluster_port: 8201

# Storage backend (for production)
vault_storage_backend: "raft" # Options: raft, consul, file

# Auto-unseal (for production)
vault_auto_unseal_enabled: false
vault_auto_unseal_type: "transit" # Options: transit, awskms, azurekeyvault, gcpckms
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

## Infrastructure Lessons Learned

This section documents key learnings from implementing complex infrastructure patterns, particularly around Ansible role usage and HashiCorp Vault deployment.

### Ansible Role Best Practices

#### 🎯 **Leverage Role Templates, Don't Manually Create Configs**

**❌ Anti-pattern**: Manually creating configuration files

```bash
# DON'T DO THIS
cat > /tmp/vault-config.hcl << 'EOF'
# Manual config creation
seal "transit" {
  address = "http://vault-master:8200"
  token = "hardcoded-token"
}
EOF
ansible -m copy -a "src=/tmp/vault-config.hcl dest=/etc/vault.d/vault.hcl" target_host
```

**✅ Best Practice**: Configure role variables and let templates generate configs

```yaml
# In inventory/host_vars/target_host.yml
vault_auto_unseal_enabled: true
vault_auto_unseal_type: "transit"
vault_auto_unseal_config:
  address: "http://192.168.10.30:8200"
  token: "{{ lookup('infisical.vault.read_secrets', project_id='...', env_slug='prod', path='/vault', secret_name='TRANSIT_TOKEN').value }}"
  key_name: "autounseal"
  mount_path: "transit/"

vault_raft_retry_join:
  - "http://192.168.10.31:8200" # Leader node
```

**Why this matters:**

- **Consistency**: Role templates ensure standardized, validated configuration
- **Maintainability**: Variables are version-controlled and auditable
- **Security**: No hardcoded secrets in scripts
- **Flexibility**: Role handles HCL formatting, validation, and best practices

#### 📋 **Study Role Variable Structure**

Always examine `roles/{role}/defaults/main.yml` to understand expected variable formats:

```bash
# Study the role's expectations
cat roles/vault/defaults/main.yml | grep -A 10 "vault_auto_unseal_config"
```

**Key patterns:**

- Complex configs use dictionaries: `vault_auto_unseal_config.address` vs `vault_transit_address`
- Arrays for multiple values: `vault_raft_retry_join: []`
- Template variables match role expectations

#### 🏗️ **Infrastructure Architecture Patterns**

### HashiCorp Vault: Master + Production Cluster

```text
┌─────────────────┐    ┌─────────────────────────────────────┐
│ Master Vault    │    │ Production Vault Cluster           │
│ (Dev Mode)      │    │ (Raft HA Cluster)                  │
│                 │    │                                     │
│ • Transit Engine│◄──►│ • vault-prod-1-holly (Leader)      │
│ • Auto-unseal   │    │ • vault-prod-2-mable (Follower)    │
│ • Dev server    │    │ • vault-prod-3-lloyd (Follower)    │
│                 │    │                                     │
│ Status: ✅ Ready│    │ Status: ✅ Initialized & Unsealed │
└─────────────────┘    └─────────────────────────────────────┘
```

**Key Insights:**

- **Master vault runs in dev mode** for transit auto-unseal service
- **Production cluster uses raft storage** for HA and persistence
- **Separation of concerns**: Master provides unsealing, cluster provides storage
- **Network isolation**: Master and production nodes can be on different networks

#### 🔄 **Separation of Concerns in Playbooks**

**❌ Anti-pattern**: Monolithic playbooks doing everything

```yaml
# DON'T: Single playbook handling install, config, init, AND unseal
- name: Do Everything Vault
  tasks:
    - name: Install Vault
    - name: Configure Vault
    - name: Initialize Vault
    - name: Unseal Vault
    - name: Setup PKI
```

**✅ Best Practice**: Modular playbooks with clear responsibilities

```yaml
# DO: Separate concerns
playbooks/infrastructure/vault/
├── deploy-vault-prod.yml    # Deployment & configuration
├── init-vault-cluster.yml   # Initialization (run once)
├── unseal-vault.yml         # Unsealing status/reporting
└── validate-pki-roles.yml   # PKI configuration
```

**Benefits:**

- **Selective execution**: `ansible-playbook deploy-vault-prod.yml --tags vault-deploy`
- **Idempotency**: Can rerun deployment without re-initializing
- **Debugging**: Isolate issues to specific phases
- **Maintenance**: Update one concern without affecting others

#### 🔐 **Secure Credential Management**

**Always use lookups, never hardcode:**

```yaml
# ✅ GOOD: Lookup from secure store
vault_auto_unseal_config:
  token: "{{ lookup('infisical.vault.read_secrets', project_id='...', env_slug='prod', path='/vault', secret_name='TRANSIT_TOKEN').value }}"

# ❌ BAD: Hardcoded in variables
vault_transit_token: "s.xxxxx..." # Visible in logs, version control
```

#### 📊 **Testing & Validation Strategy**

**Test incrementally:**

1. **Connectivity**: `test-connectivity.yml --tags connectivity`
2. **Service status**: `test-connectivity.yml --tags services`
3. **Configuration**: Syntax validation + role templating
4. **Functionality**: Unseal status, cluster health
5. **Integration**: Full workflow testing

**Monitor with structured output:**

```yaml
- name: Display deployment summary
  debug:
    msg: |
      🏗️  Vault Production Node Deployed
      Node: {{ ansible_hostname }}
      Auto-unseal: {{ "✅ Enabled" if vault_auto_unseal_enabled else "❌ Disabled" }}
      Service: {{ "✅ Running" if service_status else "❌ Failed" }}
```

### Takeaways for Future Infrastructure Work

1. **Trust the role**: Enterprise Ansible roles encapsulate best practices - leverage their templates
2. **Variable structure matters**: Study `defaults/main.yml` to understand expected formats
3. **Separate concerns**: Different playbooks for different lifecycle phases
4. **Secure by default**: Never hardcode credentials, always use lookups
5. **Test incrementally**: Build confidence with progressive validation
6. **Document patterns**: Share learnings for team consistency

These patterns ensure maintainable, secure, and reliable infrastructure automation.

## Post-Deployment Steps

### Development Mode

```bash
export VAULT_ADDR='http://vault-server:8200'
export VAULT_TOKEN='root'
vault status
```

### Production Mode

1. **Initialize cluster** (once, on leader):

   ```bash
   uv run ansible-playbook playbooks/infrastructure/vault/init-vault-cluster.yml \
     -i inventory/environments/vault-cluster/production.yaml \
     -e target_hosts=vault-prod-1-holly
   ```

2. **Verify auto-unseal**:

   ```bash
   uv run ansible-playbook playbooks/infrastructure/vault/unseal-vault.yml \
     -i inventory/environments/vault-cluster/production.yaml \
     -e target_hosts=vault_production --tags report
   ```

3. **Configure PKI and policies**:

   ```bash
   uv run ansible-playbook playbooks/infrastructure/vault/validate-pki-roles.yml \
     -i inventory/environments/vault-cluster/production.yaml
   ```

## Directory Structure

```text
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
