# HashiCorp Vault Deployment Strategy

## Executive Summary

This document outlines the deployment strategy for HashiCorp Vault in the andromeda-orchestration infrastructure, based on comprehensive research and best practices from production deployments.

## Research Findings

### Key Sources Evaluated

1. **Skatteetaten/vagrant-hashistack** - Modern workload identity patterns
2. **Deltamir/ansible-hashistack** - Comprehensive PKI/mTLS automation
3. **wescale.hashistack** - Homelab-focused implementations

### Critical Decision: Vault as a Service, Not a Nomad Job

All research sources confirm that Vault should **NOT** run as a Nomad job in production because:

- **Persistent State Requirements**: Vault requires stable storage for encrypted data
- **Unsealing Complexity**: The unsealing process doesn't fit container orchestration patterns
- **Foundation Service**: Vault should be the secure foundation that Nomad workloads depend on
- **Recovery Procedures**: Disaster recovery is more complex in containerized environments

## Implementation Strategy

### Phase 1: Development Mode (Week 1)

**Objective**: Exploration and learning

```bash
# Deploy Vault in dev mode
uv run ansible-playbook playbooks/infrastructure/vault/deploy-vault-dev.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e target_hosts=lloyd
```

**Dev Mode Characteristics**:

- In-memory storage (data lost on restart)
- Automatic unsealing
- Root token: "root"
- No TLS encryption
- UI enabled at http://<host>:8200/ui

### Phase 2: Production Preparation (Week 2)

**Objective**: Production-ready deployment with Raft storage

#### Storage Backend Selection: Raft

**Why Raft over Consul backend?**

- **Simplicity**: No external dependencies
- **Performance**: Direct storage without network overhead
- **Integrated**: Ships with Vault, no additional setup
- **HA Ready**: Built-in leader election and replication

#### Configuration Structure

```hcl
storage "raft" {
  path = "/opt/vault/data"
  node_id = "vault-node-1"

  retry_join {
    leader_api_addr = "http://vault-1.service.consul:8200"
  }
}
```

### Phase 3: Nomad Integration

**Workload Identity Configuration** (Nomad 1.7+):

1. **JWT Auth Backend Setup**:

   ```bash
   vault auth enable -path=nomad jwt
   vault write auth/nomad/config \
     jwks_url="https://nomad.service.consul:4646/.well-known/jwks.json" \
     jwt_supported_algs="RS256" \
     default_role="nomad-workload"
   ```

2. **Nomad Server Configuration**:

   ```hcl
   vault {
     enabled = true
     address = "http://vault.service.consul:8200"
     jwt_auth_backend_path = "nomad"
   }
   ```

3. **Job Specification**:

   ```hcl
   vault {
     role = "nomad-workload"
     change_mode = "restart"
   }
   ```

## Auto-Unseal Strategy

### Development Environment

- Manual unsealing acceptable for learning
- Use Shamir's secret sharing with 3 of 5 keys

### Production Environment

**Option 1: Transit Secret Engine** (Recommended for homelab)

```hcl
seal "transit" {
  address = "http://vault-transit.service.consul:8200"
  token = "s.xxxxx"
  key_name = "autounseal"
  mount_path = "transit/"
}
```

**Option 2: Cloud KMS** (For cloud deployments)

- AWS KMS
- Azure Key Vault
- Google Cloud KMS

## Security Architecture

### Secrets Management Hybrid Approach

```text
┌─────────────────┐
│   Infisical     │ ← Static secrets (API keys, passwords)
│  (Existing)     │
└─────────────────┘
        ↓
┌─────────────────┐
│     Vault       │ ← Dynamic secrets (certificates, temp credentials)
│  (New)          │
└─────────────────┘
        ↓
┌─────────────────┐
│  Nomad Jobs     │ ← Workload identity authentication
└─────────────────┘
```

### PKI Certificate Management

1. **Root CA**: Offline, air-gapped
2. **Intermediate CA**: Vault-managed
3. **Leaf Certificates**: Auto-generated for workloads

## Deployment Files Structure

```text
roles/vault/                       # Ansible role
├── defaults/main.yml              # Configuration variables
├── tasks/
│   ├── install.yml               # Installation tasks [FIXME]: This install installs from binary, needs to be updated to use the package manager
│   ├── config_dev.yml            # Dev mode setup
│   ├── config_prod.yml           # Production setup
│   └── nomad_integration.yml    # Nomad auth configuration

playbooks/infrastructure/vault/    # Deployment playbooks
├── deploy-vault-dev.yml          # Dev mode deployment
├── deploy-vault-prod.yml         # Production deployment
└── configure-nomad-auth.yml     # Nomad integration

nomad-jobs/core-infrastructure/
└── vault-reference.nomad.hcl     # Reference only - NOT for production
```

## Operational Procedures

### Initial Deployment

1. **Deploy in dev mode** for exploration
2. **Test basic operations** (secrets, policies, auth)
3. **Plan production topology** (1 or 3 nodes for HA)
4. **Deploy production** with Raft storage
5. **Initialize and unseal** Vault
6. **Configure auto-unseal** mechanism
7. **Set up Nomad integration**
8. **Create policies** for workloads

### Day 2 Operations

- **Backup**: Daily Raft snapshots
- **Monitoring**: Prometheus metrics, seal status alerts
- **Certificate Rotation**: Automated via Vault PKI
- **Audit Logging**: Enable file audit backend
- **Disaster Recovery**: Practice recovery procedures

## Monitoring and Alerting

### Key Metrics

- `vault.core.unsealed` - Seal status (critical)
- `vault.token.count` - Active tokens
- `vault.expire.num_leases` - Active leases
- `vault.runtime.alloc_bytes` - Memory usage
- `vault.raft.apply` - Raft write performance

### Integration with Netdata

```yaml
# Add to Netdata configuration
go.d:
  jobs:
    - name: vault
      url: http://vault.service.consul:8200/v1/sys/metrics
      format: prometheus
```

## Migration Path from Dev to Production

1. **Export policies and auth methods** from dev
2. **Document secret paths** and access patterns
3. **Deploy production Vault** cluster
4. **Import policies** and configure auth
5. **Migrate secrets** (if any persistent ones)
6. **Update Nomad configuration** to use production Vault
7. **Decommission dev instance**

## Common Pitfalls to Avoid

1. ❌ Running Vault as a Nomad job in production
2. ❌ Using dev mode storage backend in production
3. ❌ Storing unseal keys together
4. ❌ Disabling audit logging
5. ❌ Using root tokens for applications
6. ❌ Ignoring certificate expiration
7. ❌ Not testing disaster recovery

## Success Criteria

- ✅ Vault deployed and unsealed
- ✅ Auto-unseal configured
- ✅ Nomad workload identity working
- ✅ PKI certificate generation automated
- ✅ Monitoring and alerting active
- ✅ Backup procedures tested
- ✅ Disaster recovery plan documented

## Next Steps

1. Deploy Vault in dev mode to lloyd node
2. Explore UI and API functionality
3. Test Nomad workload identity integration
4. Plan production deployment for Week 2
5. Document operational procedures

## References

- [Vault Production Hardening](https://developer.hashicorp.com/vault/tutorials/operations/production-hardening)
- [Nomad Vault Integration](https://developer.hashicorp.com/nomad/docs/integrations/vault)
- [Vault Storage Backends](https://developer.hashicorp.com/vault/docs/configuration/storage)
