# Vault Access and Operations Guide

## Current Deployment Status

**Environment**: Production with PKI Certificates
**Deployment Date**: 2025-08-30 (PKI certificates)
**Status**: ✅ Active on all nodes with TLS/HTTPS
**Certificate Authority**: HomeLab Intermediate CA
**Certificate Validity**: 30 days (renewal required)

### Production Cluster Details

| Node                 | Version | API Address                  | UI Address                      | Status | Certificate Serial |
| -------------------- | ------- | ---------------------------- | ------------------------------- | ------ | ------------------ |
| vault-master-lloyd   | v1.20.1 | <http://192.168.10.30:8200>  | <http://192.168.10.30:8200/ui>  | Active | Transit Master (HTTP) |
| vault-prod-1-holly   | v1.20.1 | <https://192.168.10.31:8200> | <https://192.168.10.31:8200/ui> | Active | 10:4d:e5:dc... |
| vault-prod-2-mable   | v1.20.1 | <https://192.168.10.32:8200> | <https://192.168.10.32:8200/ui> | Active | 12:dc:60:48... |
| vault-prod-3-lloyd   | v1.20.1 | <https://192.168.10.33:8200> | <https://192.168.10.33:8200/ui> | Active | 19:74:88:26... |

## Authentication

### Production Access

**⚠️ IMPORTANT**: Credentials are stored in Infisical for security.

To retrieve the production root token:

```bash
# Using Infisical CLI
infisical secrets get VAULT_PROD_ROOT_TOKEN --env=prod --path=/apollo-13/vault

# Or via environment (if Infisical is configured)
source <(infisical export --env=prod --path=/apollo-13/vault)

# Using Ansible lookup
vault_token: >-
  {{ (lookup('infisical.vault.read_secrets',
             universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
             universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
             project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
             env_slug='prod',
             path='/apollo-13/vault',
             secret_name='VAULT_PROD_ROOT_TOKEN')).value }}
```

### CLI Access

```bash
# Set environment variables (use HTTPS for production nodes)
export VAULT_ADDR='https://192.168.10.33:8200'  # or .31, .32 for other prod nodes
export VAULT_TOKEN='<token-from-infisical>'
# Skip certificate verification if CA not in trust store (temporary)
export VAULT_SKIP_VERIFY=true  # Remove once CA is in system trust store

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
# Via API (HTTPS with certificate validation)
curl -s https://192.168.10.33:8200/v1/sys/health | jq

# Via CLI
vault status

# Via Consul (with token)
CONSUL_HTTP_TOKEN=<consul-token> consul catalog nodes -service=vault -detailed
```

### Logs

```bash
# On any vault node
sudo journalctl -u vault -f
```

## Security Considerations

### Production Deployment Features

✅ **Current deployment is in PRODUCTION mode**:

- **Raft Storage**: Persistent, replicated storage across 3 nodes
- **Auto-unseal**: Using Transit master for automatic unsealing
- **TLS/HTTPS Enabled**: PKI-issued certificates from HomeLab Intermediate CA
- **Certificate Details**:
  - Issuer: HomeLab Intermediate CA
  - Validity: 30 days
  - Auto-renewal: Pending (Issue #99)
  - Health checks: Validated by Consul
- **High Availability**: 3-node Raft cluster
- **Consul Integration**: Service discovery and health monitoring

### PKI Certificate Management

**Implemented (Issue #97)**:
- All production nodes using CA-issued certificates
- Certificates stored in `/opt/vault/tls/`
- Backup certificates in `/opt/vault/tls/backup-*`
- Consul health checks validate certificates

**Next Steps**:
1. Implement automated certificate renewal (Issue #99)
2. Enable mTLS for service communication (Issue #98)
3. Set up monitoring for certificate expiry (Issue #100)

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

## PKI Infrastructure

### Certificate Hierarchy

```
Root CA (HomeLab Root CA)
└── Intermediate CA (HomeLab Intermediate CA)
    ├── vault-prod-1-holly.vault.spaceships.work
    ├── vault-prod-2-mable.vault.spaceships.work
    └── vault-prod-3-lloyd.vault.spaceships.work
```

### Certificate Operations

```bash
# Verify certificate on a node
openssl verify -CAfile /opt/vault/tls/ca-bundle.pem /opt/vault/tls/tls.crt

# Check certificate details
openssl x509 -in /opt/vault/tls/tls.crt -text -noout

# Test TLS connection
openssl s_client -connect vault-prod-1-holly:8200 -CAfile /opt/vault/tls/ca-bundle.pem
```

### Playbooks for PKI Management

- `playbooks/infrastructure/vault/setup-pki-root-ca.yml` - Root CA setup
- `playbooks/infrastructure/vault/setup-pki-intermediate-ca.yml` - Intermediate CA
- `playbooks/infrastructure/vault/replace-self-signed-certificates.yml` - Deploy PKI certificates
- `playbooks/infrastructure/vault/automated-certificate-renewal.yml` - Auto-renewal (pending)
- `playbooks/infrastructure/vault/monitor-pki-certificates.yml` - Certificate monitoring

## Related Documentation

- [Vault Deployment Strategy](../implementation/vault/deployment-strategy.md)
- [Enhanced Deployment Strategy](../implementation/vault/enhanced-deployment-strategy.md)
- [Vault Architecture Diagram](../diagrams/vault-architecture.md)
- [HashiCorp Stack Integration](../diagrams/hashicorp-stack-integration.md)
- [PKI Infrastructure Implementation (Issue #94)](https://github.com/basher83/andromeda-orchestration/issues/94)
