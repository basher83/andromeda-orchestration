# Firewall and Port Allocation Strategy

This document defines the firewall rules and port allocation strategies for the homelab infrastructure, particularly focusing on Nomad-managed services.

## Overview

Our infrastructure uses a combination of static and dynamic port allocation to prevent conflicts while maintaining security and flexibility. The strategy is optimized for a homelab environment where ease of deployment is prioritized over production-level security.

## Core Principles

### 1. Dynamic Ports by Default
- **Range**: 20000-32000 (Nomad's default dynamic range)
- **Usage**: All web services, APIs, and containerized applications
- **Access**: Via load balancer using service discovery

### 2. Static Ports Only When Required
- **DNS (53)**: Must be on standard port for resolver compatibility
- **Load Balancer (80/443)**: ONE service owns these for all HTTP/HTTPS traffic
- **Legacy Services**: Only when absolutely necessary

### 3. Service Discovery over Direct Access
- Services register with Consul
- Load balancer routes based on hostname/path
- Internal communication uses `.consul` domains

## Firewall Rules (nftables)

### Base Infrastructure Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 22 | TCP | SSH | Remote administration |
| 4646 | TCP | Nomad | HTTP API |
| 4647-4648 | TCP/UDP | Nomad | RPC and Serf |
| 8300-8302 | TCP/UDP | Consul | Server RPC, Serf LAN/WAN |
| 8500 | TCP | Consul | HTTP API |
| 8600 | TCP/UDP | Consul | DNS interface |
| 19999 | TCP | Netdata | Monitoring dashboard |
| 2375-2376 | TCP | Docker | API for Nomad |

### Dynamic Service Ports

| Port Range | Protocol | Purpose |
|------------|----------|---------|
| 20000-32000 | TCP/UDP | Nomad dynamic allocation |

### Static Service Ports

| Port | Protocol | Service | Justification |
|------|----------|---------|---------------|
| 53 | TCP/UDP | DNS | Standard resolver port |
| 8081 | TCP | PowerDNS API | Currently static (should migrate) |

## Port Allocation Patterns

### Pattern 1: Web Services (Recommended)

```hcl
# Nomad job specification
network {
  port "http" {
    to = 8000  # Container's internal port
    # Nomad assigns: 24563 (example)
  }
}

# Access via: https://service.example.com (through load balancer)
```

### Pattern 2: Load Balancer (One Per Cluster)

```hcl
network {
  port "http" {
    static = 80   # Only ONE service can use this
  }
  port "https" {
    static = 443  # Only ONE service can use this
  }
}
```

### Pattern 3: Network Services

```hcl
network {
  port "dns" {
    static = 53   # Required for standard DNS
  }
}
```

## Common Pitfalls to Avoid

### ❌ Don't: Request Static Ports for Web Services
```hcl
# BAD: Creates conflicts
network {
  port "http" {
    static = 80  # Will conflict with load balancer!
  }
}
```

### ✅ Do: Use Dynamic Ports with Service Discovery
```hcl
# GOOD: No conflicts
network {
  port "http" {
    to = 3000  # Internal port
  }
}

service {
  name = "my-app"
  port = "http"
  tags = ["urlprefix-/myapp"]  # For load balancer routing
}
```

## Service Access Patterns

### External Access (Users)
```
User → Load Balancer (80/443) → Consul Discovery → Service (dynamic port)
```

### Internal Access (Service-to-Service)
```
Service A → service-b.service.consul:port → Service B
```

### Direct Access (Debugging)
```
Admin → node-ip:dynamic-port → Service
```

## Implementation Checklist

When deploying a new service:

1. **Determine Port Requirements**
   - [ ] Can it use a dynamic port? (default: yes)
   - [ ] Does it require a well-known port? (rare)
   - [ ] Will users access it directly? (use load balancer instead)

2. **Configure Nomad Job**
   - [ ] Use dynamic port allocation
   - [ ] Configure health checks
   - [ ] Add Consul service registration
   - [ ] Include routing tags for load balancer

3. **Update Load Balancer**
   - [ ] Add routing rules (if needed)
   - [ ] Configure SSL certificates
   - [ ] Test service discovery

4. **Document Service**
   - [ ] Add to service registry
   - [ ] Document access patterns
   - [ ] Note any special requirements

## Firewall Management

### Adding New Static Ports

1. **Justify the Need**
   - Why can't this use dynamic ports?
   - Is this a standard protocol requirement?
   - Are there alternatives?

2. **Update nftables Template**
   ```bash
   vim playbooks/infrastructure/network/templates/nftables-nomad-client.conf.j2
   ```

3. **Apply Changes**
   ```bash
   uv run ansible-playbook playbooks/infrastructure/network/update-nftables-nomad.yml \
     -i inventory/doggos-homelab/infisical.proxmox.yml
   ```

### Monitoring Port Usage

```bash
# View current nftables rules
nft list ruleset

# Check Nomad port allocations
nomad node status -verbose <node-id>

# List Consul services
consul catalog services
```

## Examples

### Example 1: Deploying Windmill

```hcl
job "windmill" {
  group "windmill" {
    network {
      port "http" {
        to = 8000  # Windmill's default port
      }
    }
    
    service {
      name = "windmill"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.windmill.rule=Host(`windmill.lab.local`)"
      ]
    }
  }
}
```

### Example 2: Deploying Grafana

```hcl
job "grafana" {
  group "grafana" {
    network {
      port "http" {
        to = 3000  # Grafana's default port
      }
    }
    
    service {
      name = "grafana"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.grafana.rule=Host(`grafana.lab.local`)"
      ]
    }
  }
}
```

## Load Balancer Options

### Recommended: Traefik
- Native Consul integration
- Automatic service discovery
- Built-in Let's Encrypt support
- Dynamic configuration

### Alternative: Caddy
- Simple configuration
- Automatic HTTPS
- Good for basic routing

### Alternative: nginx
- Familiar to many users
- Requires manual configuration
- Use with consul-template for automation

## Troubleshooting

### Port Conflicts
```bash
# Check what's using a port
ss -tlnp | grep :80

# Find Nomad allocation using a port
nomad job status <job-name>
nomad alloc status <alloc-id>
```

### Service Discovery Issues
```bash
# Verify service registration
consul catalog services
dig @localhost -p 8600 service.service.consul

# Check service health
consul watch -type=service -service=<service-name>
```

### Firewall Blocking
```bash
# Test connectivity
nc -zv <node-ip> <port>

# Check nftables logs
journalctl -u nftables -f
```

## Related Documentation

- [Nomad Networking](https://www.nomadproject.io/docs/job-specification/network)
- [Consul Service Discovery](https://www.consul.io/docs/discovery/services)
- [Traefik Consul Catalog](https://doc.traefik.io/traefik/providers/consul-catalog/)
- Network Architecture Diagram: `/docs/diagrams/network-port-architecture.md` (TODO)