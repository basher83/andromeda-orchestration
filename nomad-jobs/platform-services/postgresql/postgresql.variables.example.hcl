# PostgreSQL Job Variables - Example File
#
# Copy this file to postgresql.variables.hcl and fill in your actual passwords
# DO NOT commit the actual variables file to git!
#
# Usage:
#   cp postgresql.variables.example.hcl postgresql.variables.hcl
#   # Edit postgresql.variables.hcl with your passwords
#   nomad job run -var-file="postgresql.variables.hcl" postgresql.nomad.hcl

postgres_password = "changeme-postgres-super-password"
pdns_password     = "changeme-powerdns-password"
netdata_password  = "changeme-netdata-monitor-password"
vault_db_password = "changeme-vault-db-password"
