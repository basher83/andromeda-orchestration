# Vault Enhanced Deployment Strategy

Based on deep analysis of production implementations from Deltamir, Skatteetaten, and wescale repositories.

## Executive Summary

This enhanced strategy incorporates advanced patterns discovered through deepwiki analysis:

- **Deltamir**: Master Vault pattern with automated certificate/secret rotation via consul-template
- **Skatteetaten**: Three-tier ACL framework with centralized token management
- **wescale**: Production-grade snapshot/restore procedures with PKI auto-renewal

## Phase 0: Pre-Deployment Assessment

### Infrastructure Readiness Checklist

- [ ] DNS resolution verified for all Vault nodes
- [ ] Network connectivity between all nodes (ports 8200, 8201)
- [ ] Time synchronization (NTP) configured
- [ ] Storage provisioning for `/opt/vault` (minimum 10GB)
- [ ] Firewall rules configured for Vault ports
- [ ] SSH keypairs prepared for snapshot operations

## Phase 1: Development Exploration (Enhanced)

### 1.1 Dev Mode with Production Patterns

Deploy Vault in dev mode but with production-like patterns:

```yaml
# Enhanced dev mode configuration
vault_mode: "dev"
vault_dev_root_token: "{{ lookup('password', '/dev/null chars=ascii_letters,digits length=32') }}"
vault_ui_enabled: true

# Enable production-like features even in dev
vault_audit_enabled: true
vault_telemetry_enabled: true

# Pre-enable PKI for testing
vault_dev_pki_enabled: true
vault_pki_path: "/pki"
```

### 1.2 Three-Tier Policy Framework Setup

Implement Skatteetaten's policy model early:

```hcl
# admin-policy.hcl
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# producer-policy.hcl
path "secret/data/apps/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "auth/token/create" {
  capabilities = ["create", "update"]
}

# consumer-policy.hcl
path "secret/data/apps/*" {
  capabilities = ["read", "list"]
}
```

## Phase 2: PKI Infrastructure (New)

### 2.1 Three-Tier PKI Hierarchy

Implement Deltamir's PKI pattern:

```yaml
# PKI hierarchy configuration
vault_pki_hierarchy:
  root_ca:
    path: "hashistack/pki"
    ttl: "87600h" # 10 years
  intermediate_cas:
    consul:
      path: "hashistack/pki_int_consul"
      ttl: "43800h" # 5 years
    nomad:
      path: "hashistack/pki_int_nomad"
      ttl: "43800h" # 5 years
    vault:
      path: "hashistack/pki_int_vault"
      ttl: "43800h" # 5 years
```

### 2.2 Certificate Auto-Renewal System

Deploy wescale's auto-renewal pattern:

```bash
#!/bin/bash
# /usr/sbin/ansible-refresh-vault-cert
set -euo pipefail

CERT_PATH="/etc/ssl/private/vault.crt"
FORWARD_DELAY="+1w"

# Check certificate validity
if [ -f "$CERT_PATH" ]; then
  VALID_UNTIL=$(openssl x509 -enddate -noout -in "$CERT_PATH" | cut -d= -f2)
  VALID_SECONDS=$(date -d "$VALID_UNTIL" +%s)
  FORWARD_SECONDS=$(date -d "$FORWARD_DELAY" +%s)

  if [ $VALID_SECONDS -gt $FORWARD_SECONDS ]; then
    echo "Certificate valid until $VALID_UNTIL"
    exit 0
  fi
fi

# Renew certificate
vault write -format=json pki_int/issue/vault-server \
  common_name="vault.service.consul" \
  ttl="720h" | jq -r '.data.certificate' > "$CERT_PATH.new"

mv "$CERT_PATH.new" "$CERT_PATH"
systemctl reload vault
```

## Phase 3: Production Deployment (Enhanced)

### 3.1 Master Vault Pattern

Deploy a master Vault instance for managing other Vaults:

```yaml
# Master Vault configuration
master_vault:
  address: "https://vault-master.homelab.spaceships.work:8200"
  features:
    - transit_auto_unseal # For other Vaults
    - pki_root_ca # Certificate authority
    - gossip_key_storage # For Consul/Nomad
    - policy_management # Centralized policies
```

