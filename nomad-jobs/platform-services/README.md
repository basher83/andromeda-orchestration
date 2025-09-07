# Platform Services

This directory contains Nomad job specifications for infrastructure services that provide functionality to the platform. Services are organized into dedicated directories for better maintainability.

## Directory Structure

```
platform-services/
├── postgresql/     # PostgreSQL database server
├── powerdns/       # PowerDNS authoritative DNS server
├── vault-pki/      # Vault PKI certificate management
└── README.md       # This file
```

## Service Overview

### PostgreSQL Database

**Location**: [`postgresql/`](postgresql/)

Multi-service database supporting PowerDNS, Netdata, and Vault. Features variable-based configuration for secure password management.

- **Status**: ✅ Production
- **Key Features**: Multi-tenant database, variable configuration, persistent storage
- **Documentation**: See [`postgresql/README.md`](postgresql/) and [`postgresql/POSTGRESQL-DEPLOYMENT.md`](postgresql/POSTGRESQL-DEPLOYMENT.md)

### PowerDNS Authoritative Server

**Location**: [`powerdns/`](powerdns/)

DNS server with multiple configuration options and MySQL backend for zone storage.

- **Status**: ✅ Production
- **Key Features**: Static DNS port 53, REST API, MySQL backend, Consul integration
- **Documentation**: See [`powerdns/README.md`](powerdns/)

### Vault PKI Services

**Location**: [`vault-pki/`](vault-pki/)

Certificate management and monitoring services for Vault PKI infrastructure.

- **Status**: ✅ Production
- **Key Features**: Certificate export, health monitoring, metrics collection
- **Documentation**: See [`vault-pki/README.md`](vault-pki/)

## Quick Deployment Reference

### PostgreSQL

```bash
# With variables
nomad job run -var-file="postgresql/postgresql.variables.hcl" postgresql/postgresql.nomad.hcl

# Via Ansible
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -e job=nomad-jobs/platform-services/postgresql/postgresql.nomad.hcl
```

### PowerDNS

```bash
# Standard deployment
nomad job run powerdns/powerdns-auth.nomad.hcl

# Variable-based deployment
nomad job run powerdns/powerdns-infisical.nomad.hcl
```

### Vault PKI Services

```bash
# Certificate exporter
nomad job run vault-pki/vault-pki-exporter.nomad.hcl

# Health monitor
nomad job run vault-pki/vault-pki-monitor.nomad.hcl
```

## Common Configuration

All services follow these patterns:

- **Service Identity**: All services include identity blocks with `aud = ["consul.io"]`
- **Consul Registration**: Automatic service discovery and health checks
- **Traefik Integration**: HTTP services include routing tags for the load balancer
- **Persistent Storage**: Database services use dedicated volumes
- **Security**: Secrets managed through variables or Vault integration

## Future Services

### NetBox (Phase 3)

- IPAM and DCIM for infrastructure management
- PowerDNS integration for automatic DNS updates
- Dynamic inventory generation for Ansible

### Monitoring Stack

- Prometheus for metrics collection
- Grafana for visualization and dashboards
- AlertManager for notification management
- Integration with existing Netdata infrastructure

### Secrets Management Enhancement

- Complete migration to Vault for all credentials
- Dynamic database credential rotation
- API key lifecycle management

## Troubleshooting

### Common Issues

1. **PowerDNS API not accessible**:

   - Verify webserver is enabled: Check for `--webserver=yes` in args
   - Get dynamic port: `nomad alloc status <alloc_id>`
   - Test from host: `curl -H "X-API-Key: changeme789xyz" http://<node>:<port>/api/v1/servers`

2. **DNS queries not working**:

   - Check port 53 is properly mapped
   - Verify MySQL is running and connected
   - Check PowerDNS logs: `nomad alloc logs <alloc_id> powerdns`

3. **Service registration issues**:

   - Ensure all services have identity blocks with `aud = ["consul.io"]`
   - Verify services in Consul: `consul catalog services`
   - Check Nomad client has proper Consul integration

4. **MySQL connection problems**:
   - Verify MySQL task is running
   - Check environment variables for connection details
   - Ensure persistent volume is properly mounted
