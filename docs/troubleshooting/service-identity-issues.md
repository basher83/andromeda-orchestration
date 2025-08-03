# Service Identity Token Issues

This document tracks the current issues with Nomad service identity token derivation and Consul integration.

## Issue Summary

When deploying services with Consul service blocks in Nomad, the workload identity tokens are not being properly derived. Instead, workloads are using the Nomad client's token, which lacks necessary permissions.

## Symptoms

1. **PowerDNS Deployment Failures**:
   ```
   Template failed: kv.get(powerdns/mysql/password): Unexpected response code: 403 
   (rpc error making call: Permission denied: token with AccessorID '05081fff-66cc-58ba-2bb3-88f9cd4f1780' 
   lacks permission 'key:read' on "powerdns/mysql/password")
   ```

2. **Service Registration Errors**:
   ```
   failed to derive Consul token for service powerdns: 
   Unexpected response code: 403 (rpc error making call: ACL not found: 
   auth method "nomad-workloads" not found)
   ```

## Current Configuration

### Nomad Configuration
- Service identities enabled in Nomad servers and clients:
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

### Consul Auth Method
- Created JWT auth method "nomad-workloads"
- JWKS URL: http://192.168.11.11:4646/.well-known/jwks.json
- Bound audiences: ["consul.io"]
- Binding rule: Role binding to "nomad-workload" role
- Role has policies: nomad-workload-identity, nomad-workload-kv

### Service Configuration
Jobs require identity blocks with aud values:
```hcl
service {
  name = "myservice"
  identity {
    aud = ["consul.io"]
  }
}
```

## Root Cause Analysis

1. **Token Not Being Derived**: The Nomad workload is using the Nomad client's Consul token (05081fff-66cc-58ba-2bb3-88f9cd4f1780) instead of deriving a new token via the auth method.

2. **Auth Method Configuration**: While the auth method is properly configured, the token derivation process is not happening during job allocation.

3. **Missing Claims**: The auth method expects claims like `nomad_service` which may not be present in the JWT token.

## Workaround

Currently deploying services without service identity blocks and using hardcoded values instead of Consul KV lookups.

## Investigation Steps

1. Verify Nomad is generating JWT tokens for workloads
2. Check if tokens contain expected claims (nomad_namespace, nomad_job_id, nomad_task, nomad_service)
3. Verify auth method can validate tokens from Nomad
4. Check Nomad logs for token derivation attempts
5. Verify Consul can reach Nomad's JWKS endpoint from all nodes

## Investigation Results (2025-08-02)

After thorough investigation using Netdata monitoring and direct system checks:

1. **Consul Auth Method Status**: The `nomad-workloads` auth method is properly configured:
   - JWKS URL is accessible: http://192.168.11.11:4646/.well-known/jwks.json
   - Bound audiences: ["consul.io"]
   - Binding rule links to `nomad-workload` role
   - Role has appropriate policies for KV read access

2. **Token Usage**: Jobs are using the Nomad client's Consul token (AccessorID: 05081fff-66cc-58ba-2bb3-88f9cd4f1780) instead of deriving workload-specific tokens

3. **Current Workaround**: Deploy services without service blocks to avoid identity validation errors:
   - Created `powerdns-no-services.nomad.hcl` without any service blocks
   - PowerDNS successfully deployed and running
   - Traefik running with service blocks (somehow working)

4. **Root Cause**: Nomad is not attempting to derive workload identity tokens. The issue appears to be in the Nomad configuration or the linkage between Nomad and the Consul auth method.

## Related Issues

- Consul ACL permissions for nodes (fixed)
- Multiple Consul configuration blocks (fixed)
- Docker nftables compatibility (fixed)

## References

- [Nomad Service Identity Documentation](https://developer.hashicorp.com/nomad/docs/integrations/consul/service-identity)
- [Consul Auth Methods](https://developer.hashicorp.com/consul/docs/security/acl/auth-methods)
- [JWT Auth Method](https://developer.hashicorp.com/consul/docs/security/acl/auth-methods/jwt)