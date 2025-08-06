# Nomad Implementation Documentation

HashiCorp Nomad configuration and deployment patterns for container orchestration.

## 📚 Documentation

### Storage Configuration
- **[storage-configuration.md](storage-configuration.md)** - Complete guide for Nomad job storage
  - Volume types and use cases
  - CSI plugin configuration
  - Host volume setup
  - Best practices and examples

- **[storage-strategy.md](storage-strategy.md)** - Strategic approach to Nomad storage
  - Storage architecture decisions
  - Data persistence patterns
  - Migration strategies
  - Performance considerations

- **[storage-patterns.md](storage-patterns.md)** - Common storage implementation patterns
  - Database storage patterns
  - Application data patterns
  - Shared storage patterns
  - Backup and recovery patterns

### Network Configuration
- **[port-allocation.md](port-allocation.md)** - Port allocation best practices
  - Dynamic vs static ports
  - Port range management
  - Service discovery integration
  - Load balancer configuration

## 🚀 Quick Start

### Deploy a Job
```bash
# Deploy a Nomad job
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/applications/example.nomad.hcl
```

### Check Job Status
```bash
# Set Nomad address
export NOMAD_ADDR=http://nomad.service.consul:4646

# List jobs
nomad job status

# Check specific job
nomad job status <job-name>
```

## 📋 Implementation Status

### ✅ Completed
- Port allocation strategy
- Storage configuration patterns
- Host volume documentation
- CSI plugin guidance

### 🚧 In Progress
- NFS CSI driver deployment
- Volume migration procedures

### ⏳ Planned
- Multi-region job patterns
- Advanced scheduling constraints
- Autoscaling configuration

## 🏗️ Architecture Overview

### Storage Architecture
```
┌─────────────────────────────────────┐
│         Nomad Job                   │
├─────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐          │
│  │ Task 1  │  │ Task 2  │          │
│  └────┬────┘  └────┬────┘          │
│       │            │                │
│  ┌────▼────────────▼────┐          │
│  │   Shared Volume      │          │
│  └──────────────────────┘          │
└─────────────────────────────────────┘
           │
    ┌──────▼──────┐
    │ Host Volume │ or │ CSI Volume │
    └─────────────┘
```

### Port Allocation Strategy
- **Dynamic Ports** (20000-32000): Default for most services
- **Static Ports**: Only for:
  - DNS (53)
  - HTTP Load Balancer (80)
  - HTTPS Load Balancer (443)
  - Legacy services requiring specific ports

### Integration Points
- **Consul**: Service registration and health checks
- **Vault**: Dynamic secrets and workload identity
- **Traefik**: Load balancing and routing

## 📁 Job Organization

```
nomad-jobs/
├── core-infrastructure/    # Essential services
│   ├── traefik.nomad.hcl  # Load balancer
│   └── vault.nomad.hcl    # Reference only (DO NOT USE)
├── platform-services/      # Infrastructure services
│   ├── powerdns.nomad.hcl
│   └── netbox.nomad.hcl
└── applications/          # User-facing applications
    └── example.nomad.hcl
```

## 🔑 Key Decisions

### Why Dynamic Ports?
- Avoids port conflicts
- Enables multiple instances
- Simplifies deployment
- Works with service discovery

### Why Host Volumes Initially?
- Simple to implement
- No additional infrastructure
- Good for single-node testing
- Clear migration path to CSI

### Why Separate Job Categories?
- Clear deployment priorities
- Different update strategies
- Distinct security policies
- Easier troubleshooting

## 📊 Storage Decision Matrix

| Storage Type | Use Case | Persistence | Performance | Complexity |
|-------------|----------|-------------|-------------|------------|
| Ephemeral | Temp data, caches | None | High | Low |
| Host Volume | Single node apps | Node-local | High | Low |
| CSI Volume | Distributed apps | Cluster-wide | Medium | Medium |
| NFS | Shared data | Network | Low-Medium | Medium |

## 🔧 Troubleshooting

### Common Issues

#### Job Fails to Start
```bash
# Check allocation status
nomad alloc status <alloc-id>

# View allocation logs
nomad alloc logs <alloc-id>

# Check constraints
nomad job plan <job.nomad>
```

#### Port Conflicts
```bash
# Find used ports
ss -tlnp | grep <port>

# Check Nomad allocations
nomad alloc status -json | jq '.TaskStates'
```

#### Volume Mount Issues
```bash
# Check host volume configuration
nomad node status -verbose <node-id>

# Verify permissions
ls -la /opt/nomad-volumes/
```

## 🛠️ Useful Commands

```bash
# Job Management
nomad job run <job.nomad>           # Deploy job
nomad job stop <job-name>           # Stop job
nomad job restart <job-name>        # Restart job

# Debugging
nomad alloc exec <alloc-id> /bin/sh # Shell into container
nomad alloc fs <alloc-id>           # Browse allocation filesystem
nomad alloc signal <alloc-id> HUP   # Send signal to task

# Monitoring
nomad node status                   # List nodes
nomad server members                # Show server cluster
nomad eval list                     # List evaluations
```

## 📚 Further Reading

- [Nomad Documentation](https://developer.hashicorp.com/nomad)
- [Nomad Storage](https://developer.hashicorp.com/nomad/docs/job-specification/volume)
- [Nomad Networking](https://developer.hashicorp.com/nomad/docs/job-specification/network)
- [Job Specification](https://developer.hashicorp.com/nomad/docs/job-specification)
