# Vault PKI Services

This directory contains Nomad job specifications for Vault PKI (Public Key Infrastructure) management services.

## Currently Deployed Services

### Vault PKI Exporter (PRODUCTION)

**File**: `vault-pki-exporter.nomad.hcl`

**Status**: ✅ Deployed and Running

**Purpose**: Certificate export utility for Vault PKI infrastructure. Extracts certificates from Vault and makes them available to other services.

### Vault PKI Monitor (PRODUCTION)

**File**: `vault-pki-monitor.nomad.hcl`

**Status**: ✅ Deployed and Running

**Purpose**: Health monitoring and validation service for Vault PKI operations. Monitors certificate validity, renewal status, and PKI health.

## Key Features

### Certificate Export (vault-pki-exporter)

- **Automated Certificate Retrieval**: Fetches certificates from Vault PKI
- **Multiple Format Support**: Exports in PEM, DER, and other formats
- **Scheduled Updates**: Regularly refreshes certificates before expiration
- **Service Integration**: Makes certificates available to infrastructure services

### Health Monitoring (vault-pki-monitor)

- **Certificate Validation**: Monitors certificate expiration dates
- **Renewal Alerts**: Tracks certificates approaching renewal windows
- **PKI Health Checks**: Validates Vault PKI backend status
- **Metrics Export**: Provides monitoring metrics for certificate lifecycle

## Services Registered

### Vault PKI Exporter

- `vault-pki-exporter` - Certificate export service
- `vault-pki-exporter-api` - API for certificate retrieval

### Vault PKI Monitor

- `vault-pki-monitor` - Health monitoring service
- `vault-pki-monitor-metrics` - Prometheus metrics endpoint

## Configuration Requirements

### Vault Integration

Both services require Vault connectivity:

- **Vault Address**: `VAULT_ADDR` environment variable
- **Authentication**: Vault token or service identity
- **PKI Mount**: Path to PKI secrets engine (default: `pki/`)

### Environment Variables

```bash
VAULT_ADDR=https://vault.service.consul:8200
VAULT_TOKEN=<vault-token>
PKI_MOUNT_PATH=pki/
CERT_EXPORT_PATH=/exported-certs/
MONITOR_INTERVAL=1h
```

## Deployment

### Individual Deployment

```bash
# Deploy certificate exporter
nomad job run vault-pki-exporter.nomad.hcl

# Deploy health monitor
nomad job run vault-pki-monitor.nomad.hcl
```

### Ansible Deployment

```bash
# Deploy exporter
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/platform-services/vault-pki/vault-pki-exporter.nomad.hcl

# Deploy monitor
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/platform-services/vault-pki/vault-pki-monitor.nomad.hcl
```

## Access

### Certificate Exporter

- **API**: `http://vault-pki-exporter.service.consul:<port>/api/v1/certificates`
- **Certificate Files**: Available via Nomad alloc filesystem
- **Health Check**: `http://vault-pki-exporter.service.consul:<port>/health`

### Health Monitor

- **Metrics**: `http://vault-pki-monitor.service.consul:<port>/metrics`
- **Status API**: `http://vault-pki-monitor.service.consul:<port>/api/v1/status`
- **Alerts**: Integrated with monitoring stack (future)

## Security Considerations

### Certificate Handling

- **Secure Storage**: Certificates stored with appropriate file permissions
- **Access Control**: Limited to authorized services only
- **Encryption**: Sensitive certificate data encrypted at rest
- **Audit Logging**: All certificate access logged for compliance

### Vault Authentication

- **Service Identity**: Uses Consul service identity for Vault authentication
- **Token Management**: Automatic token renewal and rotation
- **Least Privilege**: Minimal required permissions for certificate operations

## Monitoring and Alerts

### Certificate Exporter Metrics

- Certificate export success/failure rates
- Certificate expiration tracking
- Export operation duration
- Vault connectivity status

### Health Monitor Alerts

- Certificates expiring within 30 days
- Vault PKI backend connectivity issues
- Certificate validation failures
- Renewal operation status

## Troubleshooting

### Common Issues

1. **Vault Connection Failed**:

   - Verify `VAULT_ADDR` is accessible
   - Check Vault token validity
   - Confirm PKI mount path exists

2. **Certificate Export Errors**:

   - Check Vault PKI role permissions
   - Verify certificate validity
   - Review export path permissions

3. **Service Identity Issues**:

   - Ensure identity blocks with `aud = ["consul.io"]`
   - Verify Consul service registration
   - Check Vault auth method configuration

4. **Monitoring Data Missing**:
   - Confirm Prometheus integration
   - Check metrics endpoint accessibility
   - Verify monitoring service registration

## Future Enhancements

### Advanced Features

- **Automated Renewal**: Automatic certificate renewal before expiration
- **Multi-PKI Support**: Support for multiple Vault PKI mounts
- **Certificate Signing**: Request and sign certificates for services
- **CRL Management**: Certificate Revocation List monitoring and updates

### Integration Improvements

- **Traefik Integration**: Automatic certificate deployment to load balancer
- **Service Mesh**: mTLS certificate management for service-to-service communication
- **External Certificate Management**: Integration with external CAs (Let's Encrypt, etc.)

## Related Documentation

- [Vault PKI Documentation](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [Certificate Management Best Practices](../../standards/security-standards.md)
- [Nomad Service Identity](../../troubleshooting/service-identity-issues.md)
- [Infrastructure Certificate Strategy](../../operations/vault-access.md)
