# Consul JWT Authentication for Nomad Workloads

## Overview

This document describes the JWT authentication method configuration that enables Nomad workloads to authenticate with Consul using service identity tokens.

## Current Configuration

The active authentication method `nomad-workloads` is configured with the following settings:

```json
{
  "BoundAudiences": ["consul.io"],
  "ClaimMappings": {
    "nomad_job_id": "nomad_job_id",
    "nomad_namespace": "nomad_namespace",
    "nomad_task": "nomad_task"
  },
  "JWKSURL": "http://192.168.11.11:4646/.well-known/jwks.json",
  "JWTValidationPubKeys": [],
  "ListClaimMappings": {
    "nomad_service": "nomad_service"
  }
}
```

**Configuration Source**: `roles/consul/files/auth-methods/nomad-workloads-final.json`

## Purpose and Function

### What This Enables

- **Service Identity**: Each Nomad workload gets unique JWT tokens
- **Consul Access**: Workloads can authenticate to Consul API and KV store
- **Zero Trust**: No shared secrets, tokens are automatically generated and rotated
- **Audit Trail**: Consul can identify which specific service made requests

### How It Works

1. **Token Generation**: Nomad generates JWT tokens for workloads with service identity configured
2. **Token Validation**: Consul validates tokens using Nomad's JWKS endpoint
3. **Claims Mapping**: JWT claims are mapped to Consul metadata for authorization
4. **Authorization**: Bound roles determine what the authenticated service can access

## Verification Commands

### Check Current Configuration

```bash
# View the complete auth method configuration
consul acl auth-method read -name nomad-workloads

# Verify JWKS endpoint accessibility
curl -s http://192.168.11.11:4646/.well-known/jwks.json | jq .
```

### Verify Associated Components

```bash
# Check binding rules (links auth method to roles)
consul acl binding-rule list -method nomad-workloads

# Check associated roles and policies
consul acl role list | grep nomad-workload
consul acl policy list | grep nomad-workload
```

## Dependencies

### Nomad Configuration

Nomad must have service identity enabled:

```hcl
consul {
  service_identity {
    enabled = true
  }
  task_identity {
    enabled = true
  }
}
```

### Job Requirements

All services must include identity blocks when service_identity is enabled:

```hcl
service {
  name = "service-name"
  port = "port-label"

  identity {
    aud = ["consul.io"]  # REQUIRED - matches BoundAudiences
    ttl = "1h"          # Optional but recommended
  }
}
```

## Troubleshooting

### Common Issues

1. **"Auth method not found"** - The auth method was deleted or never created
2. **"Permission denied"** - Token lacks required policies/roles
3. **"JWKS unreachable"** - Consul can't reach Nomad's JWKS endpoint
4. **"Service identity must provide aud value"** - Missing identity block in service definition

### Debug Commands

```bash
# Test JWKS connectivity from Consul nodes
curl -I http://192.168.11.11:4646/.well-known/jwks.json

# Check Consul logs for auth failures
journalctl -u consul -f

# Check Nomad logs for token derivation issues
journalctl -u nomad -f
```

## Configuration History

The final configuration was established on **August 2, 2025** after troubleshooting service identity token derivation issues. The configuration files show this evolution:

- `nomad-workloads.json` (02:32) - Original with localhost URL
- `nomad-workloads-config.json` (02:33) - Config extraction
- `nomad-workloads-updated.json` (02:46) - Added timing leeway settings
- `nomad-workloads-final.json` (02:46) - **ACTIVE CONFIG** - Simplified final version

## Related Components

### Consul Policies

- `nomad-workload-identity` - Basic service identity permissions
- `nomad-workload-kv` - KV store access for workloads

### Consul Roles

- `nomad-workload` - Role bound by the binding rule

### Files

- **Active Config**: `roles/consul/files/auth-methods/nomad-workloads-final.json`
- **Policy Files**: `roles/consul/files/policies/nomad-workload-*.hcl`

## Consul KV Access for Nomad Jobs

### Issue and Resolution (August 10, 2025)

**Problem**: Nomad jobs using Consul KV templating (e.g., `{{ key "path/to/key" }}`) were failing with permission denied errors. The PowerDNS deployment was affected by this issue.

**Root Cause**: The `nomad-client` and `nomad-server` ACL policies lacked `key_prefix` read permissions required for Consul KV access during job templating.

**Solution**: Updated both ACL policies to include KV read access:

```hcl
# Added to both nomad-server and nomad-client policies
key_prefix "" {
  policy = "read"
}
```

**Deployment Method**: Created infrastructure playbooks to manage ACL policy updates:

- `playbooks/infrastructure/consul-nomad/update-nomad-client-acl-kv.yml` - Updates client policy
- `playbooks/infrastructure/consul-nomad/update-all-nomad-acl-policies.yml` - Updates both policies

**Verification**: All 6 Nomad nodes (3 servers + 3 clients) now have proper KV access through their respective ACL policies.

### Enhanced Nomad Role

As part of this fix, the Nomad role was enhanced with proper Consul ACL integration:

**New Role Features**:

- `roles/nomad/files/consul-policies/` - Standardized ACL policy templates
- `roles/nomad/tasks/consul-acl.yml` - Automated ACL management
- Enhanced configuration templating with proper token assignment

**Policy Templates**:

- `nomad-server.hcl` - Server policy with KV access and ACL management
- `nomad-client.hcl` - Client policy with KV access for job templating

### Usage in Jobs

With the fix, Nomad jobs can now use Consul KV templating:

```hcl
template {
  data = <<EOT
    database_host={{ key "app/database/host" }}
    database_port={{ key "app/database/port" }}
  EOT
  destination = "local/config.env"
}
```

## Implementation Status

- ✅ Auth method configured and active
- ✅ JWKS endpoint accessible
- ✅ Basic policies and roles created
- ✅ **FIXED (Aug 10, 2025)**: Consul KV access for Nomad job templating
- ✅ **RESOLVED (Aug 10, 2025)**: Nomad now consistently derives workload tokens; service identity in use for workloads (ensure identity blocks with `aud=["consul.io"]` are present in jobs)

## References

- [Consul JWT Auth Method Documentation](https://developer.hashicorp.com/consul/docs/security/acl/auth-methods/jwt)
- [Nomad Service Identity Documentation](https://developer.hashicorp.com/nomad/docs/integrations/consul/service-identity)
- [Service Identity Troubleshooting](../../troubleshooting/service-identity-issues.md)
- [Nomad Job Standards](../../standards/nomad-job-standards.md#service-identity-requirements)
