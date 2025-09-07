# PowerDNS Service

This directory contains Nomad job specifications for the PowerDNS authoritative DNS server.

## Currently Deployed Services

### PowerDNS (PRODUCTION)

**Files**:

- `powerdns-auth.nomad.hcl` - Standard deployment with MySQL backend
- `powerdns-infisical.nomad.hcl` - Variable-based configuration deployment

**Status**: ✅ Deployed and Running

**Version**: PowerDNS Auth 46/48

**Last Updated**: 2025-09-06

**Purpose**: Authoritative DNS server for the homelab infrastructure with API access and MySQL backend.

## Configuration Options

### Standard Deployment (powerdns-auth.nomad.hcl)

- Uses MySQL backend for zone storage
- Includes API with webserver on dynamic port
- Standard configuration for production use

### Variable-Based Deployment (powerdns-infisical.nomad.hcl)

- Uses Nomad variables for configuration
- Supports dynamic API key and database credentials
- Enhanced security through variable management

## Key Features

- **Static DNS Port**: 53 (required for DNS compatibility)
- **API Access**: REST API for zone management
- **MySQL Backend**: Persistent zone storage
- **Consul Integration**: Service discovery and identity blocks
- **Traefik Routing**: Web interface accessible via load balancer

## Services Registered

- `powerdns-dns` - DNS service on port 53
- `powerdns-api` - REST API on dynamic port
- `powerdns-mysql` - MySQL database backend

## Access

- **DNS Queries**: `<node-ip>:53` or `dig @<node-ip> domain.com`
- **API**: `http://<node-ip>:<dynamic-port>/api/v1/servers`
- **Traefik Route**: `https://powerdns.lab.local` (when configured)
- **Default SOA**: `ns1.lab.spaceships.work hostmaster.lab.spaceships.work 1 10800 3600 604800 3600`

## Deployment

### Standard Deployment

```bash
nomad job run powerdns-auth.nomad.hcl
```

### Variable-Based Deployment

```bash
# Set variables first
nomad var put nomad/jobs/powerdns \
  pdns_db_password="your-db-password" \
  pdns_api_key="your-api-key"

# Deploy
nomad job run powerdns-infisical.nomad.hcl
```

### Ansible Deployment

```bash
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/platform-services/powerdns/powerdns-auth.nomad.hcl
```

## Configuration

### API Configuration

The PowerDNS API requires explicit command-line arguments:

```bash
--webserver=yes
--webserver-address=0.0.0.0
--webserver-port=8081
--webserver-allow-from=0.0.0.0/0
--api=yes
--api-key=your-api-key
```

### MySQL Schema

The job automatically creates required PowerDNS tables:

- `domains` - DNS zones
- `records` - DNS records
- Includes necessary indexes for performance

## Important Notes

- **Port 53**: Must be static and available (DNS requirement)
- **API Webserver**: Must be enabled via command-line args, not environment variables
- **Identity Blocks**: All service blocks must include `aud = ["consul.io"]`
- **Database Credentials**: Currently hardcoded (TODO: migrate to Vault)

## Traefik Integration

PowerDNS API service includes Traefik tags for routing:

```hcl
tags = [
  "traefik.enable=true",
  "traefik.http.routers.powerdns.rule=Host(`powerdns.lab.local`)",
  "traefik.http.routers.powerdns.entrypoints=websecure",
  "traefik.http.routers.powerdns.tls=true",
  "traefik.http.services.powerdns.loadbalancer.server.port=${NOMAD_PORT_api}",
]
```

## Troubleshooting

### Common Issues

1. **DNS not responding**:

   - Check port 53 is properly mapped
   - Verify MySQL is running and connected
   - Check PowerDNS logs: `nomad alloc logs <alloc_id> powerdns`

2. **API not accessible**:

   - Verify webserver is enabled in args
   - Get dynamic port: `nomad alloc status <alloc_id>`
   - Test: `curl -H "X-API-Key: your-key" http://<node>:<port>/api/v1/servers`

3. **Service registration issues**:
   - Ensure identity blocks with `aud = ["consul.io"]`
   - Check Consul: `consul catalog services`
   - Verify Nomad client Consul integration

## Future Integration

- **NetBox Integration**: Automatic DNS updates from IPAM
- **Vault Secrets**: Dynamic database credentials and API keys
- **Zone Management**: Automated zone creation and updates
