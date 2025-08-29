# Vault PKI Root CA Setup Documentation

## Overview

This document covers the setup and configuration of HashiCorp Vault's PKI secrets engine as the Root Certificate Authority for the HomeLab infrastructure.

## Implementation Details

### PKI Engine Configuration

- **Mount Path**: `/pki`
- **Max Lease TTL**: 87600h (10 years)
- **Description**: Root Certificate Authority
- **Version**: v1.20.2+builtin.vault

### Root CA Certificate

- **Common Name**: HomeLab Root CA
- **Issuer Name**: root-ca-2025
- **Organization**: HomeLab
- **Organizational Unit**: Infrastructure
- **Key Type**: RSA 4096-bit
- **Validity Period**: 10 years (Aug 29, 2025 - Aug 27, 2035)
- **Serial Number**: 78:ac:94:b8:c7:15:09:75:09:f0:67:f7:37:71:e0:c0:7e:59:b2:a6

### Certificate Roles

#### Infrastructure Role
- **Purpose**: HashiCorp services (Vault, Consul, Nomad)
- **Allowed Domains**:
  - spaceships.work (with subdomains)
  - consul (bare domain)
  - nomad (bare domain)
  - vault (bare domain)
- **Max TTL**: 8760h (1 year)
- **Default TTL**: 720h (30 days)
- **Flags**: Server and Client certificates

#### Service Role
- **Purpose**: Application services
- **Allowed Domains**:
  - service.consul (with subdomains)
  - app.spaceships.work (with subdomains)
- **Max TTL**: 4320h (6 months)
- **Default TTL**: 168h (7 days)
- **Flags**: Server certificates only

#### Client Role
- **Purpose**: mTLS client certificates
- **Allowed Domains**:
  - client.spaceships.work (with subdomains)
- **Max TTL**: 720h (30 days)
- **Default TTL**: 24h (1 day)
- **Flags**: Client certificates only

## API Endpoints

### Public Endpoints (No Authentication Required)

- **CA Certificate**: `https://vault.spaceships.work:8200/v1/pki/ca`
- **CA Certificate (PEM)**: `https://vault.spaceships.work:8200/v1/pki/ca/pem`
- **CRL**: `https://vault.spaceships.work:8200/v1/pki/crl`
- **OCSP**: `https://vault.spaceships.work:8200/v1/pki/ocsp`

### Administrative Endpoints (Requires Vault Token)

- **Issue Certificate**: `POST /v1/pki/issue/{role_name}`
- **Sign CSR**: `POST /v1/pki/sign/{role_name}`
- **List Certificates**: `LIST /v1/pki/certs`
- **Revoke Certificate**: `POST /v1/pki/revoke`

## Usage Examples

### Issue a Certificate for Infrastructure

```bash
# Set environment variables
export VAULT_ADDR='https://vault.spaceships.work:8200'
export VAULT_TOKEN='your-token-here'

# Issue certificate for Consul server
vault write pki/issue/infrastructure \
    common_name="consul-server-1.consul" \
    ttl="720h"

# Issue certificate for Nomad server
vault write pki/issue/infrastructure \
    common_name="nomad-server-1.nomad" \
    ttl="720h"

# Issue certificate for Vault server
vault write pki/issue/infrastructure \
    common_name="vault-prod-1.vault" \
    ttl="720h"
```

### Issue a Certificate for Service

```bash
# Issue certificate for a service in Consul
vault write pki/issue/service \
    common_name="api.service.consul" \
    ttl="168h"

# Issue certificate for an application
vault write pki/issue/service \
    common_name="dashboard.app.spaceships.work" \
    ttl="168h"
```

### Issue a Client Certificate

```bash
# Issue mTLS client certificate
vault write pki/issue/client \
    common_name="user1.client.spaceships.work" \
    ttl="24h"
```

### Download CA Certificate