### 3.2 Raft Cluster with Auto-Unseal

Production cluster configuration:

```hcl
# vault.hcl
storage "raft" {
  path = "/opt/vault/data"
  node_id = "vault-{{ ansible_hostname }}"

  retry_join {
    leader_api_addr = "https://vault-1.homelab.spaceships.work:8200"
  }
  retry_join {
    leader_api_addr = "https://vault-2.homelab.spaceships.work:8200"
  }
  retry_join {
    leader_api_addr = "https://vault-3.homelab.spaceships.work:8200"
  }
}

seal "transit" {
  address = "https://vault-master.homelab.spaceships.work:8200"
  token = "{{ vault_transit_token }}"
  disable_renewal = "false"
  key_name = "autounseal"
  mount_path = "transit/"
}
```

## Phase 4: Automated Secret Rotation (New)

### 4.1 Consul-Template Integration

Implement Deltamir's rotation patterns:

```hcl
# /opt/vault/templates/consul_gossip_rotation.hcl
vault {
  address = "https://vault.service.consul.spaceships.work:8200"
  token = "{{ consul_template_token }}"
  renew_token = true
}

template {
  source = "/opt/vault/templates/gossip.key.tpl"
  destination = "/etc/consul/gossip.key"
  perms = 0600
  user = "consul"
  group = "consul"

  exec {
    command = ["/opt/consul_rotate_key.sh"]
    timeout = "30s"
  }
}
```

### 4.2 Rotation Intervals

Configure rotation based on Deltamir's patterns:

```yaml
# Rotation intervals
consul_template_gossip_key_ttl: "1h" # Gossip keys
consul_template_cert_ttl: "24h" # TLS certificates
vault_token_ttl: "768h" # Service tokens (32 days)
```

## Phase 5: Snapshot and Disaster Recovery (Enhanced)

### 5.1 Automated Snapshot System

Implement wescale's snapshot pattern:

```yaml
# Snapshot configuration
vault_snapshot:
  enabled: true
  schedule: "0 2 * * *" # Daily at 2 AM
  retention: 30 # Keep 30 days
  storage:
    local: "/opt/vault-snapshots"
    remote: "s3://backup-bucket/vault/"

  # Dedicated snapshot user
  user:
    name: "vault-snapshot"
    home: "/opt/vault-snapshot"
    policy: "snapshot-policy"
```

### 5.2 Snapshot Playbook

```yaml
# playbooks/infrastructure/vault/snapshot.yml
---
- name: Vault Snapshot Operations
  hosts: vault_servers[0]
  become: true

  tasks:
    - name: Check if leader
      uri:
        url: "https://127.0.0.1:8200/v1/sys/leader"
      register: leader_check

    - name: Create snapshot
      when: leader_check.json.is_self
      shell: |
        vault operator raft snapshot save \
          /opt/vault-snapshots/vault.$(date +%Y%m%dT%H%M%S).snapshot
      environment:
        VAULT_ADDR: "https://127.0.0.1:8200"
        VAULT_TOKEN: "{{ vault_snapshot_token }}"

    - name: Sync to backup location
      synchronize:
        src: "/opt/vault-snapshots/"
        dest: "{{ backup_location }}/"
        mode: pull
```

### 5.3 Restore Procedures

Enhanced restore with validation:

```yaml
# playbooks/infrastructure/vault/restore.yml
---
- name: Vault Restore from Snapshot
  hosts: vault_servers
  serial: 1

  pre_tasks:
    - name: Verify snapshot exists
      stat:
        path: "{{ snapshot_file }}"
      delegate_to: localhost
      run_once: true

    - name: Confirm restore operation
      pause:
        prompt: |
          ⚠️  This will restore Vault from: {{ snapshot_file }}
          All current data will be replaced.
          Unseal keys from snapshot time will be required.

          Continue? (yes/no)
```

## Phase 6: Monitoring and Observability (Enhanced)

### 6.1 Comprehensive Metrics

