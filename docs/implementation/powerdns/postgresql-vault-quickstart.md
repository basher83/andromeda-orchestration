# PostgreSQL + Vault Database Secrets - Quick Reference

## Deployment Commands

```bash
# 1. Deploy PostgreSQL
nomad job run nomad-jobs/platform-services/postgresql.nomad.hcl

# 2. Get PostgreSQL connection info
PGALLOC=$(nomad job status postgresql | grep running | awk '{print $1}')
PGHOST=$(nomad alloc status $PGALLOC | grep "Address" | awk '{print $3}' | cut -d: -f1)
PGPORT=$(nomad alloc status $PGALLOC | grep "Address" | awk '{print $3}' | cut -d: -f2)

# 2.1. Verify PostgreSQL is running
nomad alloc logs $PGALLOC postgres | grep "ready to accept connections"

# 3. Verify vaultuser was created automatically (optional)
PGPASSWORD="temporary-bootstrap-password" psql -h $PGHOST -p $PGPORT -U postgres -d powerdns -c \
  "SELECT rolname, rolcreaterole, rolcreatedb FROM pg_roles WHERE rolname = 'vaultuser';"

# 4. Configure Vault database connection
vault write database/config/powerdns-database \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="powerdns-role" \
    connection_url="postgresql://{{username}}:{{password}}@$PGHOST:$PGPORT/powerdns" \
    username="vaultuser" \
    password="vaultpass" \
    password_authentication="scram-sha-256"

# 5. Create PowerDNS role in Vault
vault write database/roles/powerdns-role \
    db_name="powerdns-database" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT USAGE ON SCHEMA public TO \"{{name}}\"; \
        GRANT SELECT, INSERT, UPDATE, DELETE ON domains, records, supermasters, comments, domainmetadata, cryptokeys, tsigkeys TO \"{{name}}\"; \
        GRANT SELECT, USAGE ON domains_id_seq, records_id_seq, comments_id_seq, domainmetadata_id_seq, cryptokeys_id_seq, tsigkeys_id_seq TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

## Testing Commands

```bash
# Generate dynamic credentials
vault read database/creds/powerdns-role

# Test credentials (replace with actual generated values)
PGPASSWORD="<generated-password>" psql -h $PGHOST -p $PGPORT -U "<generated-username>" -d powerdns -c "SELECT COUNT(*) FROM domains;"
```

## Verification Commands

```bash
# Check PostgreSQL status
nomad job status postgresql

# Check database tables
PGPASSWORD="temporary-bootstrap-password" psql -h $PGHOST -p $PGPORT -U postgres -d powerdns -c "\dt"

# Check Vault configuration
vault read database/config/powerdns-database
vault read database/roles/powerdns-role

# List active database leases
vault list sys/leases/lookup/database/creds/powerdns-role
```

## Troubleshooting

### After Redeployment (when port changes)

```bash
# Get new connection details
PGALLOC=$(nomad job status postgresql | grep running | awk '{print $1}')
PGHOST=$(nomad alloc status $PGALLOC | grep "Address" | awk '{print $3}' | cut -d: -f1)
PGPORT=$(nomad alloc status $PGALLOC | grep "Address" | awk '{print $3}' | cut -d: -f2)

# Recreate vaultuser if missing
PGPASSWORD="temporary-bootstrap-password" psql -h $PGHOST -p $PGPORT -U postgres -c \
  "CREATE USER vaultuser WITH CREATEDB CREATEROLE LOGIN PASSWORD 'vaultpass';"

# Re-grant permissions
PGPASSWORD="temporary-bootstrap-password" psql -h $PGHOST -p $PGPORT -U postgres -d powerdns -c \
  "GRANT SELECT, INSERT, UPDATE, DELETE ON domains, records, supermasters, comments, domainmetadata, cryptokeys, tsigkeys TO vaultuser WITH GRANT OPTION;
   GRANT SELECT, USAGE ON domains_id_seq, records_id_seq, comments_id_seq, domainmetadata_id_seq, cryptokeys_id_seq, tsigkeys_id_seq TO vaultuser WITH GRANT OPTION;"

# Update Vault config with new address
vault write database/config/powerdns-database \
    connection_url="postgresql://{{username}}:{{password}}@$PGHOST:$PGPORT/powerdns" \
    username="vaultuser" password="vaultpass" \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="powerdns-role" \
    password_authentication="scram-sha-256"
```

### Common Log Messages (Expected/Harmless)

- `chmod: /var/run/postgresql: Operation not permitted` - Harmless Docker entrypoint warning
- `listening on Unix socket "/tmp/.s.PGSQL.XXXXX"` - Correct, socket moved to /tmp
- NetData role creation - Now handled automatically by init script

## Key Points

✅ **SCRAM-SHA-256** is configured in **Vault plugin**, not PostgreSQL config
✅ **pg_hba.conf** uses **md5** authentication
✅ **PGDATA** set to subdirectory to avoid mount point issues
✅ **Unix socket** moved to `/tmp` to avoid permission issues
✅ **NetData user** created automatically by init script
✅ **vaultuser** needs **WITH GRANT OPTION** on all PowerDNS tables
✅ **Dynamic credentials** have **1h TTL** by default

## Files Modified

- `nomad-jobs/platform-services/postgresql.nomad.hcl`
- `docs/implementation/powerdns/postgresql-vault-integration.md` (comprehensive docs)
- `docs/implementation/powerdns/postgresql-vault-quickstart.md` (this file)
