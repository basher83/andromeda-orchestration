# Vault Access and Operations Guide

## Current Deployment Status

**Environment**: Development Mode
**Deployment Date**: 2025-08-06
**Status**: ✅ Active on all nodes
**Production Deployment**: See [Implementation Guide](../implementation/vault/production-deployment.md)

### Node Details

| Node                 | Version | API Address                 | UI Address                     | Status |
| -------------------- | ------- | --------------------------- | ------------------------------ | ------ |
| nomad-server-1-lloyd | v1.15.5 | <http://192.168.10.11:8200> | <http://192.168.10.11:8200/ui> | Active |
| nomad-server-2-holly | v1.20.1 | <http://192.168.10.12:8200> | <http://192.168.10.12:8200/ui> | Active |
| nomad-server-3-mable | v1.20.1 | <http://192.168.10.13:8200> | <http://192.168.10.13:8200/ui> | Active |

## Authentication

### Development Mode Access

**⚠️ IMPORTANT**: Credentials are stored in Infisical for security.

To retrieve the dev token:

```bash
# Using Infisical CLI
infisical secrets get VAULT_PROD_ROOT_TOKEN --env=dev --path=/apollo-13/vault

# Or via environment (if Infisical is configured)
source <(infisical export --env=dev --path=/apollo-13/vault)

# Using Ansible lookup
vault_token: >-
  {{ (lookup('infisical.vault.read_secrets',
             universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
             universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
             project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
             env_slug='dev',
             path='/apollo-13/vault',
             secret_name='VAULT_DEV_ROOT_TOKEN')).value }}
```

### CLI Access

```bash
# Set environment variables
export VAULT_ADDR='http://192.168.10.11:8200'  # or .12, .13 for other nodes
export VAULT_TOKEN='<token-from-infisical>'

# Verify connection
vault status

# List secrets engines
vault secrets list

# Read test secret
vault kv get secret/test
```

### UI Access

1. Navigate to one of the UI addresses above
2. Sign in with Token method
3. Enter the root token from Infisical
4. Explore the UI for secret management

## Service Discovery

Vault services are registered in Consul:

```bash
# Query via Consul CLI
consul catalog services | grep vault

# DNS query (from a node with Consul DNS)
dig @127.0.0.1 -p 8600 vault.service.consul SRV
```

## Common Operations

### Create a Secret

```bash
vault kv put secret/myapp/config \
    username='appuser' \
    password='changeme' \
    api_key='abc123'
```

### Read a Secret

```bash
vault kv get secret/myapp/config
vault kv get -format=json secret/myapp/config | jq
```

### List Secrets

```bash
vault kv list secret/
```

### Enable New Secrets Engine

```bash
vault secrets enable -path=kv-v2 kv-v2
```

## Monitoring

### Health Check

```bash
# Via API
curl -s http://192.168.10.11:8200/v1/sys/health | jq

# Via CLI
vault status
```

### Logs

```bash
# On any vault node
sudo journalctl -u vault -f
```

## Security Considerations

### Development Mode Limitations

⚠️ **Current deployment is in DEVELOPMENT mode**:

- **No persistence**: All data is lost on restart
- **Auto-unsealed**: No unseal keys required
- **No TLS**: HTTP only, not HTTPS
- **Fixed root token**: Not randomly generated
- **Not for production**: Only for testing and exploration

### Production Migration Path

When ready for production:

1. Use `playbooks/infrastructure/vault/deploy-vault-prod.yml`
2. Configure Raft storage backend for HA
3. Enable TLS with proper certificates
4. Implement auto-unseal (Transit, AWS KMS, etc.)
5. Configure proper authentication methods (LDAP, OIDC, etc.)
6. Set up audit logging
7. Implement backup procedures

## Troubleshooting

### Service Won't Start

```bash
# Check service status
sudo systemctl status vault

# Check logs
sudo journalctl -xeu vault.service -n 50

# Verify config (production mode only)
sudo vault operator diagnose -config=/etc/vault.d/vault.hcl
```

### Connection Refused

1. Check firewall rules
2. Verify service is running
3. Confirm correct IP and port
4. Check network connectivity

### Lost Root Token

In dev mode, restart the service with a new token:

```bash
sudo systemctl stop vault
# Edit /etc/systemd/system/vault.service to change token
sudo systemctl daemon-reload
sudo systemctl start vault
```

## Integration Points

### Nomad Integration

JWT authentication is prepared but not yet configured. To enable:

1. Configure Vault JWT auth method
2. Update Nomad server configuration
3. Create appropriate policies
4. Test workload identity tokens

### Consul Integration

Services are registered but not using Consul backend. For production:

1. Consider Consul as storage backend
2. Use Consul for service mesh integration
3. Implement Consul template for secret rotation

## Next Steps

1. **Explore Vault features** in dev mode
2. **Define secret hierarchy** for the organization
3. **Plan authentication methods** (users, services, CI/CD)
4. **Design policies** for least privilege access
5. **Prepare for production** deployment when ready

## Related Documentation

- [Vault Deployment Strategy](../implementation/vault/deployment-strategy.md)
- [Enhanced Deployment Strategy](../implementation/vault/enhanced-deployment-strategy.md)
- [Vault Architecture Diagram](../diagrams/vault-architecture.md)
- [HashiCorp Stack Integration](../diagrams/hashicorp-stack-integration.md)
