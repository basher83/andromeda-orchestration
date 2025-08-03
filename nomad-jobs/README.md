# Nomad Jobs

This directory contains all Nomad job specifications for the homelab infrastructure. Jobs are organized by their purpose and criticality.

## Directory Structure

```
nomad-jobs/
├── core-infrastructure/    # Essential platform services (load balancers, service mesh)
├── platform-services/      # Infrastructure services (DNS, IPAM, monitoring)
└── applications/          # User-facing applications
```

## Deployment

All jobs are deployed using Ansible playbooks with the `community.general.nomad_job` module.

### Quick Deploy

```bash
# Deploy a specific job
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/core-infrastructure/traefik.nomad.hcl

# Deploy with force restart
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/platform-services/powerdns.nomad.hcl \
  -e force=true
```

### Service-Specific Playbooks

Some services have dedicated deployment playbooks with additional validation:

```bash
# Deploy Traefik (includes port conflict checks)
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-traefik.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

## Job Naming Conventions

- **Job Names**: Use kebab-case, descriptive names (e.g., `traefik`, `powerdns`, `netbox`)
- **Service Names**: Match job name for primary service, use `{job}-{component}` for multi-service jobs
- **File Names**: `{service}.nomad.hcl` for single service, `{service}/` directory for complex deployments

## Port Allocation Strategy

Following our [firewall and port strategy](../docs/operations/firewall-port-strategy.md):

1. **Dynamic Ports (Default)**: Services use Nomad's dynamic range (20000-32000)
2. **Static Ports (Exceptions)**:
   - DNS (53): Required for standard resolver compatibility
   - Load Balancer (80/443): ONE service owns these for all HTTP/HTTPS traffic
3. **Access Pattern**: External traffic → Load Balancer → Service Discovery → Dynamic Port

## Service Categories

### Core Infrastructure

Services that other services depend on:
- **traefik**: Load balancer and reverse proxy (owns ports 80/443)
- **consul-connect**: Service mesh components (future)

### Platform Services

Infrastructure services that provide functionality:
- **powerdns**: Authoritative DNS server
- **netbox**: IPAM and DCIM (Phase 3)
- **monitoring**: Prometheus, Grafana, etc. (future)

### Applications

End-user facing services:
- **windmill**: Workflow automation (future)
- **gitea**: Git hosting (future)

## Best Practices

1. **Secrets Management**:
   - Never hardcode secrets in job files
   - Use Consul KV via `template` stanzas
   - Reference: `{{ keyOrDefault "service/path/to/secret" "" }}`

2. **Volume Management**:
   - Choose appropriate storage type (see [Storage Guide](STORAGE.md))
   - Volume names: `{service}-{type}` (e.g., `powerdns-mysql`)
   - Provision volumes before deployment:
     ```bash
     ansible-playbook playbooks/infrastructure/nomad/volumes/provision-host-volumes.yml
     ```

3. **Service Discovery**:
   - Always register services with Consul
   - Include health checks
   - Add routing tags for Traefik

4. **Resource Allocation**:
   - Set appropriate CPU and memory limits
   - Consider cluster capacity
   - Monitor actual usage and adjust

## Troubleshooting

### Common Issues

1. **Port Already in Use**:
   ```bash
   # Check what's using a port
   ss -tlnp | grep :80
   
   # Find Nomad allocation
   nomad job status | grep -B2 "static = 80"
   ```

2. **Service Not Accessible**:
   - Check firewall allows dynamic port range
   - Verify Consul registration: `consul catalog services`
   - Check Traefik routing: `curl -H "Host: service.lab.local" http://loadbalancer`

3. **Job Fails to Start**:
   ```bash
   # Check job status
   nomad job status <job-name>
   
   # View allocation logs
   nomad alloc logs <alloc-id>
   ```

## Migration Status

- [x] PowerDNS - Migrated from static port to dynamic + Traefik routing
- [ ] Traefik - Initial deployment pending
- [ ] NetBox - Phase 3 of DNS/IPAM implementation

## Related Documentation

- [Nomad Storage Configuration Guide](STORAGE.md)
- [Nomad Storage Strategy](../docs/implementation/nomad-storage-strategy.md)
- [Storage Implementation Patterns](../docs/implementation/nomad-storage-patterns.md)
- [Nomad Port Allocation Best Practices](../docs/implementation/nomad-port-allocation.md)
- [Firewall and Port Strategy](../docs/operations/firewall-port-strategy.md)
- [Network Architecture Diagram](../docs/diagrams/network-port-architecture.md)