# Core Infrastructure Services

This directory contains Nomad job specifications for core infrastructure services that other services depend on.

## Currently Deployed Services

### Traefik (PRODUCTION)

**File**: `traefik.nomad.hcl`

**Status**: ✅ Deployed and Running

**Version**: v3.0

**Last Updated**: 2025-08-04

**Purpose**: Load balancer and reverse proxy for all HTTP/HTTPS traffic in the cluster.

**Key Features**:

- Owns ports 80 and 443 (the ONLY service that should use these ports)
- Automatic service discovery via Consul Catalog
- Automatic HTTPS with self-signed certificates
- Dashboard available at [https://traefik.lab.local](https://traefik.lab.local) (port 8080 internally)
- Prometheus metrics endpoint at /metrics on admin port
- Health check endpoint at /ping on admin port

**Current Configuration**:

- Static ports: 80 (HTTP), 443 (HTTPS)
- Dynamic admin port (maps to container port 8080)
- Consul integration with service identity enabled
- All services require identity blocks with `aud = ["consul.io"]`
- Persistent volume for certificate storage

**Deployment**:

```bash
# Deploy Traefik
nomad job run nomad-jobs/core-infrastructure/traefik.nomad.hcl

# Or via Ansible
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-traefik.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

**Service Discovery**:
Services register with Traefik by adding tags to their Consul service registration:
```hcl
service {
  name = "myapp"
  port = "web"

  # REQUIRED: Identity block for Consul integration
  identity {
    aud = ["consul.io"]
    ttl = "1h"
  }

  tags = [
    "traefik.enable=true",
    "traefik.http.routers.myapp.rule=Host(`myapp.lab.local`)",
    "traefik.http.routers.myapp.entrypoints=websecure",
    "traefik.http.routers.myapp.tls=true",
    "traefik.http.services.myapp.loadbalancer.server.port=${NOMAD_PORT_web}",
  ]
}
```

**Monitoring**:
- Prometheus metrics available at: `http://<node>:<admin_port>/metrics`
- Health check: `http://<node>:<admin_port>/ping`
- Dashboard: `https://traefik.lab.local` (when configured)

**Important Notes**:
- Requires CONSUL_HTTP_ADDR environment variable set to reach Consul
- Uses node's Consul agent via `${attr.unique.consul.name}.node.consul:8500`
- All service blocks MUST include identity blocks when service_identity is enabled

## Archived Files

The `.archive/` directory contains previous iterations and test versions:
- `traefik-minimal.nomad.hcl` - Basic test configuration
- `traefik-no-identity.nomad.hcl` - Version without service identity (pre-migration)
- `traefik-simple.nomad.hcl` - Simplified test version
- `traefik-with-identity.nomad.hcl` - Identity migration test
- `traefik-with-services.nomad.hcl` - Service registration test

## Future Services

### Consul Connect Gateway (Planned)
- Service mesh ingress/egress gateways
- mTLS between services
- Advanced traffic management

### Vault (Planned)
- Secret management
- Dynamic credentials
- PKI infrastructure for proper TLS certificates

## Troubleshooting

### Common Issues

1. **Services not appearing in Traefik**:
   - Ensure service has identity block with `aud = ["consul.io"]`
   - Check Traefik tags are properly formatted
   - Verify service is registered in Consul: `consul catalog services`

2. **Connection refused to admin endpoints**:
   - Admin port is dynamic, get current port: `nomad alloc status <alloc_id>`
   - Endpoints only accessible from within infrastructure network
   - Check nftables/firewall rules on the host

3. **Consul connection errors**:
   - Verify CONSUL_HTTP_ADDR is set in Traefik environment
   - Check Consul agent is running on the node
   - Ensure Consul DNS is working: `dig consul.service.consul`
