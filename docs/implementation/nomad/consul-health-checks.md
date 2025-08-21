# Core Requirements

1. Always Include Identity Blocks

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

1. HTTP Health Checks are preferred

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

1. TCP Connectivity Checks

```hcl
check {
  name     = "tcp-connectivity"
  type     = "tcp"
  interval = "10s"
  timeout  = "2s"
  port     = "db"               # explicit port reference
}
```

1. Multi-Protocol Services

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

## Consistent Timing

```hcl
# Standard intervals based on service criticality
check {
  interval = "10s"    # Critical services (DNS, DB)
  timeout  = "2s"
}

check {
  interval = "15s"    # API services
  timeout  = "3s"
}

check {
  interval = "30s"    # Non-critical services
  timeout  = "5s"
}
```

## Meaningful Check Names

```hcl
# Good - descriptive names
check {
  name = "postgres-tcp"
  name = "api-health"
  name = "dns-tcp-53"
}

# Avoid generic names
check {
  name = "check"  # too generic
}
```

## Port Specification

```hcl
# Explicit port reference (recommended)
check {
  type = "http"
  path = "/health"
  port = "api"      # references network.port.api
}

# Implicit (uses service port)
check {
  type = "tcp"
  # uses the port defined in service block
}
```

## Complete example pattern

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

# Database service example
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

# DNS service with static port
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
