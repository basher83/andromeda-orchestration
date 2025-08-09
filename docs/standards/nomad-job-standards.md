# Nomad Job Standards

## Purpose
Define consistent patterns for Nomad job development, testing, and deployment that ensure reliable and maintainable container orchestration.

## Background
Through iterative development of services like Traefik and PowerDNS, we've established patterns that separate production from development, maintain clean histories, and ensure consistent deployments.

## Standard

### Directory Organization

```
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
2. **Safe Experimentation**: Test without affecting production
3. **Historical Context**: Learn from past attempts
4. **Git Friendly**: Can gitignore .testing if desired
5. **Self-Documenting**: Clear what's production vs development

### Service Identity Requirements

```hcl
# REQUIRED when service_identity is enabled in Nomad
service {
  name = "service-name"
  port = "port-label"

  identity {
    aud = ["consul.io"]  # MANDATORY
    ttl = "1h"          # Recommended
  }

  tags = [...]
  check {...}
}
```

**Why Required?**
- **Security**: Workload-specific tokens
- **Audit**: Track which service accessed what
- **Isolation**: Services can't impersonate each other
- **Automation**: Automatic token management

### Port Allocation

Use standardized port labels across jobs to simplify routing and observability. See the Port label glossary for recommended names: [Port Allocation: Port label glossary](../implementation/nomad/port-allocation.md#port-label-glossary).

Recommended labels (keep lowercase and consistent):
- http – primary HTTP traffic (via LB)
- https – TLS entrypoint (LB only)
- grpc – gRPC endpoint (internal/LB)
- metrics – Prometheus scrape (internal)
- admin – admin/management (internal)
- health – health checks (internal)
- db – database protocol (internal)

```hcl
network {
  # Static ports - ONLY for special cases
  port "dns" {
    static = 53  # ONLY for DNS
  }

  # Dynamic ports - DEFAULT
  port "api" {}    # Nomad assigns from 20000-32000
  port "web" {}    # No conflicts possible

  # Port mapping for containers
  port "admin" {
    to = 8080    # Container port
  }              # Host port is dynamic
}
```

### Volume Standards

```hcl
# Persistent data
volume "service-data" {
  type      = "host"
  source    = "service-data"  # Matches client config
  read_only = false
}

# Naming: {service}-{purpose}
# Examples:
#   postgres-data
#   traefik-certs
#   prometheus-data
```

### Task Configuration

```hcl
task "service" {
  driver = "docker"

  config {
    image = "image:tag"  # Always specify tag
    ports = ["web", "api"]

    # For debugging - remove in production
    args = [
      "--debug",
      "--verbose"
    ]
  }

  # Resource limits - ALWAYS SET
  resources {
    cpu    = 200  # MHz
    memory = 256  # MB
  }

  # Environment variables
  env {
    # Configuration via env vars
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

```hcl
service {
  check {
    type     = "http"
    path     = "/health"
    interval = "10s"
    timeout  = "2s"

    # For authenticated endpoints
    header {
      Authorization = ["Bearer ${NOMAD_SECRET_TOKEN}"]
    }
  }
}

# TCP check for non-HTTP services
check {
  type     = "tcp"
  interval = "10s"
  timeout  = "2s"
}

# Script check for complex validation
check {
  type     = "script"
  command  = "/local/health-check.sh"
  interval = "30s"
  timeout  = "5s"
}
```

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
2. Update service discovery tags with `${NOMAD_PORT_label}`
3. Test service discovery and routing
4. Update documentation

### Adding Service Identity
1. Add identity block to all service definitions
2. Ensure Consul auth method configured
3. Test service registration
4. Remove any manual token configuration

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

- [Nomad Storage Configuration](../implementation/nomad/storage-configuration.md)
- [Port Allocation](../implementation/nomad/port-allocation.md)
- [Service Identity Issues](../troubleshooting/service-identity-issues.md)
- [Nomad Jobs README](../../nomad-jobs/README.md)
