# Vault PKI Certificate Replacement Documentation

## Overview

This document covers the process of replacing self-signed certificates with PKI-issued certificates for the Vault cluster nodes.

## Current Implementation Status

✅ **COMPLETE** - All production Vault nodes have PKI-issued certificates as of 2025-08-29

| Node | IP Address | Serial Number | Status |
|------|------------|---------------|--------|
| vault-prod-1-holly | 192.168.10.31 | `1f:46:19:2f:38:c9:cb:e8:43:47:7b:e3:6a:21:a4:e3:b0:bd:23:71` | ✅ Complete |
| vault-prod-2-mable | 192.168.10.32 | `35:54:ed:b1:cc:ca:39:e1:0d:b7:f7:e5:33:60:6f:d7:8b:4d:0e:5e` | ✅ Complete |
| vault-prod-3-lloyd | 192.168.10.33 | `5b:e4:20:fe:f9:2a:5a:0c:2c:53:57:07:21:7b:6f:60:8a:a9:e7:d1` | ✅ Complete |
| vault-master-lloyd | 192.168.10.30 | N/A - Dev mode (HTTP only) | ⏳ Issue #99 |

## Certificate Details

### PKI Hierarchy

```text
HomeLab Root CA (10 years)
    └── HomeLab Intermediate CA (5 years)
        └── Vault Service Certificates (30 days)
```

### Certificate Configuration

- **Issuer**: HomeLab Intermediate CA
- **Key Type**: RSA 2048-bit
- **TTL**: 30 days (720h)
- **Common Name Pattern**: `{hostname}.vault.spaceships.work`
- **Subject Alternative Names**:
  - `{hostname}`
  - `vault.service.consul`
  - `{hostname}.vault`
  - `localhost`
- **IP SANs**:
  - Node IP address
  - `127.0.0.1`

## File Locations

### On Vault Nodes

| File | Path | Description | Permissions |
|------|------|-------------|-------------|
| Certificate | `/opt/vault/tls/tls.crt` | Server certificate | 644 (vault:vault) |
| Private Key | `/opt/vault/tls/tls.key` | Private key | 600 (vault:vault) |
| CA Bundle | `/opt/vault/tls/ca-bundle.pem` | CA chain | 644 (vault:vault) |
| Backup | `/opt/vault/tls/backup-{epoch}/` | Backup directory | 700 (vault:vault) |
| System CA | `/usr/local/share/ca-certificates/vault-ca-chain.crt` | System trust store | 644 (root:root) |

### Vault Configuration

Vault expects certificates at:

```hcl
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = false
  tls_cert_file = "/opt/vault/tls/tls.crt"
  tls_key_file = "/opt/vault/tls/tls.key"
}
```

## Deployment Process

### Prerequisites

1. **SSH Access**: Ensure you have the production SSH key:

```bash
# The key should be at ~/.ssh/production
ls -la ~/.ssh/production
```

1. **Infisical Authentication**: Set environment variables:

```bash
export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID='your-client-id'
export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET='your-client-secret'
```

1. **Vault Leader Identification**: The playbook must point to the active Vault leader:

   - Check with: `vault status` on each node
   - Update `vault_addr` in playbook if leader changes
   - Current leader (2025-08-29): vault-prod-3-lloyd (192.168.10.33)

