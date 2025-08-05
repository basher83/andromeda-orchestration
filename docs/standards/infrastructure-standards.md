# Infrastructure Standards

## Purpose

Define infrastructure architecture standards that ensure scalability, maintainability, and operational excellence.

## Background

Our infrastructure has evolved from static, manually-configured systems to dynamic, service-discovered, and auto-scaling platforms. These standards codify the patterns that have proven successful.

## Standard

### Service Discovery Architecture

#### Why Service Discovery Over Static Configuration?

1. **Dynamic Infrastructure**: Services move between nodes
2. **Automatic Updates**: No manual configuration changes
3. **Health-Aware**: Only route to healthy instances
4. **Scale Friendly**: Add/remove instances without reconfiguration
5. **DNS Integration**: Everything accessible via DNS names

#### Implementation

```
Service Registration → Consul → DNS/API → Service Discovery
                          ↓
                     Health Checks
                          ↓
                    Load Balancing (Traefik)
```

### Network Architecture

#### Port Allocation Strategy

```
Static Ports (Exceptions only):
├── 53   - DNS (PowerDNS)
├── 80   - HTTP (Traefik)
├── 443  - HTTPS (Traefik)
└── [Everything else: Dynamic 20000-32000]
```

**Why Dynamic Ports?**

- **No Conflicts**: Nomad manages allocation
- **Security**: Ports change on redeploy
- **Flexibility**: Services can move nodes
- **Simplicity**: No port planning needed

### Infrastructure Layers

```
Application Layer
├── User Applications (Gitea, Windmill, etc.)
└── Uses: Platform Services

Platform Services Layer
├── PowerDNS - Authoritative DNS
├── NetBox - IPAM/DCIM (future)
├── Monitoring - Metrics/Logs
└── Uses: Core Infrastructure

Core Infrastructure Layer
├── Traefik - Load Balancing
├── Consul - Service Discovery
├── Nomad - Orchestration
└── Base services everything depends on
```

### Monitoring Philosophy

#### Multi-Layer Monitoring

```
Infrastructure Monitoring (Netdata)
├── Real-time metrics (1-second resolution)
├── Anomaly detection (ML-based)
├── Parent-child streaming architecture
└── No external dependencies

Application Monitoring (Future Prometheus)
├── Application-specific metrics
├── Business metrics
├── Long-term storage
└── Complex queries
```

**Why Both?**

- **Netdata**: Instant visibility, no configuration
- **Prometheus**: Application insights, custom metrics
- **Complementary**: Different use cases, not redundant

### Security Standards

#### Network Segmentation

**doggos-homelab Cluster:**

```
Management Network (192.168.10.0/24) - 1G
├── Proxmox hosts management
├── Infrastructure services
└── Administrative access

Data Network (192.168.11.0/24) - 10G
├── High-throughput services
├── Netdata streaming
├── Storage traffic
└── Inter-node communication
```

**og-homelab Cluster:**

```
Combined Network (192.168.30.0/24) - 2.5G
├── All services (management + data)
├── Proxmox hosts
├── LXC containers
└── Service discovery
```

**Future Networks:**

```
Storage Network (TBD) [Ready to implement - NICs available]
├── Dedicated NFS/iSCSI traffic
├── Backup traffic isolation
├── Storage systems to migrate:
│   ├── Proxmox Backup Server (currently 192.168.30.200)
│   └── TrueNAS (currently 192.168.30.6)
└── Separate from service networks

DMZ Network (TBD) [Future]
├── Public-facing services
├── Reverse proxy endpoints
└── Isolated from internal networks
```

**Network Isolation Benefits:**

- **Performance**: Prevent backup/storage traffic from impacting services
- **Security**: Isolate storage systems from general network
- **QoS**: Prioritize different traffic types appropriately
- **Scalability**: Add storage nodes without network congestion

#### Access Control

- **Zero Trust**: Authenticate everything
- **Service Identity**: Every service has identity
- **mTLS**: Service-to-service encryption (future)
- **ACLs**: Consul/Nomad ACLs enforced

### High Availability Patterns

#### Service HA

```
Active-Active Services:
├── Traefik (multiple instances)
├── Consul (3-5 servers)
├── Nomad (3-5 servers)
└── Stateless, replicated

Active-Passive Services:
├── PowerDNS (primary/secondary)
├── Databases (primary/replica)
└── Stateful, failover-based
```

## Rationale

### Why Dynamic Everything?

- **Cloud-Native**: Treat on-prem like cloud
- **Cattle not Pets**: Services are replaceable
- **Automation First**: Manual = mistake-prone
- **Scale Ready**: Patterns work at any size

### Why Service Mesh Architecture?

- **Decoupling**: Services don't know about infrastructure
- **Flexibility**: Change infrastructure without app changes
- **Observability**: Automatic metrics and tracing
- **Security**: Centralized policy enforcement

### Why Proxmox + Nomad?

- **Proxmox**: Robust VM platform, good API
- **Nomad**: Simple but powerful orchestration
- **Together**: Best of VMs and containers
- **Alternative to**: Complex Kubernetes for homelab

## Examples

### Good Example: Service Deployment

```hcl
# Service registers itself with Consul
service {
  name = "my-app"
  port = "web"  # Dynamic port

  tags = [
    "traefik.enable=true",
    "traefik.http.routers.myapp.rule=Host(`myapp.lab.local`)",
  ]

  check {
    type     = "http"
    path     = "/health"
    interval = "10s"
  }

  identity {
    aud = ["consul.io"]
  }
}
```

### Bad Example: Static Configuration

```yaml
# ❌ Hardcoded addresses
upstream app {
  server 192.168.1.10:8080;  # What if it moves?
  server 192.168.1.11:8080;  # What if it's down?
}
```

## Exceptions

- **Legacy Systems**: May require static IPs temporarily
- **External Services**: Not everything can use service discovery
- **Compliance Requirements**: Some regulations require static configs

## Migration

### To Dynamic Infrastructure

1. **Enable Service Discovery**: Deploy Consul
2. **Add Health Checks**: Define for each service
3. **Implement Load Balancing**: Deploy Traefik
4. **Migrate Services**: One at a time
5. **Update DNS**: Point to new infrastructure

### To Monitoring

1. **Deploy Netdata**: Immediate visibility
2. **Configure Streaming**: Parent-child architecture
3. **Add Dashboards**: Key metrics visible
4. **Plan Prometheus**: For application metrics
5. **Implement Alerting**: Critical issues only

## References

### Internal Documentation

- [Network Architecture](../diagrams/network-port-architecture.md)
- [Firewall Strategy](../operations/firewall-port-strategy.md)
- [Netdata Architecture](../operations/netdata-architecture.md)
- [Service Identity](../troubleshooting/service-identity-issues.md)

### Related Repositories

- [terraform-homelab](https://github.com/basher83/terraform-homelab) - IaC for infrastructure provisioning
- [Mission Control](https://github.com/basher83/docs/tree/main/mission-control) - Organization-wide standards
