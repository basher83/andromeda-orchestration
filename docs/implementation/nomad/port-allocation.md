# Nomad Port Allocation Best Practices

This guide provides best practices for port allocation in Nomad jobs to avoid conflicts and ensure smooth deployments.

## Quick Reference

### Port Allocation Decision Tree

```
Does your service need a specific port?
├─ No (99% of services) → Use Dynamic Ports
│   └─ Access via Load Balancer
└─ Yes → Why?
    ├─ Standard Protocol (DNS, SMTP) → Use Static Port
    ├─ Direct User Access → Use Load Balancer Instead!
    └─ Legacy Requirement → Document & Plan Migration
```

## Dynamic Port Allocation (Default)

### Basic Pattern

```hcl
job "my-service" {
  group "api" {
    network {
      # Dynamic port allocation
      port "http" {
        to = 8080  # What the container expects
        # Nomad assigns from 20000-32000 range
      }
    }

    task "api" {
      driver = "docker"

      config {
        image = "my-app:latest"
        ports = ["http"]
      }

      env {
        PORT = "${NOMAD_PORT_http}"  # Pass dynamic port to app
      }
    }

    service {
      name = "my-api"
      port = "http"

      tags = [
        # Traefik routing
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
  }
}
```

#### Nomad port environment variables (quick reference)

When you define a port label (e.g., "http"), Nomad injects helpful env vars:

- NOMAD_PORT_http – The allocated host port for this label
- NOMAD_HOST_PORT_http – Same as above (alias)
- NOMAD_IP_http – The host IP bound for this label
- NOMAD_ADDR_http – Convenience "IP:PORT" string

Use these to wire the app at runtime without hardcoding. For multiple labels, repeat with each label name.

### Multiple Ports

```hcl
network {
  port "http" {
    to = 8080
  }
  port "metrics" {
    to = 9090
  }
  port "admin" {
    to = 8081
  }
}
```

Naming tips:
- Use short, lowercase labels (http, grpc, metrics, admin)
- Prefer one label per externally reachable purpose; keep admin ports internal

### Port label glossary

| Label   | Purpose                  | Exposed?         | Typical container port | Notes |
|---------|--------------------------|------------------|------------------------|-------|
| http    | Primary HTTP traffic     | Via LB (Traefik) | 3000/8080              | Tag with traefik router rules |
| https   | TLS entrypoint (LB only) | Host (LB nodes)  | 443                    | Static on LB; not for app pods |
| grpc    | gRPC endpoint            | Internal/LB      | 9090                   | Consider Connect/mesh first |
| metrics | Prometheus metrics       | Internal only    | 2112/9090              | Tag service with prometheus |
| admin   | Admin/management         | Internal only    | 8081/9000              | Do not expose publicly |
| health  | Health checks            | Internal only    | 8086                   | Keep lightweight handler |
| db      | Database protocol        | Internal only    | 5432/3306              | Prefer internal DNS over static ports |

Use these labels consistently to simplify service discovery, routing, and dashboards.


## Static Port Allocation (Exceptions)

### Valid Use Cases

#### 1. Standard Protocol Ports

```hcl
# DNS Server
network {
  port "dns" {
    static = 53
    to = 53
  }
}

# SMTP Server
network {
  port "smtp" {
    static = 25
    to = 25
  }
}
```

#### 2. Load Balancer (One Per Cluster)

```hcl
# Traefik/Nginx/Caddy
network {
  mode = "host"  # Important for load balancers

  port "http" {
    static = 80
  }
  port "https" {
    static = 443
  }
}
```

Placement notes:
- If you run more than one LB for HA, static ports 80/443 are fine across different nodes; conflicts only occur per-node.
- Constrain LBs to ingress-capable nodes (public IPs) using node metadata.

```hcl
# Example LB placement
constraint {
  attribute = "${node.class}"
  value     = "ingress"
}
```

### Invalid Use Cases (Use Dynamic Instead)

#### ❌ Web Applications

```hcl
# WRONG - Will conflict!
network {
  port "http" {
    static = 80  # NO! Use dynamic port
  }
}
```

#### ❌ API Services

```hcl
# WRONG - Unnecessary
network {
  port "api" {
    static = 8080  # NO! Use dynamic port
  }
}
```

## Service Discovery Integration

### With Traefik

```hcl
service {
  name = "my-app"
  port = "http"

  tags = [
    "traefik.enable=true",
    "traefik.http.routers.myapp.rule=Host(`myapp.lab.local`)",
    "traefik.http.routers.myapp.entrypoints=websecure",
    "traefik.http.routers.myapp.tls=true",
  ]
}
```

### With Consul Connect

```hcl
service {
  name = "my-app"
  port = "http"

  connect {
    sidecar_service {}
  }
}
```

Notes on Connect sidecars:
- The sidecar proxy uses its own dynamically allocated ports; you typically expose only the service label used by the proxy.
- For mesh-only services, you may not need any host-exposed ports at all.

## Port Configuration Patterns

### Pattern 1: Simple Web Service

```hcl
job "webapp" {
  group "frontend" {
    count = 3  # Multiple instances, each gets different port

    network {
      port "http" { to = 3000 }
    }

    service {
      name = "webapp"
      port = "http"
      tags = ["urlprefix-/"]
    }
  }
}
```

### Pattern 2: Microservice with Multiple Ports

