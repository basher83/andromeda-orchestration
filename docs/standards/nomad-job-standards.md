# Nomad Job Standards

## Purpose

Define consistent patterns for Nomad job development, testing, and deployment that ensure reliable and maintainable container orchestration.

## Background

Through iterative development of services like Traefik and PowerDNS, we've established patterns that separate production from development, maintain clean histories, and ensure consistent deployments.

## Standard

### Directory Organization

```text
nomad-jobs/
├── core-infrastructure/
│   ├── traefik.nomad.hcl      # Production file ONLY
│   ├── README.md               # Service documentation
│   ├── .testing/              # Active development
│   │   └── traefik-metrics.nomad.hcl
│   └── .archive/              # Historical versions
│       ├── traefik-v1.nomad.hcl
│       └── traefik-no-identity.nomad.hcl
```

#### The .testing/.archive Pattern

**Why This Pattern?**

1. **Clean Production**: Only proven configs visible
1. **Safe Experimentation**: Test without affecting production
1. **Historical Context**: Learn from past attempts
1. **Git Friendly**: Can gitignore .testing if desired
1. **Self-Documenting**: Clear what's production vs development

### Service Identity Requirements

All Nomad jobs **MUST** include identity blocks for Consul ACL integration.

📖 **See**: [Consul Health Checks Guide](../implementation/nomad/consul-health-checks.md) for comprehensive patterns including:

- Identity block configuration
- Health check patterns (HTTP, TCP, Script)
- Timing best practices
- Complete examples for different service types

**Why Required?**

- **Security**: Workload-specific tokens
- **Audit**: Track which service accessed what
- **Isolation**: Services can't impersonate each other
- **Automation**: Automatic token management

### Port Allocation

📖 **See**: [Port Allocation Guide](../implementation/nomad/port-allocation.md) for:

- Complete port label glossary
- Dynamic vs static port decision criteria
- Port range management (20000-32000)
- Service discovery integration patterns
- Load balancer configuration

**Key Principle**: Use dynamic ports by default. Static ports only for DNS (53), HTTP (80), HTTPS (443).

### Volume Standards

📖 **See Implementation Guides**:

- [Storage Configuration](../implementation/nomad/storage-configuration.md) - Volume types and use cases
- [Storage Patterns](../implementation/nomad/storage-patterns.md) - Common implementation patterns
- [Storage Strategy](../implementation/nomad/storage-strategy.md) - Architecture decisions
- [Dynamic Volumes](../implementation/nomad/dynamic-volumes.md) - Plugin and systemd configuration

**Naming Convention**: `{service}-{purpose}` (e.g., `postgres-data`, `traefik-certs`)

### Task Configuration

📖 **See**: [HCL2 Variables Guide](../implementation/nomad/hcl2-variables.md) for passing variables from Ansible

```hcl
task "service" {
  driver = "docker"

  config {
    image = "image:tag"  # Always specify tag
    ports = ["web", "api"]
  }

  # Resource limits - ALWAYS SET
  resources {
    cpu    = 200  # MHz
    memory = 256  # MB
  }

  # Environment variables
  env {
    CONFIG_OPTION = "value"
    # NEVER hardcode secrets
    API_KEY = "${NOMAD_SECRET_API_KEY}"
  }

  # Consul template for secrets
  template {
    data = <<EOF
{{ keyOrDefault "service/config" "" }}
EOF
    destination = "local/config.yml"
  }
}
```

### Health Checks

📖 **See**: [Consul Health Checks Guide](../implementation/nomad/consul-health-checks.md#check-type-patterns) for:

- HTTP, TCP, Script, and gRPC check patterns
- Timing recommendations by service criticality
- Port specification best practices
- Complete working examples

**Quick Reference**: Critical services (10s/2s), API services (15s/3s), Non-critical (30s/5s)

## Rationale

### Why Strict File Organization?

- **Clarity**: Immediately obvious what's production
- **Safety**: Can't accidentally deploy test configs
- **History**: Learn from past iterations
- **Cleanliness**: Main directory stays minimal

### Why Dynamic Ports?

- **No Conflicts**: Nomad manages allocation
- **Flexibility**: Services can move nodes
- **Security**: Ports change on redeploy
- **Simplicity**: No port planning spreadsheet

### Why Service Identity?

- **Zero Trust**: Every service authenticated
- **Audit Trail**: Who accessed what when
- **Automatic**: No manual token management
- **Secure**: Tokens auto-rotate

## Examples

### Good Example: Production-Ready Job

```hcl
job "api-service" {
  datacenters = ["dc1"]
  type = "service"

  group "api" {
    count = 2  # HA deployment

    network {
      port "http" {}  # Dynamic port
    }

    service {
      name = "api"
      port = "http"

      identity {
        aud = ["consul.io"]
        ttl = "1h"
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.api.rule=Host(`api.lab.local`)",
      ]

      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "api" {
      driver = "docker"

      config {
        image = "api:v1.2.3"  # Specific version
        ports = ["http"]
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
```

### Bad Example: Development Patterns in Production

```hcl
job "bad-service" {
  group "app" {
    network {
      port "web" {
        static = 8080  # ❌ Unnecessary static port
      }
    }

    service {
      name = "app"
      port = "web"
      # ❌ Missing identity block
    }

    task "app" {
      config {
        image = "app:latest"  # ❌ Non-deterministic
      }

      env {
        API_KEY = "secret123"  # ❌ Hardcoded secret
      }

      # ❌ No resource limits
    }
  }
}
```

## Exceptions

- **DNS Services**: Require port 53
- **Load Balancers**: Require ports 80/443
- **Legacy Integration**: May need specific ports temporarily
- **Development**: Can relax standards in .testing/

## Migration

### From Static to Dynamic Ports

1. Remove `static = XXXX` from port definitions
1. Update service discovery tags with `${NOMAD_PORT_label}`
1. Test service discovery and routing
1. Update documentation

### Adding Service Identity

1. Add identity block to all service definitions
1. Ensure Consul auth method configured
1. Test service registration
1. Remove any manual token configuration

### Organizing Existing Jobs

```bash
# Create structure
mkdir -p {core-infrastructure,platform-services,applications}/{.testing,.archive}

# Move production jobs
mv *-final.nomad.hcl service.nomad.hcl

# Archive old versions
mv *-v*.nomad.hcl .archive/
mv *-test*.nomad.hcl .archive/

# Document in README.md
```

## References

### Implementation Guides

- [Nomad Implementation README](../implementation/nomad/README.md) - Main index for all Nomad documentation
- [Consul Health Checks](../implementation/nomad/consul-health-checks.md) - Service registration and health checks
- [Port Allocation](../implementation/nomad/port-allocation.md) - Dynamic vs static ports
- [Storage Configuration](../implementation/nomad/storage-configuration.md) - Volume types and patterns
- [Storage Strategy](../implementation/nomad/storage-strategy.md) - Architecture decisions
- [Storage Patterns](../implementation/nomad/storage-patterns.md) - Common patterns
- [Dynamic Volumes](../implementation/nomad/dynamic-volumes.md) - Plugin configuration
- [HCL2 Variables](../implementation/nomad/hcl2-variables.md) - Variable passing from Ansible

### Troubleshooting

- [Service Identity Issues](../troubleshooting/service-identity-issues.md)
- [Consul KV Templating](../troubleshooting/consul-kv-templating-issues.md)

### Related Documentation

- [Nomad Workloads Authentication](../implementation/consul/nomad-workloads-auth.md)
- [Nomad Jobs Directory](../../nomad-jobs/README.md)
