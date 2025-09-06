# Platform Services

This directory contains Nomad job specifications for infrastructure services that provide functionality to the platform.

## Currently Deployed Services

### PowerDNS (PRODUCTION)

**File**: `powerdns.nomad.hcl`
**Status**: ✅ Deployed and Running
**Version**: pdns-auth-48:latest
**Last Updated**: 2025-08-04

**Purpose**: Authoritative DNS server for the homelab infrastructure.

**Key Features**:

- Runs on standard DNS port 53 (static allocation required)
- API accessible on dynamic port with webserver on port 8081 internally
- MySQL backend (MariaDB 10) for zone storage
- Ready for NetBox integration (future phase)
- Service discovery via Consul

**Current Configuration**:

- Static port: 53 (DNS)
- Dynamic port for API (maps to container port 8081)
- MySQL on dynamic port (maps to container port 3306)
- All services registered in Consul with identity blocks
- Persistent volume for MySQL data: `powerdns-mysql`

**Services Registered**:

- `powerdns-dns` - DNS service on port 53
- `powerdns-api` - REST API for zone management
- `powerdns-mysql` - MySQL database backend

**Access**:

- DNS queries: `<node-ip>:53` or `dig @<node-ip> domain.com`
- API: `http://<node-ip>:<dynamic-port>/api/v1/servers`
- API Key: `changeme789xyz` (TODO: Move to Vault/Infisical)
- Traefik route: [https://powerdns.lab.local](https://powerdns.lab.local)

**Deployment**:

```bash
# Deploy PowerDNS
nomad job run nomad-jobs/platform-services/powerdns.nomad.hcl

# Or via Ansible (Preferred)
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/platform-services/powerdns.nomad.hcl
```

**API Configuration**:
The PowerDNS API requires explicit command-line arguments to enable:

```hcl
args = [
  "--webserver=yes",
  "--webserver-address=0.0.0.0",
  "--webserver-port=8081",
  "--webserver-allow-from=0.0.0.0/0",
  "--api=yes",
  "--api-key=changeme789xyz"
]
```

**MySQL Schema**:
The job automatically creates the required PowerDNS tables:

- `domains` - DNS zones
- `records` - DNS records
- Includes necessary indexes for performance

**Important Notes**:

- API webserver MUST be enabled via command-line args, not just environment variables
- All service blocks MUST include identity blocks with `aud = ["consul.io"]`
- MySQL credentials are currently hardcoded (TODO: Move to secrets management)
- Default SOA: `ns1.lab.spaceships.work hostmaster.lab.spaceships.work 1 10800 3600 604800 3600`

**Traefik Integration**:
PowerDNS API service includes Traefik tags for routing:

```hcl
tags = [
  "traefik.enable=true",
  "traefik.http.routers.powerdns.rule=Host(`powerdns.lab.spaceships.work`)",
  "traefik.http.routers.powerdns.entrypoints=websecure",
  "traefik.http.routers.powerdns.tls=true",
  "traefik.http.services.powerdns.loadbalancer.server.port=${NOMAD_PORT_api}",
]
```

## Archived Files

The `.archive/` directory contains previous iterations and test versions:

- `powerdns.nomad.hcl` - Original version without service registration
- `powerdns-minimal.nomad.hcl` - Basic test configuration
- `powerdns-no-services.nomad.hcl` - Workaround version without service blocks
- `powerdns-simple-services.nomad.hcl` - Initial service registration test
- `powerdns-test-services.nomad.hcl` - Test with port 5353 to avoid conflicts
- `powerdns-with-identity.nomad.hcl` - Identity blocks with Consul KV integration attempt
- `powerdns-with-services.nomad.hcl` - Service registration without identity blocks
- `powerdns-final.nomad.hcl` - Final working version (renamed to powerdns.nomad.hcl)

## Planned Services

### NetBox (Phase 3)

- IPAM and DCIM
- Source of truth for infrastructure
- PowerDNS integration for automatic DNS updates
- Dynamic inventory for Ansible

### Monitoring Stack

- Prometheus for metrics collection (Traefik metrics ready)
- Grafana for visualization
- AlertManager for notifications
- Integration with existing Netdata infrastructure

### Logging Stack

- Loki for log aggregation
- Promtail for log shipping
- Integration with Grafana

### Secrets Management

- Vault or enhanced Infisical integration
- Dynamic database credentials for PowerDNS
- API key rotation

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