```hcl
job "microservice" {
  group "service" {
    network {
      port "http" { to = 8080 }      # Main service
      port "grpc" { to = 9090 }      # gRPC endpoint
      port "metrics" { to = 2112 }   # Prometheus metrics
      port "health" { to = 8086 }    # Health checks
    }

    service {
      name = "microservice-http"
      port = "http"
    }

    service {
      name = "microservice-grpc"
      port = "grpc"
    }

    service {
      name = "microservice-metrics"
      port = "metrics"
      tags = ["prometheus"]
    }
  }
}
```

### Pattern 3: Database with Static Port

```hcl
job "postgres" {
  group "db" {
    network {
      port "db" {
        static = 5432  # Standard PostgreSQL port
        to = 5432
      }
    }

    service {
      name = "postgres"
      port = "db"

      # Only accessible within the cluster
      tags = ["internal"]
    }
  }
}
```

Caveat with static + scale:
- If count > number of eligible nodes, Nomad cannot place all allocations (per-node port conflict). Keep count <= eligible nodes or use dynamic ports behind a proxy.

## Container Configuration

### Configurable Port Applications

```hcl
task "app" {
  driver = "docker"

  config {
    image = "myapp:latest"
    ports = ["http"]
  }

  # Pass dynamic port to application
  env {
    PORT = "${NOMAD_PORT_http}"
    LISTEN_ADDR = "0.0.0.0:${NOMAD_PORT_http}"
  }
}
```

### Fixed Port Applications

```hcl
task "legacy-app" {
  driver = "docker"

  config {
    image = "legacy:latest"
    ports = ["http"]
  }

  # If app can't be configured, use 'to' in network block
  # network { port "http" { to = 8080 } }
}
```

If the container absolutely cannot change its listen port, prefer using `to` with a dynamic host port rather than statically claiming the host port.

## Common Issues and Solutions

### Issue 1: Port Conflicts

**Symptom**: Allocation fails with "port already in use"

**Solution**: Check for static port conflicts
```bash
# Find what's using the port
nomad job status | grep "static ="
ss -tlnp | grep :<port>
```

### Issue 2: Service Unreachable

**Symptom**: Service running but can't connect

**Solutions**:
1. Check firewall allows dynamic range (20000-32000)
2. Verify service registration in Consul
3. Ensure health checks are passing
4. Confirm Traefik/Consul Catalog sees the correct port label and address
5. If using host networking, verify the service is binding 0.0.0.0 (not only 127.0.0.1)

### Issue 3: Container Can't Bind Port

**Symptom**: Container fails to start, "address already in use"

**Solution**: Use the `to` parameter
```hcl
port "http" {
  to = 8080  # Container expects this port
}
```

Also check for per-node reserved ports in the Nomad client configuration.

### Issue 4: Dynamic Port Collides with Local Firewall Rules

Open the dynamic range in host firewalls and upstream security groups:

- Default dynamic range: 20000-32000 (unless customized)
- Ensure outbound health checks and LB probes can reach allocated ports

## Migration Guide

### Moving from Static to Dynamic Ports

#### Step 1: Update Job Specification
```hcl
# Before
network {
  port "http" {
    static = 8080
  }
}

# After
network {
  port "http" {
    to = 8080  # If app expects specific port
  }
}
```

#### Step 2: Add Load Balancer Routing
```hcl
service {
  tags = [
    "traefik.enable=true",
    "traefik.http.routers.app.rule=Host(`app.lab.local`)",
  ]
}
```

#### Step 3: Update DNS/Documentation
- Change from `node-ip:8080` to `app.lab.local`
- Update any hardcoded references
 - Document the port label(s) in your service README

### Optional: Adjust Nomad client reserved ports

Reserve well-known ports on nodes so dynamic allocation never uses them:

```hcl
# /etc/nomad.d/client.hcl
client {
  reserved_ports = "22,25,53,80,443,8500,8600,4646,4647,4648"
  # reserved_networks = "10.0.0.0/24"  # Optional, avoid binding to specific subnets
}
```

## Testing Port Allocation

### Pre-deployment Checks

```bash
# Check available port range
nomad node status -self | grep "Reserved Ports"

# Dry run job
nomad job plan my-job.hcl

# Validate job
nomad job validate my-job.hcl
```

### Post-deployment Verification

```bash
# Check allocated ports
nomad alloc status <alloc-id> | grep "Port"

# Verify service discovery
dig @localhost -p 8600 my-service.service.consul

# Test connectivity
curl http://<node-ip>:<dynamic-port>/health

# Verify the app received env vars
nomad alloc exec <alloc-id> env | grep -E "NOMAD_(PORT|ADDR|IP)_"
```

## Best Practices Summary

1. **Default to Dynamic Ports**: Use static ports only when absolutely necessary
2. **One Load Balancer**: Only one service should claim ports 80/443
3. **Service Discovery**: Use Consul for internal service communication
4. **Health Checks**: Always configure health checks for services
5. **Port Documentation**: Document any static port requirements
6. **Firewall Rules**: Ensure dynamic port range is open (20000-32000)
7. **Container Flexibility**: Make containers accept PORT environment variable

## Related Resources

- [Firewall and Port Strategy](../operations/firewall-port-strategy.md)
- [Nomad Network Stanza](https://www.nomadproject.io/docs/job-specification/network)
- [Consul Service Discovery](https://www.consul.io/docs/discovery/services)
- [Traefik Dynamic Configuration](https://doc.traefik.io/traefik/providers/consul-catalog/)
