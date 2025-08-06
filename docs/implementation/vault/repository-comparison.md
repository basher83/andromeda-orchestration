# Vault Implementation Repository Comparison

## Overview

This document compares our Vault implementation with three reference repositories identified during research:

1. **Deltamir/ansible-hashistack** - Production-grade HashiCorp stack deployment
2. **Skatteetaten/vagrant-hashistack** - Development-focused HashiCorp stack
3. **wescale/hashistack** - Enterprise patterns with Terraform integration

## Implementation Alignment Matrix

| Feature | Our Implementation | Deltamir | Skatteetaten | wescale |
|---------|-------------------|----------|--------------|---------|
| **Storage Backend** | Raft (production), In-memory (dev) | Consul | In-memory (dev) | Raft |
| **Deployment Method** | Ansible role + playbooks | Ansible role | Ansible playbooks | Terraform + Ansible |
| **Service Management** | Systemd service | Systemd | Systemd | Systemd |
| **Auto-unseal** | Transit, AWS KMS, Azure, GCP | Transit | Not implemented | AWS KMS |
| **Nomad Integration** | JWT workload identity | Token-based | Token-based | JWT workload identity |
| **Dev Mode Support** | Yes, with safety checks | No | Yes, primary focus | No |
| **TLS Configuration** | Optional, configurable | Required | Disabled in dev | Required |
| **Consul Integration** | Service registration | Storage backend | Service registration | Service mesh |
| **Multi-node Support** | Yes, Raft clustering | Yes, via Consul | Single node dev | Yes, Raft clustering |

## Pattern Analysis by Repository

### 1. Deltamir/ansible-hashistack

**Patterns We Adopted:**

- ✅ Structured Ansible role with clear task separation
- ✅ Systemd service management with proper unit files
- ✅ Comprehensive variable defaults with documentation
- ✅ Health check integration with Consul
- ✅ Separate configuration templates for different modes

**Patterns We Simplified:**

- ❌ Consul storage backend → We use Raft for fewer dependencies
- ❌ Mandatory TLS → We made TLS optional for homelab flexibility
- ❌ Complex PKI setup → Deferred to post-deployment phase

**Key Differences:**

```yaml
# Deltamir uses Consul storage
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

# We use Raft for simplicity
storage "raft" {
  path = "/opt/vault/data"
  node_id = "{{ ansible_hostname }}"
}
```

### 2. Skatteetaten/vagrant-hashistack

**Patterns We Adopted:**

- ✅ Dev mode with systemd service (unusual but effective)
- ✅ Master token pattern for initial configuration
- ✅ Bootstrap and post-configuration playbooks
- ✅ Extensive pre/post task validation
- ✅ Integration testing approach

**Patterns We Enhanced:**

- ⚡ Added production mode support (they only support dev)
- ⚡ Added auto-unseal capabilities
- ⚡ Added Raft storage for production
- ⚡ Added comprehensive safety checks and prompts

**Key Implementation Match:**

```yaml
# Skatteetaten's dev mode systemd approach
ExecStart=/usr/local/bin/vault server -dev \
  -dev-root-token-id="{{ vault_master_token }}"

# Our matching implementation
ExecStart=/usr/local/bin/vault server -dev \
  -dev-root-token-id="{{ vault_dev_root_token }}"
```

### 3. wescale/hashistack

**Patterns We Adopted:**

- ✅ Raft storage backend for production
- ✅ JWT-based Nomad workload identity
- ✅ Auto-unseal configuration structure
- ✅ Comprehensive policy templates
- ✅ Multi-node clustering support

**Patterns We Simplified:**

- ❌ Terraform provisioning → Pure Ansible for consistency
- ❌ Complex master/minion architecture → Peer-based Raft
- ❌ Mandatory enterprise features → Optional configurations

**Key Alignment:**

```hcl
# wescale's Raft configuration
storage "raft" {
  path = "/opt/vault/raft"
  retry_join {
    leader_api_addr = "http://vault1:8200"
  }
}

# Our similar approach
storage "raft" {
  path = "{{ vault_data_dir }}"
  node_id = "{{ vault_raft_node_id }}"
  retry_join {
    leader_api_addr = "{{ item }}"
  }
}
```

## Validation Findings

### Storage Backend Choice

Our Raft implementation aligns with **wescale** patterns:

- **Justification**: Raft provides integrated storage without external dependencies
- **Trade-off**: Less suitable for very large deployments vs Consul
- **Homelab Benefit**: Simpler operation, fewer moving parts

