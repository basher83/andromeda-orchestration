# Consul ACL Integration Guide for Nomad

## Current Status

The Consul-Nomad integration is blocked by Consul ACL requirements. Consul is configured with ACLs enabled, which requires authentication tokens for all operations.

## Problem

- Consul ACL is already bootstrapped (not a fresh installation)
- Management token is required to create new policies and tokens
- Without the management token, we cannot create tokens for Nomad
- Nomad cannot register services without proper ACL tokens

## Options

### Option 1: Retrieve Existing Management Token
If you have access to the management token:
1. Check Infisical: `/consul/tokens/management`
2. Check your password manager (1Password, etc.)
3. Check with the person who initially bootstrapped Consul

### Option 2: Disable ACLs Temporarily
1. SSH to Consul servers
2. Edit `/etc/consul.d/consul.hcl`
3. Set `acl { enabled = false }`
4. Restart Consul
5. Configure integration
6. Re-enable ACLs

### Option 3: Reset ACL System
**WARNING**: This will invalidate all existing tokens
1. Stop Consul on all servers
2. Delete ACL data: `rm -rf /opt/consul/data/acl-*`
3. Start Consul
4. Re-bootstrap ACL system
5. Recreate all tokens

### Option 4: Use Anonymous Token
Configure Nomad to work without tokens (insecure):
1. Update Consul ACL default policy to allow
2. Not recommended for production

## Recommended Approach

Since this is a homelab environment, the safest approach is:

1. **First, try to locate the management token**:
   - Check documentation
   - Check Infisical
   - Check password managers

2. **If token cannot be found**, temporarily disable ACLs:
   ```bash
   # On all Consul servers
   sudo sed -i 's/enabled = true/enabled = false/' /etc/consul.d/consul.hcl
   sudo systemctl restart consul
   ```

3. **Configure integration without ACLs**:
   - Verify Nomad can register services
   - Test service discovery

4. **Re-enable ACLs** with proper configuration:
   - Bootstrap new ACL system
   - Create appropriate policies
   - Generate tokens for all services
   - Store tokens in Infisical

## Manual Token Creation

If you have the management token, create tokens manually:

```bash
# Create policy for Nomad servers
consul acl policy create -name nomad-server \
  -rules @- <<EOF
agent_prefix "" { policy = "read" }
node_prefix "" { policy = "read" }
service_prefix "" { policy = "write" }
acl = "write"
EOF

# Create token for Nomad servers
consul acl token create \
  -description "Token for Nomad servers" \
  -policy-name nomad-server

# Update Nomad configuration with the token
```

## Next Steps

1. Decide on approach based on your access level
2. If you have the management token, provide it when prompted
3. If not, consider temporarily disabling ACLs
4. Document the final token configuration for future reference
