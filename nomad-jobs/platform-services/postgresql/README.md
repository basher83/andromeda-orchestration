# PostgreSQL Service

This directory contains Nomad job specifications for the PostgreSQL database server that supports multiple services in the infrastructure.

## Currently Deployed Services

### PostgreSQL (PRODUCTION)

**File**: `postgresql.nomad.hcl`

**Status**: ✅ Deployed and Running

**Version**: PostgreSQL 15

**Last Updated**: 2025-09-06

**Purpose**: Multi-service database server supporting PowerDNS, Netdata, and Vault infrastructure services.

## Configuration

### Required Variables

The PostgreSQL job uses variables for secure configuration:

- `POSTGRES_PASSWORD` - PostgreSQL superuser password
- `PDNS_PASSWORD` - PowerDNS database user password
- `NETDATA_PASSWORD` - Netdata monitoring user password
- `VAULT_DB_PASSWORD` - Vault database management user password

### Variable Files

- `postgresql.variables.hcl` - Production variables (gitignored)
- `postgresql.variables.example.hcl` - Template for variable structure

## Deployment Methods

### Method 1: Using Variable File (Recommended)

```bash
# Copy and edit variables
cp postgresql.variables.example.hcl postgresql.variables.hcl
# Edit postgresql.variables.hcl with actual passwords

# Deploy with variables
nomad job run -var-file="postgresql.variables.hcl" postgresql.nomad.hcl
```

### Method 2: Using Nomad Variables (Secure)

```bash
# Create Nomad variables in the namespace
nomad var put nomad/jobs/postgresql \
  POSTGRES_PASSWORD="your-secure-postgres-password" \
  PDNS_PASSWORD="your-secure-pdns-password" \
  NETDATA_PASSWORD="your-secure-netdata-password" \
  VAULT_DB_PASSWORD="your-secure-vault-password"

# Deploy (automatically uses variables)
nomad job run postgresql.nomad.hcl
```

### Method 3: Using Ansible (Preferred for Infrastructure)

```bash
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/platform-services/postgresql/postgresql.nomad.hcl
```

## Services Registered

- `postgresql` - Main PostgreSQL service
- `postgresql-pdns` - PowerDNS database user
- `postgresql-netdata` - Netdata monitoring user
- `postgresql-vault` - Vault database management user

## Access

- **Internal Access**: `postgresql.service.consul:5432`
- **Superuser**: postgres (password from variables)
- **Service Users**: pdns, netdata, vault (individual passwords)

## Important Notes

- Uses persistent volume `postgres-data` for data storage
- All service blocks include identity blocks with `aud = ["consul.io"]`
- Passwords are managed via variables for security
- Supports multiple databases for different services

## Future: Vault Integration

The job is designed to integrate with Vault for dynamic database credentials:

```hcl
template {
  data = <<EOF
{{ with secret "database/creds/postgresql" }}
POSTGRES_PASSWORD="{{ .Data.password }}"
{{ end }}
EOF
  destination = "secrets/db.env"
  env = true
}
```

## Troubleshooting

### Common Issues

1. **Job fails to start**:

   - Check that all required variables are set
   - Verify persistent volume exists
   - Check Nomad allocation logs

2. **Connection failures**:

   - Verify service registration in Consul
   - Check identity block configuration
   - Confirm variable values are correct

3. **Permission issues**:
   - Ensure database users have proper permissions
   - Check password variables are correctly applied

## Related Documentation

- [PostgreSQL Deployment Guide](POSTGRESQL-DEPLOYMENT.md)
- [Nomad Variables Documentation](https://developer.hashicorp.com/nomad/docs/concepts/variables)
- [Vault Database Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases/postgresql)
