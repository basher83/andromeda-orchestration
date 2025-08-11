# PostgreSQL and Vault Database Secrets Engine Integration

## Overview

This document describes the complete setup of PostgreSQL as a backend for PowerDNS with Vault's Database Secrets Engine for dynamic credential management. The integration provides secure, time-limited database credentials with SCRAM-SHA-256 authentication.

## Architecture

```text
PowerDNS → Vault Dynamic Credentials → PostgreSQL Backend
                ↓
        Time-limited credentials (1h TTL)
        SCRAM-SHA-256 authentication
```

## Prerequisites

- Nomad cluster with host volumes configured
- Vault cluster with database secrets engine enabled
- Consul for service discovery
- Node with `postgres-data` host volume available

## Step 1: PostgreSQL Deployment

### 1.1 Nomad Job Configuration

The PostgreSQL Nomad job (`nomad-jobs/platform-services/postgresql.nomad.hcl`) includes:

- **Host Volume**: `postgres-data` for persistent storage
- **Custom Configuration**: `postgresql.conf` with production settings
- **Access Control**: `pg_hba.conf` with md5 authentication
- **Initialization Task**: `init-pdns` creates PowerDNS database and schema
- **Service Identity**: Required for Consul integration

Key configuration elements:

```hcl
volume "postgres-data" {
  type      = "host"
  read_only = false
  source    = "postgres-data"
}

env {
  PGDATA = "/var/lib/postgresql/data/pgdata"  # Subdirectory to avoid mount issues
  POSTGRES_PASSWORD = "temporary-bootstrap-password"
}

# PostgreSQL configuration includes socket fix
template {
  data = <<-EOT
    unix_socket_directories = '/tmp'  # Avoid permission issues
  EOT
}
```

### 1.2 PowerDNS Schema

The initialization task creates the complete PowerDNS schema including:

- `domains` - DNS zone information
- `records` - DNS resource records
- `supermasters` - Supermaster configuration
- `comments` - Record comments
- `domainmetadata` - Zone metadata
- `cryptokeys` - DNSSEC keys
- `tsigkeys` - TSIG authentication keys

### 1.3 Deploy PostgreSQL

```bash
nomad job run nomad-jobs/platform-services/postgresql.nomad.hcl
```

Verify deployment:

```bash
nomad job status postgresql
nomad alloc status <allocation-id>
```

## Step 2: Vault Database Secrets Engine Configuration

### 2.1 Vault Management User (Automatic)

The vaultuser is automatically created during PostgreSQL initialization along with proper permissions. The init-pdns task creates:

- **vaultuser**: With CREATEDB and CREATEROLE privileges
- **Permissions**: Full access to PowerDNS tables with GRANT OPTION
- **Password**: `vaultpass` (configured in job template)

**No manual user creation required** - this is handled automatically during deployment.

```bash
# Get PostgreSQL connection details from Nomad allocation
PGHOST=$(nomad alloc status <allocation-id> | grep "Address" | awk '{print $3}' | cut -d: -f1)
PGPORT=$(nomad alloc status <allocation-id> | grep "Address" | awk '{print $3}' | cut -d: -f2)

# Verify vaultuser was created (optional)
PGPASSWORD="temporary-bootstrap-password" psql -h $PGHOST -p $PGPORT -U postgres -d powerdns -c \
  "SELECT rolname, rolcreaterole, rolcreatedb FROM pg_roles WHERE rolname = 'vaultuser';"
```

### 2.2 Configure Database Connection

Configure Vault to connect to PostgreSQL with SCRAM-SHA-256 authentication:

```bash
vault write database/config/powerdns-database \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="powerdns-role" \
    connection_url="postgresql://{{username}}:{{password}}@$PGHOST:$PGPORT/powerdns" \
    username="vaultuser" \
    password="vaultpass" \
    password_authentication="scram-sha-256"
```

**Important**: The `password_authentication="scram-sha-256"` setting is configured at the Vault plugin level, NOT in PostgreSQL's `postgresql.conf`.

### 2.3 Configure PowerDNS Role

Create a Vault role that defines how dynamic users are created:

```bash
vault write database/roles/powerdns-role \
    db_name="powerdns-database" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT USAGE ON SCHEMA public TO \"{{name}}\"; \
        GRANT SELECT, INSERT, UPDATE, DELETE ON domains, records, supermasters, comments, domainmetadata, cryptokeys, tsigkeys TO \"{{name}}\"; \
        GRANT SELECT, USAGE ON domains_id_seq, records_id_seq, comments_id_seq, domainmetadata_id_seq, cryptokeys_id_seq, tsigkeys_id_seq TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

## Step 3: Testing and Verification

### 3.1 Generate Dynamic Credentials

Test credential generation:

```bash
vault read database/creds/powerdns-role
```

Expected output:

```text
Key                Value
---                -----
lease_id           database/creds/powerdns-role/...
lease_duration     1h
lease_renewable    true
password           <generated-password>
username           <generated-username>
```

### 3.2 Test Database Access

Verify the dynamic credentials work:

```bash
PGPASSWORD="<generated-password>" psql -h $PGHOST -p $PGPORT -U "<generated-username>" -d powerdns -c "SELECT COUNT(*) FROM domains;"
```

Should return:

```text
 count
