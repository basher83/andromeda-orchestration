# Nomad Jobs

This directory contains all Nomad job specifications for the homelab infrastructure. Jobs are organized by their purpose and criticality.

## Directory Structure

```text
nomad-jobs/
├── core-infrastructure/    # Essential platform services (load balancers, service mesh)
│   ├── traefik.nomad.hcl  # Production job file
│   ├── README.md           # Service documentation
│   ├── .testing/          # Work-in-progress iterations
│   └── .archive/          # Previous versions for reference
├── platform-services/      # Infrastructure services (DNS, IPAM, monitoring)
│   ├── powerdns.nomad.hcl # Production job file
│   ├── README.md          # Service documentation
│   ├── .testing/          # Work-in-progress iterations
│   └── .archive/          # Previous versions for reference
└── applications/          # User-facing applications
    └── (same structure)
```

## Organizational Policy

### File Management Standards

**ENFORCE THESE RULES:**

1. **Production Files Only**: Each service directory should contain ONLY:
   - One production `.nomad.hcl` file (named after the service)
   - One `README.md` documenting the current deployment
   - Hidden directories for non-production files

2. **Development Workflow**:
   - `.testing/` - Active development and work-in-progress files
   - Test files named: `{service}-{variant}.nomad.hcl`
   - Example: `traefik-with-metrics.nomad.hcl`, `powerdns-minimal.nomad.hcl`

3. **Archive Policy**:
   - `.archive/` - Previous iterations and superseded versions
   - Move files here after production deployment is confirmed
   - Keep for reference and rollback purposes

4. **Documentation Requirements**:

Each service README.md MUST include:

- **Current Status**: Production/Testing/Planned
- **File**: Name of production job file
- **Version**: Container version or tag
- **Last Updated**: Date of last production change
- **Configuration**: Key settings and requirements
- **Access**: How to reach the service
- **Troubleshooting**: Common issues and solutions
- **Archived Files**: Brief description of archived versions

5. **Cleanup Process**:

After successful production deployment:

```bash
# Move test files to archive
mv .testing/*.nomad.hcl .archive/

# Rename final version to service name
mv {service}-final.nomad.hcl {service}.nomad.hcl

# Update README.md with production details
```

## Currently Deployed Services

### Core Infrastructure

- **Traefik** (v3.0) - ✅ Production
  - Load balancer and reverse proxy
  - Owns ports 80/443
  - Prometheus metrics enabled
  - Consul service discovery active

### Platform Services

- **PowerDNS** (pdns-auth-48) - ✅ Production
  - Authoritative DNS server
  - API enabled with MySQL backend
  - Port 53 (static) + dynamic API port
  - Consul service registration active

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

# Direct Nomad deployment
nomad job run nomad-jobs/core-infrastructure/traefik.nomad.hcl
```

### Service-Specific Playbooks

Some services have dedicated deployment playbooks with additional validation:

```bash
# Deploy Traefik (includes port conflict checks)
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-traefik.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

## Job Requirements

### Consul Service Identity

**CRITICAL**: When `service_identity { enabled = true }` is configured in Nomad:

All service blocks MUST include identity configuration:
```hcl
service {
  name = "myservice"
  port = "web"

  identity {
    aud = ["consul.io"]  # REQUIRED
    ttl = "1h"          # Recommended
  }

  # ... rest of service configuration
}
```

### Port Allocation Strategy

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
   - TODO: Migrate to Vault/Infisical

2. **Volume Management**:
   - Choose appropriate storage type (see [Storage Configuration Guide](../docs/implementation/nomad-storage-configuration.md))
   - Volume names: `{service}-{type}` (e.g., `powerdns-mysql`)
   - Provision volumes before deployment:
     ```bash
     ansible-playbook playbooks/infrastructure/nomad/volumes/provision-host-volumes.yml
     ```

3. **Service Discovery**:
   - Always register services with Consul
   - Include health checks
   - Add routing tags for Traefik
   - Include identity blocks (see requirements above)

4. **Resource Allocation**:
   - Set appropriate CPU and memory limits
   - Consider cluster capacity
   - Monitor actual usage and adjust

5. **Testing Workflow**:
   - Develop in `.testing/` directory
   - Test with descriptive variant names
   - Document findings in commit messages
   - Move to production only after validation
   - Archive superseded versions

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
   - Verify from inside infrastructure: Services may not be accessible externally

3. **Job Fails to Start**:
   ```bash
   # Check job status
   nomad job status <job-name>

   # View allocation logs
   nomad alloc logs <alloc-id>

   # Check specific task logs
   nomad alloc logs -task <task-name> <alloc-id>
   ```

4. **Service Identity Issues**:
   - Ensure ALL service blocks have identity configuration
   - Check for error: "Service identity must provide at least one target aud value"
   - Verify Consul auth method is configured

## Migration Status

- [x] Traefik - Deployed with Prometheus metrics and Consul integration
- [x] PowerDNS - Deployed with API enabled and MySQL backend
- [ ] NetBox - Phase 3 of DNS/IPAM implementation
- [ ] Monitoring Stack - Prometheus/Grafana (planned)
- [ ] Logging Stack - Loki/Promtail (planned)

## Related Documentation

### Nomad Implementation
- [Nomad Storage Configuration Guide](../docs/implementation/nomad-storage-configuration.md)
- [Nomad Storage Strategy](../docs/implementation/nomad-storage-strategy.md)
- [Storage Implementation Patterns](../docs/implementation/nomad-storage-patterns.md)
- [Nomad Port Allocation Best Practices](../docs/implementation/nomad-port-allocation.md)

### Operations & Architecture
- [Firewall and Port Strategy](../docs/operations/firewall-port-strategy.md)
- [Network Architecture Diagram](../docs/diagrams/network-port-architecture.md)

### Troubleshooting
- [Service Identity Issues](../docs/troubleshooting/service-identity-issues.md)
