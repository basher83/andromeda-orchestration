# Vault Production Deployment Plan

**Status**: ✅ Pre-Deployment Complete - Ready for Phase 1
**Priority**: P0 (CRITICAL - Unblocks all production services)
**Target Completion**: August 23, 2025
**Epic**: Domain Migration - Infrastructure Gap Resolution

---

## Executive Summary

Deploy HashiCorp Vault in production mode with Raft storage to replace the current development mode deployment. This unblocks PostgreSQL backend deployment, PowerDNS secrets management, and enables the domain migration infrastructure changes to be applied.

### Critical Impact

**Current Blocker**: Vault running in dev mode prevents:
- PostgreSQL credential persistence
- PowerDNS secret management
- Infrastructure configuration application
- Any production service deployment

**Resolution**: Production Vault with persistent storage enables all blocked services.

---

## Pre-Deployment Checklist

### Infrastructure Readiness

- [x] **DNS Resolution Verified**
  - [x] All three Nomad nodes resolve correctly
  - [x] Consul service discovery operational
  - [x] Network connectivity confirmed between all nodes

- [x] **Network Connectivity**
  - [x] Port 8200 (Vault API) accessible between all nodes
  - [x] Port 8201 (Vault cluster) accessible between all nodes
  - [x] Firewall rules configured for Vault traffic
  - [x] No port conflicts with existing services

- [x] **Storage Preparation**
  - [x] `/opt/vault/data` directory structure ready
  - [x] Minimum 10GB storage available per node (55-56GB available)
  - [x] Proper permissions for vault user/group

- [x] **Time Synchronization**
  - [x] NTP configured and synchronized across all nodes
  - [x] Time skew within acceptable limits (<1 second)

### Current State Assessment

- [x] **Document Current Dev Mode**
  - [x] Export any test policies/secrets if needed (none to preserve - dev mode inmem)
  - [x] Document current Vault version (lloyd: 1.20.2, holly/mable: 1.20.1)
  - [x] Note current integration points (isolated dev instances, no clustering)

- [x] **Service Dependencies**
  - [x] Confirm no services depend on dev mode root token (all isolated)
  - [x] Verify Nomad can handle Vault restart (confirmed)
  - [x] Check Consul service registrations (ready for integration)

### ✅ Pre-Deployment Assessment Summary

**Assessment Completed**: August 23, 2025 02:57 UTC

**Infrastructure Status**: All systems ready for production deployment
- **Node Count**: 3 Vault target nodes (nomad-server-1-lloyd, nomad-server-2-holly, nomad-server-3-mable)
- **Network**: 100% connectivity success rate between all 9 nodes tested
- **Storage**: 55-56GB available per node (far exceeds 10GB minimum)
- **Memory**: 1.9GB total, ~1.1GB available per node (adequate for Vault)
- **Time Sync**: Perfect synchronization, <1 second skew

**Current Vault Dev Mode Status**:
- **lloyd (192.168.10.11)**: v1.20.2, PID 759, 7h43m uptime, inmem storage, `/usr/bin/vault`
- **holly (192.168.10.12)**: v1.20.1, PID 765, 7h43m uptime, inmem storage, `/usr/local/bin/vault`
- **mable (192.168.10.13)**: v1.20.1, PID 767, 7h28m uptime, inmem storage, `/usr/local/bin/vault`

**Version Standardization**:
- **Target Version**: 1.20.2 (latest patch release)
- **Action Required**: Upgrade holly and mable from 1.20.1 → 1.20.2
- **Binary Location**: Standardize on `/usr/local/bin/vault`
- **Compatibility**: 1.20.1 and 1.20.2 are compatible for Raft clustering

**Port Verification**:
- Vault API (8200) and cluster (8201) ports available and accessible
- No conflicts with existing services
- Cross-node connectivity verified

**Dependencies**:
- No persistent data to preserve (dev mode inmem storage)
- No services dependent on dev mode tokens
- Clean state for production deployment

**Risk Assessment**: LOW - All prerequisites met, no blocking issues identified

---

## Phase 1: Production Deployment

### Step 1: Prepare Deployment Configuration ✅ COMPLETE

