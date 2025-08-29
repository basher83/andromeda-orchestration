# Vault PKI Intermediate CA Setup Documentation

## Overview

This document covers the setup and configuration of HashiCorp Vault's PKI Intermediate Certificate Authority for issuing service certificates in the HomeLab infrastructure.

## PKI Hierarchy

```
HomeLab Root CA (10 years)
    └── HomeLab Intermediate CA (5 years)
        ├── Infrastructure Certificates (30 days max)
        ├── Application Certificates (7 days max)
        └── Database Certificates (30 days max)
```

## Implementation Details

### Intermediate PKI Engine Configuration

- **Mount Path**: `/pki_int`
- **Max Lease TTL**: 43800h (5 years)
- **Description**: Intermediate Certificate Authority
- **Version**: v1.20.2+builtin.vault

### Intermediate CA Certificate

- **Common Name**: HomeLab Intermediate CA
- **Issuer Name**: homelab-int-ca-2025
- **Organization**: HomeLab
- **Organizational Unit**: Infrastructure Services
- **Key Type**: RSA 4096-bit
- **Validity Period**: 5 years
- **Signed By**: HomeLab Root CA
- **Max Path Length**: 1 (can only issue end-entity certificates, not sub-CAs)

### Certificate Roles

#### Infrastructure Role
- **Purpose**: HashiCorp services (Vault, Consul, Nomad)
- **Allowed Domains**:
  - `consul.service.consul`
  - `nomad.service.consul`
  - `vault.spaceships.work`
  - `*.consul`
  - `*.nomad`
  - `*.vault`
- **Max TTL**: 720h (30 days)
- **Default TTL**: 168h (7 days)
- **Flags**: Server and Client certificates
- **Key Size**: RSA 2048-bit

#### Application Role
- **Purpose**: Application services
- **Allowed Domains**:
  - `*.spaceships.work`
  - `*.app.local`
  - `*.service.consul`
- **Max TTL**: 168h (7 days)
- **Default TTL**: 24h (1 day)
- **Flags**: Server certificates only
- **Key Size**: RSA 2048-bit

#### Database Role
- **Purpose**: Database services
- **Allowed Domains**:
  - `*.db.local`
  - `*.database.consul`
  - `postgres.spaceships.work`
  - `mysql.spaceships.work`
- **Max TTL**: 720h (30 days)
- **Default TTL**: 168h (7 days)
- **Flags**: Server and Client certificates
- **Key Size**: RSA 2048-bit

## API Endpoints

### Public Endpoints (No Authentication Required)

- **CA Certificate**: `https://vault.spaceships.work:8200/v1/pki_int/ca`
- **CA Certificate (PEM)**: `https://vault.spaceships.work:8200/v1/pki_int/ca/pem`
- **CA Certificate Chain**: `https://vault.spaceships.work:8200/v1/pki_int/ca-chain`
- **CRL**: `https://vault.spaceships.work:8200/v1/pki_int/crl`
- **OCSP**: `https://vault.spaceships.work:8200/v1/pki_int/ocsp`

### Administrative Endpoints (Requires Vault Token)

- **Issue Certificate**: `POST /v1/pki_int/issue/{role_name}`
- **Sign CSR**: `POST /v1/pki_int/sign/{role_name}`
- **List Certificates**: `LIST /v1/pki_int/certs`
- **Revoke Certificate**: `POST /v1/pki_int/revoke`
- **Tidy Operations**: `POST /v1/pki_int/tidy`

## Usage Examples

### Issue Infrastructure Certificate

```bash
# Set environment variables
export VAULT_ADDR='https://vault.spaceships.work:8200'
export VAULT_TOKEN='your-token-here'

# Issue certificate for Consul server
vault write pki_int/issue/infrastructure \
    common_name="consul-server-1.consul" \
    alt_names="consul-server-1.service.consul" \
    ttl="168h"

# Issue certificate for Nomad server
vault write pki_int/issue/infrastructure \
    common_name="nomad-server-1.nomad" \
    alt_names="nomad-server-1.service.consul" \
    ttl="168h"

# Issue certificate for Vault server
vault write pki_int/issue/infrastructure \
    common_name="vault-prod-1.vault" \
    alt_names="vault-prod-1.spaceships.work" \
    ttl="168h"
```

### Issue Application Certificate

```bash
# Issue certificate for web application
vault write pki_int/issue/application \
    common_name="api.spaceships.work" \
    ttl="24h"

# Issue certificate for internal service
vault write pki_int/issue/application \
    common_name="dashboard.app.local" \
    ttl="24h"

# Issue certificate for Consul service
vault write pki_int/issue/application \
    common_name="web.service.consul" \
    ttl="24h"
```

