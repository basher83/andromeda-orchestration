# PostgreSQL Deployment Guide

## Overview

The PostgreSQL Nomad job has been updated to use environment variables instead of hardcoded passwords for improved security.

## Required Variables

The following variables must be set when deploying PostgreSQL:

- `POSTGRES_PASSWORD` - PostgreSQL superuser password
- `PDNS_PASSWORD` - PowerDNS database user password
- `NETDATA_PASSWORD` - Netdata monitoring user password
- `VAULT_DB_PASSWORD` - Vault database management user password

## Deployment Methods

### Method 1: Using Variable File (Recommended)

1. Copy the example variables file:

   ```bash
   cp postgresql.variables.example.hcl postgresql.variables.hcl
   ```

2. Edit `postgresql.variables.hcl` with your actual passwords:

   ```hcl
   postgres_password = "your-secure-postgres-password"
   pdns_password     = "your-secure-pdns-password"
   netdata_password  = "your-secure-netdata-password"
   vault_db_password = "your-secure-vault-password"
   ```

3. Deploy the job:

   ```bash
   nomad job run -var-file="postgresql.variables.hcl" postgresql.nomad.hcl
   ```

### Method 2: Using Nomad Variables (Secure)

1. Create Nomad variables in the namespace:

   ```bash
   nomad var put nomad/jobs/postgresql \
     POSTGRES_PASSWORD="your-secure-postgres-password" \
     PDNS_PASSWORD="your-secure-pdns-password" \
     NETDATA_PASSWORD="your-secure-netdata-password" \
     VAULT_DB_PASSWORD="your-secure-vault-password"
   ```

2. Deploy the job (it will automatically use the variables):

   ```bash
   nomad job run postgresql.nomad.hcl
   ```

### Method 3: Using Environment Variables

1. Export the variables:

   ```bash
   export NOMAD_VAR_POSTGRES_PASSWORD="your-secure-postgres-password"
   export NOMAD_VAR_PDNS_PASSWORD="your-secure-pdns-password"
   export NOMAD_VAR_NETDATA_PASSWORD="your-secure-netdata-password"
   export NOMAD_VAR_VAULT_DB_PASSWORD="your-secure-vault-password"
   ```

2. Deploy the job:

   ```bash
   nomad job run postgresql.nomad.hcl
   ```

### Method 4: Command Line (Not Recommended for Production)

```bash
nomad job run \
  -var="POSTGRES_PASSWORD=your-secure-postgres-password" \
  -var="PDNS_PASSWORD=your-secure-pdns-password" \
  -var="NETDATA_PASSWORD=your-secure-netdata-password" \
  -var="VAULT_DB_PASSWORD=your-secure-vault-password" \
  postgresql.nomad.hcl
```

## Future: Vault Integration

Once Vault is fully operational, the job will be updated to use Vault's dynamic database credentials:

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

## Security Notes

- **NEVER** commit `postgresql.variables.hcl` to git (it's in `.gitignore`)
- **ALWAYS** use strong, unique passwords for each service
- **ROTATE** passwords regularly
- **USE** Nomad Variables or Vault for production deployments

## Verification

After deployment, verify the PostgreSQL service is running:

```bash
# Check job status
nomad job status postgresql

# Check service health in Consul
consul catalog services | grep postgres

# Test connection (from a Nomad client node)
psql -h <node-ip> -p <dynamic-port> -U postgres
```

## Troubleshooting

If the job fails to start:

1. Check that all required variables are set:

   ```bash
   nomad job inspect postgresql | grep PASSWORD
   ```

2. Check the job logs:

   ```bash
   nomad alloc logs <alloc-id> postgres
   nomad alloc logs <alloc-id> init-pdns
   ```

3. Ensure the `postgres-data` host volume exists on the target node

## Related Documentation

- [Nomad Variables](https://developer.hashicorp.com/nomad/docs/concepts/variables)
- [Vault Database Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases/postgresql)
