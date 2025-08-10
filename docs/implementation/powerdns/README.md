# PowerDNS Implementation Documentation

This directory contains implementation documentation for PowerDNS deployment and integration within the infrastructure.

## Documents

### [deployment-architecture.md](deployment-architecture.md)

**Deployment Architecture Decision** - Documents the evaluation and selection of PowerDNS deployment patterns (Mode A vs Mode B), implementation guide, and migration strategies.

Key topics:

- Architecture comparison (Simple vs Full Stack)
- Why Mode A was chosen
- Implementation prerequisites and steps
- Configuration details
- Migration path to Mode B

### [postgresql-vault-integration.md](postgresql-vault-integration.md)

**PostgreSQL Backend with Vault Secrets** - Complete guide for setting up PostgreSQL as PowerDNS backend with Vault's Database Secrets Engine for dynamic credential management.

Key topics:

- PostgreSQL deployment with PowerDNS schema
- Vault Database Secrets Engine configuration
- SCRAM-SHA-256 authentication setup
- Dynamic credential lifecycle management
- Security considerations and troubleshooting

### [postgresql-vault-quickstart.md](postgresql-vault-quickstart.md)

**Quick Reference Guide** - Copy-paste ready commands for PostgreSQL-Vault integration deployment and testing.

### [UPDATES.md](UPDATES.md)

**Recent Fixes and Improvements** - Log of recent issues resolved and enhancements made to the PostgreSQL-Vault integration.

## Resources

### [resources/powerdns-postgresql-schema.sql](resources/powerdns-postgresql-schema.sql)

**PowerDNS PostgreSQL Schema** - Complete database schema for PowerDNS including all required tables, indexes, and constraints. This schema is embedded in the PostgreSQL Nomad job's initialization task.

## Quick Start

For deploying PowerDNS in production:

1. Review the [deployment architecture](deployment-architecture.md) to understand the chosen pattern
2. Follow the implementation guide for prerequisites
3. Deploy using Mode A with PostgreSQL backend
   - Deploy PostgreSQL: `nomad-jobs/platform-services/postgresql.nomad.hcl`
   - Deploy/update PowerDNS job: `nomad-jobs/platform-services/powerdns.nomad.hcl` (configure to use PostgreSQL per integration docs)

## Related Documentation

- [DNS & IPAM Implementation Plan](../dns-ipam/implementation-plan.md)
- [PowerDNS NetBox Integration](../dns-ipam/powerdns-netbox-integration.md)
- [Nomad Storage Strategy](../nomad/storage-strategy.md)

## Job Files

The relevant Nomad job specifications are located at:

- **PostgreSQL Backend**: `nomad-jobs/platform-services/postgresql.nomad.hcl`
- **PowerDNS Auth (configure for PostgreSQL)**: `nomad-jobs/platform-services/powerdns.nomad.hcl`