### Issue Database Certificate

```bash
# Issue certificate for PostgreSQL
vault write pki_int/issue/database \
    common_name="postgres.spaceships.work" \
    ttl="168h"

# Issue certificate for MySQL
vault write pki_int/issue/database \
    common_name="mysql.spaceships.work" \
    ttl="168h"

# Issue certificate for database cluster
vault write pki_int/issue/database \
    common_name="postgres-primary.db.local" \
    alt_names="postgres-replica-1.db.local,postgres-replica-2.db.local" \
    ttl="168h"
```

### Download CA Certificate Chain

```bash
# Download intermediate CA certificate
curl -sk https://vault.spaceships.work:8200/v1/pki_int/ca/pem > intermediate-ca.pem

# Download full certificate chain (intermediate + root)
curl -sk https://vault.spaceships.work:8200/v1/pki_int/ca-chain > ca-chain.pem

# Verify certificate chain
openssl verify -CAfile ca-chain.pem intermediate-ca.pem
```

### Check CRL

```bash
# Download CRL
curl -sk https://vault.spaceships.work:8200/v1/pki_int/crl > intermediate-crl.crl

# View CRL details
openssl crl -in intermediate-crl.crl -inform DER -text -noout

# Check if a certificate is revoked
openssl verify -crl_check -CAfile ca-chain.pem -CRLfile intermediate-crl.crl cert.pem
```

## Automation

### Ansible Playbook

The intermediate CA setup is automated via Ansible:

```bash
# Run the setup playbook
uv run ansible-playbook playbooks/infrastructure/vault/setup-pki-intermediate-ca.yml \
  -i inventory/environments/vault-cluster/production.yaml
```

The playbook is idempotent and can be safely re-run to verify configuration.

### Ansible Certificate Generation

Using the `community.hashi_vault.vault_pki_generate_certificate` module:

```yaml
- name: Generate certificate for service
  community.hashi_vault.vault_pki_generate_certificate:
    url: "{{ vault_addr }}"
    auth_method: token
    token: "{{ vault_token }}"
    engine_mount_point: pki_int
    role_name: infrastructure
    common_name: "service.consul"
    ttl: "168h"
    validate_certs: false
  register: cert_data

- name: Save certificate
  ansible.builtin.copy:
    content: "{{ cert_data.data.data.certificate }}"
    dest: "/etc/ssl/certs/service.pem"
    mode: '0644'

- name: Save private key
  ansible.builtin.copy:
    content: "{{ cert_data.data.data.private_key }}"
    dest: "/etc/ssl/private/service-key.pem"
    mode: '0600'
```

### Required Environment Variables

