# Nomad Jobs

This directory contains all Nomad job specifications for the homelab infrastructure. Jobs are organized by their purpose and criticality.

## Directory Structure

```text
nomad-jobs/
├── core-infrastructure/    # Essential platform services (load balancers, service mesh)
│   ├── traefik.nomad.hcl      # Production Traefik load balancer
│   ├── vault-reference.nomad.hcl  # Vault integration reference
│   └── README.md               # Service documentation
├── platform-services/      # Infrastructure services (DNS, IPAM, monitoring)
│   ├── postgresql/
│   │   ├── postgresql.nomad.hcl        # PostgreSQL database server
│   │   ├── postgresql.variables.hcl    # PostgreSQL configuration variables
│   │   ├── postgresql.variables.example.hcl  # Variable template
│   │   ├── POSTGRESQL-DEPLOYMENT.md    # PostgreSQL deployment guide
│   │   └── README.md                   # PostgreSQL service documentation
│   ├── powerdns/
│   │   ├── powerdns-auth.nomad.hcl     # Production PowerDNS authoritative server
│   │   ├── powerdns-infisical.nomad.hcl # PowerDNS with variable configuration
│   │   └── README.md                   # PowerDNS service documentation
│   ├── vault-pki/
│   │   ├── vault-pki-exporter.nomad.hcl     # Vault PKI certificate exporter
│   │   ├── vault-pki-monitor.nomad.hcl      # Vault PKI health monitor
│   │   └── README.md                        # Vault PKI service documentation
│   └── README.md               # Main platform-services documentation
└── applications/          # User-facing applications
    ├── example-app.nomad.hcl   # Example application template
    └── README.md               # Application documentation
```

## Organizational Policy

### File Management Standards

**ENFORCE THESE RULES:**

1. **Production Files Only**: Each service directory should contain ONLY:

   - Production `.nomad.hcl` files (clearly named after the service)
   - Configuration files (variables, examples)
   - One `README.md` documenting the current deployment
   - Documentation files specific to the service

2. **Development Workflow**:

   - Use descriptive filenames for different configurations: `{service}-{variant}.nomad.hcl`
   - Examples: `powerdns-auth.nomad.hcl`, `powerdns-infisical.nomad.hcl`
   - Keep development versions in the main directory with clear naming

3. **Version Management**:

   - Use git for version control and rollback capabilities
   - Tag important versions in git history
   - Document version changes in commit messages

4. **Documentation Requirements**:

Each service README.md MUST include:

- **Current Status**: Production/Testing/Planned
- **File**: Name of production job file(s)
- **Version**: Container version or tag
- **Last Updated**: Date of last production change
- **Configuration**: Key settings and requirements
- **Access**: How to reach the service
- **Troubleshooting**: Common issues and solutions

## Currently Deployed Services

### Core Infrastructure

- **Traefik** (v3.0) - ✅ Production

  - Load balancer and reverse proxy
  - Owns ports 80/443
  - Prometheus metrics enabled
  - Consul service discovery active

- **Vault Reference** - 📋 Reference Implementation
  - Example Vault integration patterns
  - Service identity configuration
  - Secrets management templates

### Platform Services

- **PowerDNS** (pdns-auth-46/48) - ✅ Production

  - Authoritative DNS server with multiple configurations
  - `powerdns-auth.nomad.hcl` - Standard MySQL backend deployment
  - `powerdns-infisical.nomad.hcl` - Variable-based configuration
  - API enabled with dynamic port allocation
  - Port 53 (static) + dynamic API port
  - Consul service registration active

- **PostgreSQL** - ✅ Production

  - Multi-service database server
  - Configurable via variables (see `POSTGRESQL-DEPLOYMENT.md`)
  - Supports PowerDNS, Netdata, Vault database users
  - Persistent volume storage
  - Service discovery with Consul

- **Vault PKI Services** - 🔧 Infrastructure Tools
  - `vault-pki-exporter.nomad.hcl` - Certificate export utility
  - `vault-pki-monitor.nomad.hcl` - PKI health monitoring
  - Integration with Vault certificate management

## Deployment

All jobs are deployed using Ansible playbooks with the `community.general.nomad_job` module.

### Quick Deploy

```bash
# Deploy Traefik
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/core-infrastructure/traefik.nomad.hcl

# Deploy PowerDNS (choose configuration)
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/platform-services/powerdns/powerdns-auth.nomad.hcl \
  -e force=true

# Deploy PostgreSQL with variables
nomad job run -var-file="nomad-jobs/platform-services/postgresql/postgresql.variables.hcl" \
  nomad-jobs/platform-services/postgresql/postgresql.nomad.hcl

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

- **Example App**: Template for new application deployments
- **windmill**: Workflow automation (future)
- **gitea**: Git hosting (future)
- **wiki.js**: Documentation platform (future)

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
- [x] PowerDNS - Deployed with API enabled and MySQL/PostgreSQL backends
- [x] PostgreSQL - Deployed with variable-based configuration
- [x] Vault PKI Services - Deployed for certificate management
- [ ] NetBox - Phase 3 of DNS/IPAM implementation
- [ ] Monitoring Stack - Prometheus/Grafana (planned)
- [ ] Logging Stack - Loki/Promtail (planned)
- [ ] Application Services - Example app template available

## Related Documentation

### Nomad Implementation

- [Nomad Storage Configuration Guide](../docs/implementation/nomad-storage-configuration.md)
- [Nomad Storage Strategy](../docs/implementation/nomad-storage-strategy.md)
- [Storage Implementation Patterns](../docs/implementation/nomad-storage-patterns.md)
- [Nomad Port Allocation Best Practices](../docs/implementation/nomad-port-allocation.md)

### Service-Specific Documentation

- [PostgreSQL Deployment Guide](platform-services/POSTGRESQL-DEPLOYMENT.md)
- [PowerDNS Configuration](../docs/implementation/dns-ipam/powerdns-setup.md)
- [Vault Integration Patterns](../docs/implementation/vault/)

### Operations & Architecture

- [Firewall and Port Strategy](../docs/operations/firewall-port-strategy.md)
- [Network Architecture Diagram](../docs/diagrams/network-port-architecture.md)

### Troubleshooting

- [Service Identity Issues](../docs/troubleshooting/service-identity-issues.md)