- [x] **Update Inventory Variables**
  ```yaml
  # Added to inventory/doggos-homelab/group_vars/all/main.yml
  vault_mode: "production"
  vault_storage_backend: "raft"
  vault_raft_retry_join:
    - "http://192.168.10.11:8200"  # nomad-server-1-lloyd
    - "http://192.168.10.12:8200"  # nomad-server-2-holly
    - "http://192.168.10.13:8200"  # nomad-server-3-mable
  vault_ui_enabled: true
  vault_tls_disable: true  # Initial deployment, enable TLS in Phase 2
  vault_audit_enabled: true
  vault_telemetry_enabled: true
  ```

- [x] **Verify Deployment Playbook**
  - [x] Review `playbooks/infrastructure/vault/deploy-vault-prod.yml`
  - [x] Fixed recursive template variable issue
  - [x] Updated role configuration for v1.20.2 target version
  - [x] Confirmed target_hosts parameter works with `tag_server` group

- [x] **Test Ansible Connectivity**
  - [x] All 3 nodes respond to ping successfully
  - [x] Playbook dry-run passes prerequisite checks
  - [x] Version analysis completed and documented

- [x] **Version Standardization**
  - [x] Analyzed current versions (lloyd: 1.20.2, holly/mable: 1.20.1)
  - [x] Updated role defaults to target v1.20.2
  - [x] Confirmed compatibility for Raft clustering
  - [x] Deployment will handle automatic upgrades

### Step 2: Stop Development Mode Services ✅ COMPLETE

- [x] **Graceful Shutdown**
  - [x] Stop Vault dev mode services on all nodes
  - [x] Confirm no active connections to dev mode
  - [x] Clean up dev mode process files

### Step 3: Deploy Production Vault ✅ COMPLETE

- [x] **Execute Production Deployment**
  ```bash
  # Deployed to all three nodes sequentially
  uv run ansible-playbook playbooks/infrastructure/vault/deploy-vault-prod.yml \
    -i inventory/doggos-homelab/infisical.proxmox.yml \
    -e target_hosts=nomad-server-1-lloyd
  uv run ansible-playbook playbooks/infrastructure/vault/deploy-vault-prod.yml \
    -i inventory/doggos-homelab/infisical.proxmox.yml \
    -e target_hosts=nomad-server-2-holly
  uv run ansible-playbook playbooks/infrastructure/vault/deploy-vault-prod.yml \
    -i inventory/doggos-homelab/infisical.proxmox.yml \
    -e target_hosts=nomad-server-3-mable
  ```

- [x] **Monitor Deployment Progress**
  - [x] Verify service installation on all nodes
  - [x] Check configuration file generation
  - [x] Confirm service startup on all nodes

### Step 4: Initialize Vault Cluster ✅ COMPLETE

- [x] **First Node Initialization**
  - [x] Vault initialized on first node (lloyd)
  - [x] Initialization data saved to `/root/vault-init-1755918771.txt`
  - [x] Root token and unseal keys generated

- [x] **Secure Initialization Data**
  - [x] Initialization file created on lloyd with proper permissions (0600)
  - [x] Root token stored in Infisical: `/apollo-13/vault/VAULT_ROOT_TOKEN`
  - [x] 5 unseal keys generated (3 of 5 threshold)
  - [x] Store unseal keys in Infisical: `/apollo-13/vault/unseal-keys/UNSEAL_KEY_[1-5]`
  - [x] All secrets secured in centralized secrets management
  - [x] Delete initialization file from server after securing

### Step 5: Unseal Additional Nodes ✅ COMPLETE

- [x] **Manual Unseal Process**
  - [x] Unseal first node (lloyd) using 3 unseal keys
  - [x] Unseal second node (holly) using 3 unseal keys
  - [x] Unseal third node (mable) using 3 unseal keys
  - [x] Verify all nodes join Raft cluster

- [x] **Cluster Formation Verification**
  - [x] Raft cluster operational with 3 nodes
  - [x] Lloyd is leader, Holly and Mable are followers
  - [x] All nodes running Vault v1.20.2
  - [x] Cluster ID: `f96ca9f2-5c5a-791e-d08c-61653ba7e39c`

---

## Phase 2: Configuration and Integration ✅ COMPLETE

### Step 1: Enable Audit Logging ✅ COMPLETE

- [x] **File Audit Backend**
  ```bash
  vault audit enable file file_path=/var/log/vault/audit.log
  ```
  - [x] Verify audit log creation
  - [x] Audit log active at `/var/log/vault/audit.log` (4KB+ of structured JSON logs)
  - [x] Confirm structured JSON logging (HMAC-protected sensitive data)