2. **PKI Infrastructure**: Ensure intermediate CA is configured (Issue #96)

### Single Node Deployment

Deploy to a specific node:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/replace-self-signed-certificates.yml \
  -i inventory/environments/vault-cluster/production.yaml \
  --limit vault-prod-1-holly
```

### Full Cluster Deployment

Deploy to all nodes (serial execution for zero downtime):

```bash
uv run ansible-playbook playbooks/infrastructure/vault/replace-self-signed-certificates.yml \
  -i inventory/environments/vault-cluster/production.yaml
```

### Deployment Steps (Automated)

1. **Backup Phase**:
   - Create timestamped backup directory
   - Check for existing certificates
   - Copy existing certificates to backup

2. **Generation Phase**:
   - Request certificate from intermediate CA
   - Validate certificate parameters
   - Generate with 30-day TTL

3. **Deployment Phase**:
   - Write certificate to `/opt/vault/tls/tls.crt`
   - Write private key to `/opt/vault/tls/tls.key`
   - Deploy CA chain bundle
   - Update system trust store

4. **Validation Phase**:
   - Verify certificate chain
   - Reload Vault service
   - Check health endpoint
   - Validate TLS connection

## Manual Certificate Generation

If needed, certificates can be generated manually:

```bash
# Generate certificate for a Vault node
vault write pki_int/issue/infrastructure \
    common_name="vault-prod-1-holly.vault.spaceships.work" \
    alt_names="vault-prod-1-holly,vault.service.consul,localhost" \
    ip_sans="192.168.10.31,127.0.0.1" \
    ttl="720h" \
    -format=json > vault-cert.json

# Extract certificate and key
jq -r '.data.certificate' vault-cert.json > tls.crt
jq -r '.data.private_key' vault-cert.json > tls.key
jq -r '.data.ca_chain[]' vault-cert.json > ca-chain.pem

# Deploy to node
scp tls.crt tls.key ca-chain.pem ansible@192.168.10.31:/tmp/
ssh ansible@192.168.10.31 "sudo mv /tmp/tls.* /opt/vault/tls/ && \
    sudo chown vault:vault /opt/vault/tls/tls.* && \
    sudo chmod 644 /opt/vault/tls/tls.crt && \
    sudo chmod 600 /opt/vault/tls/tls.key && \
    sudo systemctl restart vault"
```

## Verification

### Certificate Validation

```bash
# Check certificate details
echo | openssl s_client -connect 192.168.10.31:8200 -servername vault-prod-1-holly.vault.spaceships.work 2>/dev/null | \
  openssl x509 -noout -text | grep -E "(Subject:|Issuer:|Not After)"

# Verify certificate chain
openssl verify -CAfile ca-chain.pem tls.crt

# Check certificate expiration
openssl x509 -in tls.crt -noout -enddate
```

### Vault Health Check

```bash
# Check Vault health
curl -sk https://192.168.10.31:8200/v1/sys/health | jq '.'

# Verify TLS with certificate validation
curl -v --cacert ca-chain.pem https://vault-prod-1-holly.vault.spaceships.work:8200/v1/sys/health
```

## Consul Integration

### Service Definition

After certificate deployment, update Consul service:

```json
{
  "service": {
    "name": "vault",
    "tags": ["vault", "production", "pki-secured"],
    "port": 8200,
    "check": {
      "id": "vault-health",
      "name": "Vault Health Check",
      "http": "https://192.168.10.31:8200/v1/sys/health",
      "tls_skip_verify": false,
      "interval": "10s",
      "timeout": "5s"
    }
  }
}
```

## Certificate Renewal

### Manual Renewal

Before certificate expiration (30 days):

```bash
# Check expiration
vault list -format=json pki_int/certs | \
  xargs -I {} vault read -format=json pki_int/cert/{} | \
  jq -r '.data.certificate' | \
  openssl x509 -noout -enddate

# Renew using playbook
uv run ansible-playbook playbooks/infrastructure/vault/replace-self-signed-certificates.yml \
  -i inventory/environments/vault-cluster/production.yaml
```

### Automated Renewal (Future - Issue #99)

Automated renewal will be implemented using:

- Scheduled Ansible playbook runs
- Certificate expiration monitoring
- Automatic rotation before expiry

## Rollback Procedure

If issues occur, rollback to previous certificates:

```bash
# On affected node
ssh ansible@<node-ip>

# Find backup directory
ls -la /opt/vault/tls/backup-*

# Restore certificates
sudo cp /opt/vault/tls/backup-{epoch}/tls.crt /opt/vault/tls/
sudo cp /opt/vault/tls/backup-{epoch}/tls.key /opt/vault/tls/
sudo chown vault:vault /opt/vault/tls/tls.*
sudo chmod 644 /opt/vault/tls/tls.crt
sudo chmod 600 /opt/vault/tls/tls.key

# Restart Vault
sudo systemctl restart vault

# Verify
curl -sk https://<node-ip>:8200/v1/sys/health
```

## Troubleshooting

### Common Issues

1. **Certificate Not Accepted**
   - Check allowed domains in PKI role
   - Verify SANs match role configuration
   - Ensure TTL doesn't exceed max_ttl

2. **Vault Won't Start After Certificate Change**
   - Check file permissions (600 for key, 644 for cert)
   - Verify certificate and key match
   - Check Vault logs: `journalctl -u vault -n 50`

3. **TLS Verification Failures**
   - Ensure CA chain is complete
   - Update system trust store: `update-ca-certificates`
   - Verify intermediate CA is in chain

### Debug Commands

```bash
# Check certificate and key match
openssl x509 -noout -modulus -in tls.crt | openssl md5
openssl rsa -noout -modulus -in tls.key | openssl md5

# View certificate details
openssl x509 -in tls.crt -text -noout

# Test TLS connection
openssl s_client -connect <node-ip>:8200 -CAfile ca-chain.pem

# Check Vault service status
systemctl status vault
journalctl -u vault -f
```

## Security Considerations

1. **Certificate Lifetime**: 30-day certificates require regular rotation
2. **Private Key Protection**: Keys are mode 600, owned by vault user
3. **Backup Retention**: Keep at least 2 generations of backups
4. **Audit Trail**: All certificate operations logged in Vault audit log
5. **Zero Downtime**: Serial deployment ensures service availability

## Automation and Monitoring

### Available Playbooks

1. **Certificate Deployment**: `replace-self-signed-certificates.yml`
   - Deploys PKI-issued certificates to Vault nodes
   - Supports serial execution for zero downtime
   - Creates automatic backups before replacement

2. **Certificate Validation**: `validate-pki-certificates.yml`
   - Comprehensive certificate validation
   - Chain verification and expiry checks
   - Certificate/key matching validation

3. **Certificate Monitoring**: `monitor-pki-certificates.yml`
   - Uses Vault API to track all issued certificates
   - Checks expiration dates across cluster
   - Generates renewal recommendations

4. **Automated Renewal**: `automated-certificate-renewal.yml`
   - Automatically renews expiring certificates
   - Configurable threshold (default: 7 days)
   - Zero-downtime serial processing

5. **Consul Integration**: `update-consul-vault-integration.yml`
   - Deploys CA bundle to Consul agents
   - Updates service definitions
   - Validates health checks

6. **TLS Status Check**: `check-vault-tls-status.yml`
   - Quick TLS configuration assessment
   - Port and connectivity verification
   - Service status reporting

### Nomad Periodic Job

Deploy automated monitoring with Nomad:

```bash
# Deploy the monitoring job
nomad job run nomad-jobs/platform-services/vault-pki-monitor.nomad.hcl

# Check job status
nomad job status vault-pki-monitor

# View recent runs
nomad job history vault-pki-monitor
```

The job runs every 6 hours and checks certificate expiration across the cluster.

### Manual Operations

#### Check Certificate Status

```bash
# Quick status check
uv run ansible-playbook playbooks/infrastructure/vault/validate-pki-certificates.yml \
  -i inventory/environments/vault-cluster/production.yaml

# Detailed monitoring with Vault API
uv run ansible-playbook playbooks/infrastructure/vault/monitor-pki-certificates.yml \
  -i inventory/environments/vault-cluster/production.yaml
```

#### Trigger Automatic Renewal

```bash
# Automatic renewal (only renews if needed)
uv run ansible-playbook playbooks/infrastructure/vault/automated-certificate-renewal.yml \
  -i inventory/environments/vault-cluster/production.yaml

# Force renewal for specific node
uv run ansible-playbook playbooks/infrastructure/vault/replace-self-signed-certificates.yml \
  -i inventory/environments/vault-cluster/production.yaml \
  --limit vault-prod-1-holly
```

### Monitoring Best Practices

1. **Regular Checks**: Run validation playbook daily via cron or Nomad
2. **Threshold Alerts**: Set warning at 7 days, critical at 3 days
3. **Automatic Renewal**: Enable automated renewal at 7-day threshold
4. **Backup Retention**: Keep last 3 certificate backups per node
5. **Audit Logging**: All certificate operations logged in Vault audit

## Next Steps

1. ~~Complete deployment to remaining nodes~~ ✅
2. ~~Implement automated renewal~~ ✅ (Issue #100)
3. Enable mTLS for client authentication (Issue #98)
4. ~~Set up monitoring and alerting~~ ✅ (Issue #100)
5. Plan vault-master migration to production mode (Issue #99)

## References

- [Vault PKI Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [Ansible community.hashi_vault Collection](https://docs.ansible.com/ansible/latest/collections/community/hashi_vault/index.html)
- [OpenSSL Certificate Verification](https://www.openssl.org/docs/man1.1.1/man1/verify.html)
