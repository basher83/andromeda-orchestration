# Core Infrastructure Services

This directory contains Nomad job specifications for core infrastructure services that other services depend on.

## Services

### Traefik

**Purpose**: Load balancer and reverse proxy for all HTTP/HTTPS traffic in the cluster.

**Key Features**:
- Owns ports 80 and 443 (the ONLY service that should use these ports)
- Automatic service discovery via Consul Catalog
- Automatic HTTPS with self-signed certificates (can be upgraded to Let's Encrypt)
- Dashboard available at https://traefik.lab.local

**Deployment**:
```bash
# Deploy Traefik
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-traefik.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# Or direct deployment
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/core-infrastructure/traefik.nomad.hcl
```

**Configuration**:
- Static configuration in the job template
- Dynamic configuration via Consul tags on services
- Certificate storage in persistent volume

**Service Discovery**:
Services register with Traefik by adding tags to their Consul service registration:
```hcl
service {
  tags = [
    "traefik.enable=true",
    "traefik.http.routers.myapp.rule=Host(`myapp.lab.local`)",
    "traefik.http.routers.myapp.entrypoints=websecure",
    "traefik.http.routers.myapp.tls=true",
  ]
}
```

## Future Services

### Consul Connect Gateway
- Service mesh ingress/egress gateways
- mTLS between services
- Advanced traffic management

### Vault
- Secret management
- Dynamic credentials
- PKI infrastructure