- `VAULT_ADDR`: Vault server address (https://192.168.10.31:8200)
- `VAULT_TOKEN`: Vault token with PKI permissions
- `INFISICAL_UNIVERSAL_AUTH_CLIENT_ID`: For backup operations
- `INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET`: For backup operations

## Security Considerations

### Certificate Lifetimes

| Certificate Type | Maximum TTL | Default TTL | Rotation Frequency |
|-----------------|-------------|-------------|-------------------|
| Root CA | 10 years | N/A | Every 8-9 years |
| Intermediate CA | 5 years | N/A | Every 4 years |
| Infrastructure | 30 days | 7 days | Weekly |
| Application | 7 days | 1 day | Daily |
| Database | 30 days | 7 days | Weekly |

### Access Control

```hcl
# Example Vault policy for certificate issuance
path "pki_int/issue/infrastructure" {
  capabilities = ["create", "update"]
}

path "pki_int/issue/application" {
  capabilities = ["create", "update"]
}

path "pki_int/sign/*" {
  capabilities = ["create", "update"]
}
```

### Best Practices

1. **Principle of Least Privilege**: Each service should only be able to request certificates for its own domains
2. **Short Lifetimes**: Use the shortest practical certificate lifetime
3. **Automated Rotation**: Implement automated certificate renewal before expiration
4. **Monitoring**: Track certificate expiration and renewal failures
5. **Audit Logging**: Enable Vault audit logs for all PKI operations

### Certificate Validation

All certificates include:
- Proper Subject Alternative Names (SANs)
- Key usage extensions appropriate to the role
- Extended key usage for TLS server/client authentication
- CRL distribution points for revocation checking
- OCSP responder URL for real-time revocation status

## Monitoring and Maintenance

### Key Metrics to Monitor

1. **Certificate Expiration**
   ```bash
   # Check certificate expiration
   vault list -format=json pki_int/certs | \
     jq -r '.[]' | \
     xargs -I {} vault read -format=json pki_int/cert/{} | \
     jq -r '.data.certificate' | \
     openssl x509 -noout -enddate
   ```

2. **CRL Size and Growth**
   ```bash
   # Check CRL size
   curl -sk https://vault.spaceships.work:8200/v1/pki_int/crl | wc -c
   ```

3. **Certificate Issuance Rate**
   ```bash
   # Monitor via Vault metrics
   curl -H "X-Vault-Token: $VAULT_TOKEN" \
     https://vault.spaceships.work:8200/v1/sys/metrics
   ```

### Tidy Operations

Configure automatic tidying to clean up expired certificates:

```bash
# Configure auto-tidy
vault write pki_int/config/auto-tidy \
    enabled=true \
    interval_duration=12h \
    safety_buffer=72h \
    tidy_cert_store=true \
    tidy_revoked_certs=true \
    tidy_revoked_cert_issuer_associations=true
```

### Manual Tidy

```bash
# Run manual tidy operation
vault write pki_int/tidy \
    tidy_cert_store=true \
    tidy_revoked_certs=true \
    safety_buffer=72h
```

## Troubleshooting

### Common Issues

1. **Certificate Request Denied**
   ```bash
   # Check role configuration
   vault read pki_int/roles/infrastructure

   # Verify domain is allowed
   vault write pki_int/issue/infrastructure \
     common_name="test.example.com" \
     -format=json 2>&1 | jq -r '.errors[]'
   ```

2. **Certificate Chain Issues**
   ```bash
   # Verify chain
   curl -sk https://vault.spaceships.work:8200/v1/pki_int/ca-chain | \
     openssl crl2pkcs7 -nocrl -certfile /dev/stdin | \
     openssl pkcs7 -print_certs -text -noout
   ```

3. **CRL Not Accessible**
   ```bash
   # Test CRL endpoint
   curl -vsk https://vault.spaceships.work:8200/v1/pki_int/crl

   # Check CRL configuration
   vault read pki_int/config/crl
   ```

### Debug Commands

```bash
# Enable debug logging
vault audit enable file file_path=/tmp/vault-audit.log

# Check intermediate CA status
vault read pki_int/ca/pem

# List all issued certificates
vault list pki_int/certs

# Read specific certificate details
vault read pki_int/cert/<serial>

# Check role permissions
vault read pki_int/roles/infrastructure
```

## Migration from Self-Signed Certificates

### Migration Strategy

1. **Phase 1**: Set up PKI infrastructure (Complete)
2. **Phase 2**: Issue new certificates from intermediate CA
3. **Phase 3**: Deploy new certificates alongside self-signed
4. **Phase 4**: Update services to use new certificates
5. **Phase 5**: Remove self-signed certificates

### Example Migration Script

```bash
#!/bin/bash
# migrate-to-pki.sh

SERVICE_NAME="consul-server-1"
ROLE="infrastructure"

# Generate new certificate
vault write -format=json pki_int/issue/${ROLE} \
    common_name="${SERVICE_NAME}.consul" \
    ttl="168h" > /tmp/${SERVICE_NAME}-cert.json

# Extract certificate and key
jq -r '.data.certificate' /tmp/${SERVICE_NAME}-cert.json > /etc/consul.d/pki-cert.pem
jq -r '.data.private_key' /tmp/${SERVICE_NAME}-cert.json > /etc/consul.d/pki-key.pem
jq -r '.data.ca_chain[]' /tmp/${SERVICE_NAME}-cert.json > /etc/consul.d/pki-ca.pem

# Update service configuration
consul reload
```

## Disaster Recovery

### Backup Strategy

1. **Intermediate CA Certificate**: Backed up to Infisical at `/apollo-13/pki/INTERMEDIATE_CA_CERTIFICATE`
2. **Vault Snapshots**: Include PKI configuration and issued certificates
3. **Role Configurations**: Defined in Ansible playbooks (version controlled)

### Recovery Procedure

1. Restore Vault from snapshot
2. Verify PKI mounts are accessible
3. If needed, re-run intermediate CA playbook
4. Verify certificate issuance capability
5. Re-issue any expired certificates

## Next Steps

1. **Issue #97**: Replace self-signed certificates with PKI-issued certificates
2. **Issue #98**: Implement mTLS for service-to-service communication
3. **Issue #99**: Set up automated certificate rotation
4. **Issue #100**: Implement monitoring and alerting for PKI

## References

- [Vault PKI Secrets Engine Documentation](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [Build Your Own Certificate Authority](https://developer.hashicorp.com/vault/tutorials/secrets-management/pki-engine)
- [PKI Best Practices](https://developer.hashicorp.com/vault/docs/secrets/pki/considerations)
- [Ansible community.hashi_vault Collection](https://docs.ansible.com/ansible/latest/collections/community/hashi_vault/index.html)
