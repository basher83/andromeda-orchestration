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

### Issue 3: Container Can't Bind Port

**Symptom**: Container fails to start, "address already in use"

**Solution**: Use the `to` parameter
```hcl
port "http" {
  to = 8080  # Container expects this port
}
```

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