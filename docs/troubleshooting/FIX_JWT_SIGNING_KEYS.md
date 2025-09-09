# Fix JWT Signing Keys for Service Registration

## Problem Summary

All Nomad services (PostgreSQL, Traefik, etc.) are failing to register in Consul because Nomad cannot generate JWT tokens for service identity. The root cause is that JWT signing keys are not configured correctly in Nomad 1.10.x.

## Solution

The playbook `playbooks/infrastructure/nomad/setup-jwt-signing.yml` has been fixed to properly configure JWT signing keys **inside the server stanza** (not as a standalone jwt block).

## Execution Steps

### Step 1: Run from your local environment with SSH access

```bash
# Navigate to the repository
cd /path/to/netbox-ansible

# Run the fixed playbook using the appropriate inventory
# Option A: If you have the Proxmox dynamic inventory working
uv run ansible-playbook playbooks/infrastructure/nomad/setup-jwt-signing.yml \
  -i inventory/environments/doggos-homelab/proxmox.yml

# Option B: Using static inventory (if Proxmox plugin not available)
uv run ansible-playbook playbooks/infrastructure/nomad/setup-jwt-signing.yml \
  -i inventory/environments/doggos-homelab/static-nomad.yml

# Option C: If you need to specify SSH key
uv run ansible-playbook playbooks/infrastructure/nomad/setup-jwt-signing.yml \
  -i inventory/environments/doggos-homelab/static-nomad.yml \
  --private-key ~/.ssh/your-homelab-key
```

### Step 2: Verify JWT Configuration

After the playbook runs, verify the configuration on each Nomad server:

```bash
# SSH to a Nomad server
ssh root@192.168.10.11  # nomad-server-1-lloyd

# Check that jwt_signing_keys is in the config
grep jwt_signing_keys /etc/nomad.d/nomad.hcl

# Should see something like:
#   jwt_signing_keys = ["LS0tLS1CRUdJTi..."]

# Verify Nomad is running
systemctl status nomad

# Check JWKS endpoint
curl -s http://192.168.11.11:4646/.well-known/jwks.json | jq .
```

### Step 3: Redeploy PostgreSQL to Test

```bash
# Navigate to the PostgreSQL job directory
cd nomad-jobs/platform-services/postgresql/

# Redeploy with the variables file
nomad job run -var-file="postgresql.variables.hcl" postgresql.nomad.hcl
```

### Step 4: Verify Service Registration

```bash
# Check if PostgreSQL now appears in Consul
consul catalog services

# Should see 'postgres' in the list

# Check service details
consul catalog service postgres

# Verify through Consul UI
# Browse to: http://192.168.11.11:8500/ui/dc1/services
```

## Manual Alternative (if Ansible doesn't work)

If you can't run the Ansible playbook, here's how to fix it manually on each Nomad server:

### 1. Generate JWT signing key on each server

```bash
# SSH to each Nomad server
ssh root@192.168.10.11  # Repeat for .12 and .13

# Create key directory
mkdir -p /etc/nomad.d/jwt-keys
cd /etc/nomad.d/jwt-keys

# Generate RSA key
openssl genrsa -out jwt-signing-key.pem 4096
chown nomad:nomad jwt-signing-key.pem
chmod 600 jwt-signing-key.pem

# Base64 encode the key
JWT_KEY=$(base64 -w0 jwt-signing-key.pem)
echo "Your base64 key: $JWT_KEY"
```

### 2. Edit Nomad configuration

```bash
# Edit the Nomad config
vi /etc/nomad.d/nomad.hcl

# Find the server stanza (looks like):
server {
  enabled = true
  bootstrap_expect = 3
  # ... other settings
}

# Add jwt_signing_keys INSIDE the server block:
server {
  enabled = true
  bootstrap_expect = 3

  # Add this line (replace with your actual base64 key)
  jwt_signing_keys = ["LS0tLS1CRUdJTi...your-base64-key-here..."]

  # ... rest of server config
}
```

### 3. Validate and restart

```bash
# Validate configuration
nomad config validate /etc/nomad.d/

# Restart Nomad
systemctl restart nomad

# Check status
systemctl status nomad

# Verify JWKS endpoint
curl -s http://localhost:4646/.well-known/jwks.json
```

## Troubleshooting

### If configuration validation fails

- Make sure `jwt_signing_keys` is INSIDE the `server { }` block
- Ensure you're using `jwt_signing_keys` (plural) not `jwt_signing_key`
- Check the base64 encoding has no line breaks (use -w0 flag)

### If services still don't register

1. Check Nomad logs: `journalctl -u nomad -f`
2. Verify service has identity block:

   ```hcl
   service {
     name = "postgres"
     identity {
       aud = ["consul.io"]
     }
   }
   ```

3. Check Consul auth method: `consul acl auth-method read nomad-workloads`
4. Verify binding rule exists: `consul acl binding-rule list -method=nomad-workloads`

## Expected Outcome

After applying this fix:

1. ✅ Nomad can generate JWT tokens for workloads
2. ✅ Services with identity blocks register in Consul
3. ✅ PostgreSQL appears in `consul catalog services`
4. ✅ Service discovery works via DNS: `dig @192.168.11.11 -p 8600 postgres.service.consul`
5. ✅ Health checks function properly

## Related Documentation

- Fixed investigation: `docs/troubleshooting/investigations/2025-01-09-postgresql-service-registration.md`
- Updated guide: `docs/troubleshooting/service-identity-issues.md`