```yaml
# Enhanced telemetry configuration
vault_telemetry:
  prometheus_retention_time: "24h"
  disable_hostname: false

  # Key metrics to monitor
  alerts:
    - name: "vault_sealed"
      expression: "vault_core_unsealed == 0"
      severity: "critical"

    - name: "vault_leader_loss"
      expression: "vault_core_active == 0"
      severity: "critical"

    - name: "vault_certificate_expiry"
      expression: "vault_pki_cert_expiry_seconds < 604800" # 7 days
      severity: "warning"
```

### 6.2 Audit Log Management

```yaml
# Audit configuration
vault_audit:
  file:
    path: "/var/log/vault/audit.log"
    format: "json"
    rotate_bytes: 52428800 # 50MB
    rotate_duration: "24h"
    rotate_max_files: 14

  syslog:
    enabled: true
    facility: "AUTH"
    tag: "vault-audit"
```

## Phase 7: Integration Patterns (Enhanced)

### 7.1 Nomad Workload Identity

Enhanced JWT configuration:

```hcl
# JWT auth backend configuration
path "auth/nomad" {
  type = "jwt"
  config {
    jwks_url = "https://nomad.service.consul.spaceships.work:4646/.well-known/jwks.json"
    jwt_supported_algs = ["RS256"]
    default_role = "nomad-workload"
  }
}

# Workload role with claim mappings
resource "vault_jwt_auth_backend_role" "nomad_workload" {
  role_name = "nomad-workload"
  role_type = "jwt"

  bound_audiences = ["vault.io"]
  user_claim = "/nomad_job_id"
  user_claim_json_pointer = true

  claim_mappings = {
    nomad_namespace = "nomad_namespace"
    nomad_job_id    = "nomad_job_id"
    nomad_task      = "nomad_task"
    nomad_alloc_id  = "nomad_alloc_id"
  }

  token_policies = ["nomad-workload"]
  token_ttl = 3600
  token_max_ttl = 86400
}
```

### 7.2 Dynamic Database Credentials

```hcl
# Database secrets engine
path "database/creds/{{identity.entity.aliases.auth_jwt_xxxxx.metadata.nomad_job_id}}" {
  capabilities = ["read"]
}
```

## Implementation Timeline

| Week | Phase             | Key Activities                       |
| ---- | ----------------- | ------------------------------------ |
| 1    | Assessment & Dev  | Infrastructure audit, dev deployment |
| 2    | PKI Setup         | Root CA, intermediate CAs, policies  |
| 3    | Production Deploy | Raft cluster, auto-unseal            |
| 4    | Automation        | consul-template, rotation scripts    |
| 5    | DR & Backup       | Snapshots, restore procedures        |
| 6    | Integration       | Nomad, Consul, database engines      |
| 7    | Monitoring        | Metrics, alerts, audit logs          |
| 8    | Documentation     | Runbooks, troubleshooting guides     |

## Risk Mitigation

### Enhanced Risk Matrix

| Risk                | Probability | Impact   | Mitigation                                 |
| ------------------- | ----------- | -------- | ------------------------------------------ |
| Seal/Unseal Issues  | Medium      | High     | Auto-unseal + documented manual procedures |
| Certificate Expiry  | Low         | High     | Auto-renewal + monitoring alerts           |
| Snapshot Corruption | Low         | Critical | Multiple backup locations + validation     |
| Token Leakage       | Low         | Critical | Short TTLs + audit logging                 |
| Network Partition   | Medium      | Medium   | Raft consensus handles split-brain         |

## Success Criteria

### Enhanced Metrics

- [ ] 99.9% uptime for Vault API
- [ ] < 5 minute RTO for disaster recovery
- [ ] 100% automated certificate renewal
- [ ] Zero manual token management
- [ ] < 100ms latency for secret retrieval
- [ ] Automated daily snapshots with validation
- [ ] Three-tier policy enforcement across stack

## Conclusion

This enhanced strategy incorporates production-proven patterns:

- **Deltamir's** automated rotation and master Vault architecture
- **Skatteetaten's** three-tier policy framework
- **wescale's** snapshot management and PKI auto-renewal

The result is a robust, automated, and maintainable Vault deployment suitable for production homelab use with clear paths to scale.