### Step 2: Create Service Policies ✅ COMPLETE

- [x] **PostgreSQL Database Policy**
  ```hcl
  # Policy for PostgreSQL secret management
  path "database/creds/postgresql-*" {
    capabilities = ["read"]
  }
  path "database/config/postgresql" {
    capabilities = ["read"]
  }
  ```

- [x] **PowerDNS Service Policy**
  ```hcl
  # Policy for PowerDNS secret access
  path "secret/data/powerdns/*" {
    capabilities = ["read", "list"]
  }
  path "secret/metadata/powerdns/*" {
    capabilities = ["list"]
  }
  ```

- [x] **Apply Policies**
  - [x] Create PostgreSQL policy (`postgresql-service`)
  - [x] Create PowerDNS policy (`powerdns-service`)
  - [x] Policies available in Vault policy store

### Step 3: Enable Secret Engines ✅ COMPLETE

- [x] **Database Secrets Engine**
  ```bash
  vault secrets enable database
  ```
  - [x] Database engine enabled at `database/` path
  - [x] Plugin version: v1.20.2+builtin.vault

- [x] **KV v2 Engine**
  ```bash
  vault secrets enable -path=secret kv-v2
  ```
  - [x] KV v2 engine enabled at `secret/` path
  - [x] Plugin version: v0.24.0+builtin

- [x] **Verify Engines**
  - [x] Database engine operational and ready for configuration
  - [x] KV v2 engine operational with version 2 options
  - [x] All secret paths accessible via API

---

## Phase 3: Service Integration

### Step 1: PostgreSQL Integration

- [ ] **Database Configuration**
  ```bash
  vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://{{username}}:{{password}}@postgresql:5432/postgres" \
    allowed_roles="postgresql-role"
  ```

- [ ] **Role Creation**
  - [ ] Create PostgreSQL database role
  - [ ] Test credential generation
  - [ ] Verify credential rotation

### Step 2: Nomad Integration

- [ ] **JWT Auth Backend**
  ```bash
  vault auth enable -path=nomad jwt
  vault write auth/nomad/config \
    jwks_url="https://nomad.service.consul:4646/.well-known/jwks.json" \
    jwt_supported_algs="RS256" \
    default_role="nomad-workload"
  ```

- [ ] **Workload Identity Role**
  - [ ] Create nomad-workload role
  - [ ] Configure claim mappings
  - [ ] Test JWT authentication

### Step 3: PowerDNS Secret Management

- [ ] **Store PowerDNS Configuration**
  ```bash
  vault kv put secret/powerdns/config \
    api_key="<generated-key>" \
    database_url="postgresql://powerdns:password@postgresql:5432/powerdns"
  ```

- [ ] **Verify Secret Access**
  - [ ] Test secret retrieval with PowerDNS policy
  - [ ] Confirm secret rotation capabilities

---

## Phase 4: Validation and Testing

### Step 1: Cluster Health Verification

- [ ] **Vault Status Checks**
  ```bash
  # On each node
  vault status
  vault operator raft list-peers
  vault auth list
  vault secrets list
  ```

- [ ] **Performance Testing**
  - [ ] Test read/write operations
  - [ ] Verify cluster failover behavior
  - [ ] Check Raft consensus performance

### Step 2: Integration Testing

- [ ] **Nomad Workload Identity**
  - [ ] Deploy test job with Vault integration
  - [ ] Verify dynamic secret retrieval
  - [ ] Test token renewal process

- [ ] **Database Credential Generation**
  - [ ] Generate PostgreSQL credentials
  - [ ] Test database connectivity with generated creds
  - [ ] Verify credential expiration and rotation

### Step 3: Monitoring Integration

- [ ] **Netdata Configuration**
  - [ ] Configure Vault metrics collection
  - [ ] Add Vault health checks to Netdata
  - [ ] Verify telemetry data flow

- [ ] **Consul Health Checks**
  - [ ] Register Vault service in Consul
  - [ ] Configure health check endpoints
  - [ ] Verify service discovery integration

---

## Phase 5: Operational Readiness

### Step 1: Backup Configuration

- [ ] **Raft Snapshot Setup**
  ```bash
  # Daily snapshot cron job
  vault operator raft snapshot save /opt/vault-snapshots/vault.$(date +%Y%m%d).snapshot
  ```

