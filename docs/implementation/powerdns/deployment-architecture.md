# PowerDNS Deployment Architecture

## Overview

This document captures the architectural decision for PowerDNS deployment on Nomad, comparing two deployment patterns and documenting the chosen approach for production.

## Decision Summary

### Chosen Architecture: Mode A (Simple/Production-Ready)

After evaluating deployment patterns, we selected the simpler Mode A architecture that deploys PowerDNS Authoritative Server directly on port 53 with an external PostgreSQL backend.

## Architecture Comparison

### Mode A: Direct Authoritative DNS

```text
┌─────────────┐     :53      ┌─────────────┐     DB      ┌─────────────┐
│ DNS Clients │ ──────────> │ PowerDNS    │ <────────> │ PostgreSQL  │
└─────────────┘              │   Auth      │            │  (External) │
                             └─────────────┘            └─────────────┘
```

**Characteristics:**

- PowerDNS Auth serves directly on port 53
- External PostgreSQL for zone data
- Simple, single-service deployment
- Authoritative-only DNS

### Mode B: Full Stack with dnsdist

```text
┌─────────────┐     :53      ┌─────────────┐     :5301     ┌─────────────┐
│ DNS Clients │ ──────────> │   dnsdist   │ ──────────> │ PowerDNS    │
└─────────────┘              │   (Proxy)   │              │   Auth      │
                             └─────────────┘              └─────────────┘
                                    │
                                    │ :5300
                                    ↓
                             ┌─────────────┐
                             │ PowerDNS    │
                             │  Recursor   │
                             └─────────────┘
```

**Characteristics:**

- dnsdist proxy on port 53
- Separate auth and recursive resolvers
- Complex, multi-service deployment
- Supports both authoritative and recursive DNS

## Why Mode A Was Chosen

### 1. Simplicity

- Single service to deploy and manage
- Direct DNS serving without proxy overhead
- Fewer failure points

### 2. Alignment with Standards

- Static port 53 (as per our Nomad standards)
- Dynamic API ports (20000-32000)
- Consul service discovery
- Traefik for API ingress

### 3. Production Readiness

- External PostgreSQL for better data persistence
- Proper secrets management via Vault
- Host networking for optimal DNS performance
- Built-in HA with count=2 and distinct_hosts affinity

### 4. Operational Benefits

- Easier troubleshooting
- Lower latency (no proxy layer)
- Simpler monitoring requirements
- Clear upgrade path to Mode B if needed

## Implementation Guide

### Prerequisites

1. **PostgreSQL Database** (Deployed)

   - Deploy using `nomad-jobs/platform-services/postgresql.nomad.hcl`
   - Ensure host volume configured for data persistence

1. **Consul KV Configuration**

   ```bash
   consul kv put pdns/db/host postgres.service.consul
   consul kv put pdns/db/port 5432
   consul kv put pdns/db/name powerdns
   consul kv put pdns/db/user pdns
   ```

1. **Vault Secrets**

```bash
vault kv put kv/pdns \
  db_password="<secure-password>" \
  api_key="<secure-api-key>"
```

### Deployment Steps

1. **Phase 1: Database Setup**

   ```bash
   # Deploy PostgreSQL
   nomad job run postgresql.nomad.hcl
   ```

```bash
# Deploy PostgreSQL
nomad job run postgresql.nomad.hcl

# Initialize PowerDNS schema
# Connect to PostgreSQL and run PowerDNS schema
```

1. **Phase 2: Configure Secrets**

   ```bash
   # Set up Consul KV values
   ./scripts/setup-pdns-consul-kv.sh

   # Configure Vault secrets
   ./scripts/setup-pdns-vault.sh
   ```

1. **Phase 3: Deploy/Configure PowerDNS** (Configure for PostgreSQL backend)

   ```bash
   # Deploy or update PowerDNS job (configured for PostgreSQL backend)
   nomad job run nomad-jobs/platform-services/powerdns.nomad.hcl
   ```

1. **Phase 4: Verify Deployment**

   ```bash
   # Check service registration
   consul catalog services | grep powerdns

   # Test DNS resolution
   dig @<node-ip> example.spaceships.work
   ```

## Test DNS resolution

```bash
dig @<node-ip> example.lab
```

## Configuration

### Network Configuration

- **DNS Port**: Static port 53 (TCP/UDP)
- **API Port**: Dynamic allocation (20000-32000)
- **Network Mode**: Host networking for optimal performance

### High Availability

- **Instance Count**: 2 (configurable)
- **Placement**: Distinct hosts via affinity rules
- **Health Checks**: TCP checks on port 53

### Service Discovery

- **DNS Service**: `powerdns-auth` in Consul
- **API Service**: `powerdns-auth-api` with Traefik tags

### Security

- Database credentials via Vault
- API key stored in Vault
- Read-only tokens for CI where applicable

### Health Checks

```hcl
check {
  name     = "api"
  type     = "http"
  path     = "/api/v1/servers/localhost"
  interval = "10s"
  timeout  = "2s"
}
```

## Metrics Collection

- Integrate with Netdata for DNS metrics
- PowerDNS API provides statistics endpoint
- Consul health status monitoring

### Troubleshooting

**Service Not Starting:**

- Check PostgreSQL connectivity
- Verify Vault secrets accessible
- Review Nomad allocation logs

**DNS Not Responding:**

- Verify port 53 binding
- Check firewall rules
- Test with `dig` directly to node

**API Inaccessible:**

- Check Traefik routing
- Verify API key in Vault
- Test API directly on dynamic port

## Future Considerations

### Potential Mode B Adoption Triggers

- Need for recursive DNS resolution
- Requirement for complex routing rules
- Multiple DNS backend integration
- Advanced caching requirements

### Enhancement Opportunities

- DNS-over-HTTPS via Traefik
- DNSSEC key management
- Automated zone provisioning from NetBox
- Metrics integration with Prometheus

## Related Documentation

- [Nomad Port Allocation](../nomad/port-allocation.md)
- [Nomad Storage Patterns](../nomad/storage-patterns.md)
- [DNS & IPAM Implementation Plan](../dns-ipam/implementation-plan.md)
- [PowerDNS NetBox Integration](../dns-ipam/powerdns-netbox-integration.md)

## References

- [PowerDNS Authoritative Server Documentation](https://doc.powerdns.com/authoritative/)
- [dnsdist Documentation](https://dnsdist.org/)
- [Nomad Job Specification](https://developer.hashicorp.com/nomad/docs/job-specification)
