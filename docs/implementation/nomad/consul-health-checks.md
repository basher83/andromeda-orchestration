# Consul Health Checks for Nomad Services

## Core Requirements

### 1. Always Include Identity Blocks

Every service registration **must** include an identity block for Consul ACL integration:

```hcl
service {
  name = "my-service"
  port = "http"

  identity {
    aud = ["consul.io"]
    ttl = "1h"
  }

  check {
    # health check configuration
  }
}
```

## Check Type Patterns

### 1. HTTP Health Checks (Preferred)

For services exposing HTTP endpoints, use HTTP checks for better observability:

```hcl
check {
  name     = "api-health"
  type     = "http"
  path     = "/health"          # or /api/v1/servers/localhost
  interval = "10s"
  timeout  = "2s"
  port     = "api"              # explicit port reference
}
```

### 2. TCP Connectivity Checks

For non-HTTP services or basic connectivity validation:

```hcl
check {
  name     = "tcp-connectivity"
  type     = "tcp"
  interval = "10s"
  timeout  = "2s"
  port     = "db"               # explicit port reference
}
```

### 3. Multi-Protocol Services

For services exposing multiple protocols (e.g., PowerDNS with DNS + API):

```hcl
service {
  name = "powerdns-auth"
  port = "dns"
  tags = ["udp", "tcp", "dns"]

  identity {
    aud = ["consul.io"]
    ttl = "1h"
  }

  check {
    name     = "dns-tcp"
    type     = "tcp"
    interval = "10s"
    timeout  = "2s"
  }
}

service {
  name = "powerdns-api"
  port = "api"
  tags = ["http", "api"]

  identity {
    aud = ["consul.io"]
    ttl = "1h"
  }

  check {
    name     = "api-health"
    type     = "http"
    path     = "/api/v1/servers/localhost"
    interval = "15s"
    timeout  = "3s"
  }
}
```

## Best Practices

### Consistent Timing

Use standard intervals based on service criticality:

| Service Type | Interval | Timeout | Examples |
|-------------|----------|---------|----------|
| Critical | 10s | 2s | DNS, Database |
| API Services | 15s | 3s | REST APIs, Admin interfaces |
| Non-critical | 30s | 5s | Metrics, Background workers |

```hcl
# Critical service example
check {
  interval = "10s"
  timeout  = "2s"
}
```

### Meaningful Check Names

Use descriptive names that indicate the service and check type:

✅ **Good Examples:**

- `postgres-tcp`
- `api-health`
- `dns-tcp-53`
- `http-ready`

❌ **Avoid:**

- `check`
- `health`
- `test`

### Port Specification

Always use explicit port references for clarity:

```hcl
# ✅ Explicit port reference (recommended)
check {
  type = "http"
  path = "/health"
  port = "api"      # references network.port.api
}

# ⚠️ Implicit (uses service port)
check {
  type = "tcp"
  # uses the port defined in service block
}
```

## Complete Examples

### Example 1: Standard Web Application

```hcl
job "example-service" {
  datacenters = ["dc1"]
  type        = "service"

  group "app" {
    count = 2

    network {
      port "http" {}    # dynamic port
      port "admin" {}   # admin/metrics port
    }

    task "app" {
      driver = "docker"

      config {
        image = "myapp:latest"
        ports = ["http", "admin"]
      }

      # Main HTTP service
      service {
        name = "myapp"
        port = "http"
        tags = [
          "http",
          "traefik.enable=true",
          "traefik.http.routers.myapp.rule=Host(`myapp.lab.local`)",
        ]

        # Required for Consul ACL integration
        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        # HTTP health check on dedicated endpoint
        check {
          name     = "http-health"
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
          port     = "http"
        }

        # Optional: Additional readiness check
        check {
          name     = "http-ready"
          type     = "http"
          path     = "/ready"
          interval = "15s"
          timeout  = "3s"
          port     = "http"
        }
      }

      # Separate service for admin/metrics
      service {
        name = "myapp-admin"
        port = "admin"
        tags = ["admin", "metrics", "prometheus"]

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        check {
          name     = "admin-tcp"
          type     = "tcp"
          interval = "30s"
          timeout  = "5s"
          port     = "admin"
        }
      }
    }
  }
}
```

### Example 2: PostgreSQL Database

```hcl
job "database" {
  group "db" {
    network {
      port "db" {}
    }

    task "postgres" {
      service {
        name = "postgres"
        port = "db"
        tags = ["tcp", "db", "postgres"]

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        # TCP check for database connectivity
        check {
          name     = "postgres-tcp"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }

        # Optional: PostgreSQL-specific check using script
        check {
          name     = "postgres-ready"
          type     = "script"
          command  = "/usr/local/bin/pg_isready"
          args     = ["-h", "localhost", "-p", "${NOMAD_PORT_db}"]
          interval = "30s"
          timeout  = "10s"
        }
      }
    }
  }
}
```

### Example 3: PowerDNS with Multiple Services

```hcl
job "dns-server" {
  group "dns" {
    network {
      port "dns" {
        static = 53
        to     = 53
      }
      port "api" {}
    }

    task "powerdns" {
      # DNS service (UDP/TCP)
      service {
        name = "powerdns-dns"
        port = "dns"
        tags = ["udp", "tcp", "dns"]

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        # TCP check for DNS port
        check {
          name     = "dns-tcp"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      # API service
      service {
        name = "powerdns-api"
        port = "api"
        tags = ["http", "api"]

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        # HTTP API health check
        check {
          name     = "api-health"
          type     = "http"
          path     = "/api/v1/servers/localhost"
          interval = "15s"
          timeout  = "3s"
        }
      }
    }
  }
}
```

## Quick Reference

| Check Type | Use Case | Key Parameters |
|------------|----------|----------------|
| `http` | REST APIs, web services | `path`, `method`, `header` |
| `tcp` | Databases, raw sockets | Port only |
| `script` | Custom validation | `command`, `args` |
| `grpc` | gRPC services | `grpc_service` |

## Common Pitfalls to Avoid

1. **Missing identity blocks** → ACL failures
2. **Wrong port references** → Health checks fail
3. **Too aggressive intervals** → Resource waste
4. **Missing explicit ports** → Ambiguous routing
5. **Generic check names** → Hard to debug