- [ ] **Backup Verification**
  - [ ] Test snapshot creation
  - [ ] Verify snapshot integrity
  - [ ] Document restore procedures

### Step 2: Security Hardening

- [ ] **Root Token Management**
  - [ ] Revoke initial root token after setup
  - [ ] Create emergency access procedures
  - [ ] Document break-glass processes

- [ ] **Access Control**
  - [ ] Review and minimize policy permissions
  - [ ] Implement least-privilege access
  - [ ] Audit user/service token assignments

### Step 3: Documentation

- [ ] **Operational Runbooks**
  - [ ] Unsealing procedures
  - [ ] Backup and restore processes
  - [ ] Troubleshooting common issues
  - [ ] Emergency response procedures

- [ ] **Integration Guides**
  - [ ] Service onboarding process
  - [ ] Secret management best practices
  - [ ] Policy creation guidelines

---

## Success Criteria

### Technical Validation

- [ ] **All three Vault nodes are unsealed and healthy**
- [ ] **Raft cluster shows 3 active peers**
- [ ] **Audit logging is active and writing structured logs**
- [ ] **Database secrets engine generates valid PostgreSQL credentials**
- [ ] **KV secrets engine stores and retrieves application secrets**
- [ ] **Nomad JWT authentication works for workload identity**

### Performance Validation

- [ ] **Secret retrieval latency < 100ms**
- [ ] **Cluster failover time < 30 seconds**
- [ ] **Raft consensus operational under normal load**
- [ ] **Memory usage stable under 1GB per node**

### Security Validation

- [ ] **Root token secured and access documented**
- [ ] **Unseal keys distributed and secured separately**
- [ ] **Audit logs capturing all API operations**
- [ ] **Policy enforcement working correctly**
- [ ] **No hardcoded credentials in configuration**

### Integration Validation

- [ ] **PostgreSQL backend can deploy with Vault-managed credentials**
- [ ] **PowerDNS can retrieve secrets from Vault**
- [ ] **Domain migration infrastructure changes can be applied**
- [ ] **Nomad jobs can use Vault workload identity**

---

## Risk Mitigation

### Deployment Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Cluster formation failure | Low | High | Deploy sequentially, verify each node |
| Unseal key loss | Low | Critical | Store keys in multiple secure locations |
| Service disruption | Medium | Medium | Deploy during maintenance window |
| Configuration errors | Medium | High | Test in dev environment first |

### Rollback Plan

If production deployment fails:

1. **Immediate Rollback** (< 10 minutes)
   - [ ] Stop production Vault services
   - [ ] Restart dev mode Vault on all nodes
   - [ ] Verify service restoration

2. **Extended Rollback** (< 30 minutes)
   - [ ] Restore original configuration files
   - [ ] Clear any persistent data
   - [ ] Restart dependent services (Nomad/Consul)

---

## Next Steps After Deployment

1. **Deploy PostgreSQL Backend**
   - Use Vault-managed database credentials
   - Configure connection pooling with secret rotation

2. **Apply Domain Migration Changes**
   - Update infrastructure configuration with new domain
   - Deploy PowerDNS with Vault secret management

3. **Enable Advanced Features**
   - Configure auto-unseal for operational efficiency
   - Set up certificate management with PKI engine
   - Implement automated secret rotation

---

## Commands Reference

### Essential Commands

```bash
# Check Vault status
export VAULT_ADDR='http://192.168.10.11:8200'
vault status

# List cluster peers
vault operator raft list-peers

# Manual unseal (if needed)
vault operator unseal <key-1>
vault operator unseal <key-2>
vault operator unseal <key-3>

# Create snapshot
vault operator raft snapshot save vault-backup.snapshot

# Check audit logs
tail -f /var/log/vault/audit.log | jq

# Monitor telemetry
curl http://192.168.10.11:8200/v1/sys/metrics?format=prometheus
```

### Troubleshooting Commands

```bash
# Check Vault logs
journalctl -u vault -f

# Verify Raft storage
ls -la /opt/vault/data/

# Test network connectivity
nc -zv 192.168.10.11 8200
nc -zv 192.168.10.11 8201

# Check resource usage
ps aux | grep vault
df -h /opt/vault
```

---

**Last Updated**: August 23, 2025
**Document Owner**: Infrastructure Team
**Review Schedule**: Weekly during deployment phase
