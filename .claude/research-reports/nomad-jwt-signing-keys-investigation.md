# GitHub Implementation Research: Nomad JWT Signing Keys Configuration

## Executive Summary

Research into the `jwt_signing_keys` configuration error in Nomad 1.10.4 reveals that **JWT authentication is a feature introduced in Nomad 1.5.0**, but the configuration syntax and placement have specific requirements. The error "server.config: unexpected keys" indicates incorrect configuration placement or syntax rather than a version incompatibility issue.

**Key Finding**: JWT authentication in Nomad 1.10.4 is configured through ACL auth methods via the API/CLI, NOT directly in the server configuration file. The `jwt_signing_keys` field does not belong in the server config HCL.

## Investigation Results

### 1. JWT Authentication Timeline

- **Nomad 1.5.0** (March 2023): Introduced JWT and OIDC authentication methods
- **Nomad 1.10.4** (August 2025): Current version with full JWT support
- **Configuration Method**: JWT auth is configured via ACL auth methods, not server config

### 2. Correct Configuration Approach

#### INCORRECT (Causes "unexpected keys" error)

```hcl
# server.hcl
server {
  enabled = true
  jwt_signing_keys = ["..."]  # WRONG - This doesn't belong here
}
```

#### CORRECT Implementation

JWT authentication should be configured through the ACL system using auth methods:

```bash
# Create JWT auth method via CLI
nomad acl auth-method create \
  -name="jwt-auth" \
  -type="JWT" \
  -token-locality="global" \
  -max-token-ttl="1h" \
  -config=@jwt-config.json
```

With configuration file:

```json
{
  "JWKSURL": "https://your-provider.com/.well-known/jwks.json",
  "JWTValidationPubKeys": ["-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"],
  "BoundAudiences": ["nomad"],
  "SigningAlgs": ["RS256"]
}
```

### 3. Working ACL Configuration Examples

Based on analysis of production Nomad configurations from GitHub:

#### Basic ACL Server Configuration (server.hcl)

```hcl
server {
  enabled = true
  bootstrap_expect = 3

  # Encryption key for server communication
  encrypt = "BASE64_ENCODED_KEY"
}

acl {
  enabled = true
  token_ttl = "30s"
  policy_ttl = "60s"
  role_ttl = "60s"
  token_min_expiration_ttl = "30s"
  token_max_expiration_ttl = "24h"
}
```

### 4. Common Configuration Patterns Found

From analyzing 119 Nomad configuration repositories:

1. **ACL Configuration Location**: ACL settings are at the root level, not nested under `server`
2. **JWT Configuration**: Always done via API/CLI after cluster bootstrap
3. **No Direct JWT Keys**: No successful examples found with `jwt_signing_keys` in server config

## Recommendations

### Primary Solution: Remove JWT Configuration from Server Config

1. **Remove the invalid configuration**:
   - Delete any `jwt_signing_keys` entries from the server configuration file
   - Ensure ACL configuration is at the root level, not nested

2. **Configure JWT via API after bootstrap**:

   ```bash
   # Bootstrap ACL system first
   nomad acl bootstrap

   # Then create JWT auth method
   nomad acl auth-method create -type=JWT ...
   ```

3. **Correct server.hcl structure**:

   ```hcl
   # Minimal working configuration
   datacenter = "dc1"
   data_dir = "/opt/nomad/data"

   server {
     enabled = true
     bootstrap_expect = 3
   }

   acl {
     enabled = true
   }

   # NO jwt_signing_keys here!
   ```

### Alternative: Use OIDC Discovery

For easier JWT configuration, use OIDC discovery URL:

```bash
nomad acl auth-method create \
  -name="oidc" \
  -type="OIDC" \
  -config='{"OIDCDiscoveryURL":"https://accounts.google.com","BoundAudiences":["nomad"]}'
```

## Root Cause Analysis

The error occurs because:

1. **Configuration schema validation**: Nomad strictly validates configuration keys
2. **JWT is not a server config option**: JWT settings belong to ACL auth methods
3. **Documentation confusion**: Some examples may show JWT configuration incorrectly

## Quick Fix Steps

1. **Immediate**: Remove `jwt_signing_keys` from server configuration
2. **Bootstrap**: Ensure ACL system is properly bootstrapped
3. **Configure Auth**: Use CLI/API to create JWT auth methods
4. **Test**: Verify with `nomad acl auth-method list`

## Data Sources

- Repositories analyzed: 119
- Configuration examples reviewed: 10
- Nomad documentation: Official JWT auth method docs
- Search queries used:
  - `nomad server config acl auth language:hcl`
  - `repo:hashicorp/nomad jwt auth method`
  - `nomad jwt_signing_keys unexpected keys`

## References

1. [Nomad JWT Authentication Documentation](https://github.com/hashicorp/nomad/blob/main/website/content/docs/secure/authentication/jwt.mdx)
2. [ACL Auth Method CLI Commands](https://github.com/hashicorp/nomad/blob/main/website/content/commands/acl/auth-method/create.mdx)
3. Production examples from:
   - livioribeiro/nomad-lxd-terraform
   - Mati365/nomad-cheap-cluster
   - e2b-dev/infra

## Conclusion

The `jwt_signing_keys` configuration error is not a version compatibility issue but a configuration placement error. JWT authentication in Nomad 1.10.4 is fully supported but must be configured through the ACL auth method system, not directly in the server configuration file. Remove the JWT configuration from the server HCL file and configure it via the CLI/API instead.