### Dev Mode Implementation

Our dev mode closely matches **Skatteetaten** patterns:

- **Unique Approach**: Running dev mode with systemd (production-like management)
- **Justification**: Consistent service management across modes
- **Enhancement**: We added production mode transition path

### Nomad Integration

Hybrid approach combining best of **wescale** and **Deltamir**:

- **JWT Auth**: From wescale (modern, secure)
- **Policy Structure**: From Deltamir (comprehensive)
- **Our Addition**: Workload identity with claim mappings

## Key Implementation Decisions

### 1. Why Raft Over Consul Storage?

**Research Finding**: Both wescale and Deltamir show different approaches

- **wescale**: Uses Raft for integrated storage
- **Deltamir**: Uses Consul for distributed storage

**Our Decision**: Raft (following wescale)

- ✅ No external dependency on Consul for storage
- ✅ Simpler disaster recovery (single system)
- ✅ Better for homelab scale (3-5 nodes)
- ❌ Less suitable for 10+ node deployments

### 2. Why Support Dev Mode?

**Research Finding**: Only Skatteetaten focuses on dev mode

- **Skatteetaten**: Dev-first approach for exploration
- **Others**: Production-only focus

**Our Decision**: Dual mode support

- ✅ Dev mode for learning and testing
- ✅ Clear migration path to production
- ✅ Safety checks prevent accidental production use
- ✅ Matches homelab exploration needs

### 3. Why Optional TLS?

**Research Finding**: Mixed approaches

- **Deltamir/wescale**: Mandatory TLS
- **Skatteetaten**: No TLS in dev

**Our Decision**: Configurable TLS

- ✅ Flexibility for internal homelab networks
- ✅ Can enable for production/external access
- ✅ Simplifies initial deployment
- ⚠️ Clear security warnings in documentation

## Unique Homelab Optimizations

Our implementation includes homelab-specific optimizations not found in references:

### 1. Phased Deployment Strategy

```yaml
# Phase 1: Dev exploration
vault_mode: "dev"

# Phase 2: Production migration
vault_mode: "production"
vault_storage_backend: "raft"
```

### 2. Simplified Secret Management

```yaml
# Infisical integration for secrets
vault_auto_unseal_config:
  token: "{{ lookup('infisical.infisical.generic', '/apollo-13/vault/transit-token') }}"
```

### 3. Resource-Conscious Defaults

```yaml
# Tuned for homelab resources
vault_telemetry_prometheus_retention_time: "24h"  # Not 30d
vault_audit_log_rotate_bytes: 52428800  # 50MB not 500MB
```

## Migration Path Validation

Our implementation provides clear migration paths missing from references:

### Dev → Production Migration

1. **Skatteetaten**: No production path provided
2. **Our Implementation**: Documented migration strategy
   - Export secrets from dev
   - Deploy production with Raft
   - Import secrets to production
   - Update service endpoints

### Single Node → HA Migration

1. **References**: Assume multi-node from start
2. **Our Implementation**: Incremental scaling
   - Start with single Raft node
   - Add nodes to form cluster
   - Automatic leader election

## Security Comparison

| Security Feature | Our Implementation | Best Practice Source |
|-----------------|-------------------|---------------------|
| Root Token Rotation | Documented procedure | Deltamir |
| Auto-unseal | Multiple providers supported | wescale |
| Audit Logging | Enabled by default in prod | Deltamir |
| Policy Templates | Comprehensive set | All three |
| Network Segmentation | Separate cluster port | wescale |
| Capability Restrictions | mlock capability set | Deltamir |

## Conclusion

Our Vault implementation successfully combines:

- **Production patterns** from wescale (Raft storage, JWT auth)
- **Development patterns** from Skatteetaten (systemd dev mode)
- **Operational patterns** from Deltamir (Ansible structure, policies)

The result is a homelab-optimized deployment that:

1. ✅ Maintains production-grade patterns
2. ✅ Simplifies where appropriate for homelab use
3. ✅ Provides clear upgrade paths
4. ✅ Reduces operational complexity
5. ✅ Preserves security best practices

### Validation Summary

- **Storage**: Aligned with wescale (Raft)
- **Service Management**: Aligned with all three (systemd)
- **Dev Mode**: Enhanced from Skatteetaten
- **Nomad Integration**: Modernized from wescale
- **Ansible Structure**: Refined from Deltamir

The implementation is not a direct copy of any single repository but rather a thoughtful synthesis of the best patterns from each, adapted for homelab requirements while maintaining production viability.