```bash
# Download CA certificate
curl -sk https://vault.spaceships.work:8200/v1/pki/ca/pem > homelab-root-ca.pem

# Verify certificate
openssl x509 -in homelab-root-ca.pem -text -noout
```

### Check CRL

```bash
# Download CRL
curl -sk https://vault.spaceships.work:8200/v1/pki/crl > vault-crl.crl

# View CRL details
openssl crl -in vault-crl.crl -inform DER -text -noout
```

## Automation

### Ansible Playbook

The PKI setup is automated via Ansible:

```bash
# Run the setup playbook
uv run ansible-playbook playbooks/infrastructure/vault/setup-pki-root-ca.yml \
  -i inventory/environments/vault-cluster/production.yaml
```

The playbook is idempotent and can be safely re-run to verify configuration.

### Required Environment Variables

- `VAULT_ADDR`: Vault server address (https://192.168.10.31:8200)
- `VAULT_TOKEN`: Vault root token or admin token
- `INFISICAL_UNIVERSAL_AUTH_CLIENT_ID`: For Infisical authentication
- `INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET`: For Infisical authentication

## Security Considerations

### Access Control

- The PKI mount is protected by Vault policies
- Only administrators should have access to create/modify roles
- Certificate issuance can be delegated via specific policies

### Certificate Validation

- All certificates include proper SANs (Subject Alternative Names)
- Hostnames are enforced via role configuration
- IP SANs are allowed for infrastructure certificates

### CRL Management

- CRL is automatically updated every 72 hours
- CRL is publicly accessible for certificate validation
- Revoked certificates are immediately added to CRL

### Backup and Recovery

- Root CA certificate is backed up in Infisical at `/apollo-13/pki/ROOT_CA_CERTIFICATE`
- Regular Vault backups include PKI configuration
- Recovery procedure documented in disaster recovery plan

## Monitoring and Alerts

### Key Metrics to Monitor

1. **Certificate Expiration**: Track certificates approaching expiration
2. **CRL Size**: Monitor CRL growth over time
3. **Issuance Rate**: Track certificate issuance patterns
4. **Revocation Rate**: Monitor unusual revocation activity

### Health Checks

```bash
# Check PKI engine status
vault secrets list -format=json | jq '.["pki/"]'

# Verify CA certificate
curl -sk https://vault.spaceships.work:8200/v1/pki/ca/pem | \
  openssl x509 -noout -dates

# Check CRL freshness
curl -sk https://vault.spaceships.work:8200/v1/pki/crl | \
  openssl crl -inform DER -noout -nextupdate
```

## Troubleshooting

### Common Issues

1. **Certificate Request Denied**
   - Verify the requested domain matches role's allowed_domains
   - Check TTL doesn't exceed role's max_ttl
   - Ensure proper Vault token permissions

2. **CRL Not Updating**
   - Check Vault server logs
   - Verify CRL configuration in PKI engine
   - Ensure Vault has write permissions to storage

3. **OCSP Not Responding**
   - Verify OCSP URL configuration
   - Check network connectivity
   - Review Vault audit logs

### Debug Commands

```bash
# Enable Vault debug logging
vault audit enable file file_path=/tmp/vault-audit.log

# Check PKI configuration
vault read pki/config/urls

# List all certificates
vault list pki/certs

# View specific certificate
vault read pki/cert/<serial_number>
```

## Next Steps

1. **Issue #96**: Create Intermediate CA for operational use
2. **Issue #97**: Replace self-signed certificates with PKI-issued certificates
3. **Issue #98**: Implement mTLS for service-to-service communication
4. **Issue #99**: Set up certificate rotation automation
5. **Issue #100**: Implement monitoring and alerting for PKI

## References

- [Vault PKI Secrets Engine Documentation](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [Ansible community.hashi_vault Collection](https://docs.ansible.com/ansible/latest/collections/community/hashi_vault/index.html)
- [X.509 Certificate Best Practices](https://developer.hashicorp.com/vault/docs/secrets/pki/considerations)