-------
     0
(1 row)
```

## Step 4: Integration Points

### 4.1 PowerDNS Configuration

PowerDNS will use Vault templates to get dynamic credentials:

```hcl
template {
  data = <<EOF
{{ with secret "database/creds/powerdns-role" }}
gpgsql-host={{ env "NOMAD_IP_db" }}
gpgsql-port={{ env "NOMAD_PORT_db" }}
gpgsql-dbname=powerdns
gpgsql-user={{ .Data.username }}
gpgsql-password={{ .Data.password }}
{{ end }}
EOF
}
```

### 4.2 Service Dependencies

PowerDNS Nomad job should include:

- Vault policy allowing `database/creds/powerdns-role` access
- Service dependency on PostgreSQL
- Proper error handling for credential refresh

## Security Considerations

### 4.1 Authentication Methods

- **PostgreSQL**: md5 authentication in pg_hba.conf
- **Vault Plugin**: SCRAM-SHA-256 for stronger security
- **Dynamic Users**: Time-limited with automatic rotation

### 4.2 Network Security

- PostgreSQL bound to cluster networks only
- Vault TLS encryption for credential transport
- No static passwords in PowerDNS configuration

### 4.3 Credential Lifecycle

- Default TTL: 1 hour
- Maximum TTL: 24 hours
- Automatic cleanup when credentials expire
- Renewable leases for long-running services

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure vaultuser has GRANT OPTION on all PowerDNS tables
2. **Connection Failed**: Verify PostgreSQL is listening on correct host/port
3. **Authentication Failed**: Check password_authentication setting in Vault config
4. **Schema Missing**: Ensure init-pdns task completed successfully

### Resolved Issues

#### Unix Socket Permission Error

**Issue**: `chmod: /var/run/postgresql: Operation not permitted`

**Solution**: Added `unix_socket_directories = '/tmp'` to PostgreSQL configuration

**Status**: ⚠️ Harmless warning remains from Docker entrypoint, but socket works correctly

#### NetData Role Missing

**Issue**: `FATAL: role "netdata" does not exist`

**Solution**: Added netdata user creation to init-pdns task

**Status**: ✅ Fixed - netdata user created automatically on deployment

#### Vault Connection After Redeployment

**Issue**: Vault fails to connect after PostgreSQL redeployment with new dynamic port

**Solution**: Update Vault database config with new host:port and recreate vaultuser

**Commands**:

```bash
# Get new connection details
PGALLOC=$(nomad job status postgresql | grep running | awk '{print $1}')
PGHOST=$(nomad alloc status $PGALLOC | grep "Address" | awk '{print $3}' | cut -d: -f1)
PGPORT=$(nomad alloc status $PGALLOC | grep "Address" | awk '{print $3}' | cut -d: -f2)

# Recreate vaultuser if missing
PGPASSWORD="temporary-bootstrap-password" psql -h $PGHOST -p $PGPORT -U postgres -c \
  "CREATE USER vaultuser WITH CREATEDB CREATEROLE LOGIN PASSWORD 'vaultpass';"

# Update Vault configuration
vault write database/config/powerdns-database \
    connection_url="postgresql://{{username}}:{{password}}@$PGHOST:$PGPORT/powerdns" \
    username="vaultuser" password="vaultpass" \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="powerdns-role" \
    password_authentication="scram-sha-256"
```

### Debugging Commands

```bash
# Check PostgreSQL status
nomad job status postgresql
nomad alloc logs <allocation-id> postgres

# Check Vault database config
vault read database/config/powerdns-database
vault read database/roles/powerdns-role

# Test PostgreSQL connectivity
PGPASSWORD="temporary-bootstrap-password" psql -h $PGHOST -p $PGPORT -U postgres -l

# Check PowerDNS schema
PGPASSWORD="temporary-bootstrap-password" psql -h $PGHOST -p $PGPORT -U postgres -d powerdns -c "\dt"
```

## Maintenance

### Credential Rotation

Vault automatically handles credential rotation. For manual rotation:

```bash
# Revoke specific lease
vault lease revoke database/creds/powerdns-role/<lease-id>

# Revoke all leases for role
vault lease revoke -prefix database/creds/powerdns-role/
```

### Database Maintenance

- PostgreSQL backups should include PowerDNS schema
- Monitor credential creation/deletion in Vault audit logs
- Regular cleanup of expired PostgreSQL users (handled automatically)

## Files Modified/Created

- `nomad-jobs/platform-services/postgresql.nomad.hcl` - PostgreSQL Nomad job
- `docs/implementation/powerdns/resources/powerdns-postgresql-schema.sql` - PowerDNS database schema
- Vault database secrets engine configuration
- PowerDNS schema and initialization scripts
- This documentation: `docs/implementation/powerdns/postgresql-vault-integration.md`

## Next Steps

1. Update PowerDNS Nomad job to use Vault dynamic credentials
2. Configure Vault policies for PowerDNS service access
3. Set up monitoring for credential lifecycle
4. Implement backup strategy for PostgreSQL data
5. Configure PowerDNS authoritative server with database backend

---

_Last updated: 2025-08-10_
_Author: Infrastructure Team_
