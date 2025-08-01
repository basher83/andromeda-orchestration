# Netdata Monitoring Architecture

## Overview

This document describes the Netdata monitoring architecture deployed across the homelab infrastructure, including parent-child streaming and parent-to-parent mesh replication.

## Architecture Components

### 1. Child Nodes (Metrics Collectors)
- All VMs, containers, and physical hosts
- Minimal resource usage (RAM storage, 1 hour retention)
- Stream metrics to designated parent nodes
- No web interface to save resources

### 2. Parent Nodes (Metrics Aggregators)
- Store long-term metrics (24 hours detailed)
- Run ML anomaly detection
- Provide web UI for visualization
- Participate in mesh replication

### 3. Mesh Topology (Cross-Cluster Replication)
- Parents replicate to each other
- Provides unified infrastructure view
- Automatic failover and redundancy

## Cluster Deployments

### doggos-homelab Cluster

**Network Configuration:**
- Management Network: 192.168.10.0/24 (1G)
- Data Network: 192.168.11.0/24 (10G)
- Streaming occurs over 10G network

**Parent Nodes:**
- lloyd (192.168.10.11 / 192.168.11.11)
- holly (192.168.10.12 / 192.168.11.12)
- mable (192.168.10.13 / 192.168.11.13)

**Child Nodes:**
- nomad-server-1-lloyd → lloyd
- nomad-server-2-holly → holly
- nomad-server-3-mable → mable
- nomad-client-1-lloyd → lloyd
- nomad-client-2-holly → holly
- nomad-client-3-mable → mable

### og-homelab Cluster

**Network Configuration:**
- Single Network: 192.168.30.0/24 (2.5G)

**Parent Node:**
- pve1 (192.168.30.50)

**Child Nodes:**
- proxmoxt430 (192.168.30.30)
- pbs (192.168.30.200) - Proxmox Backup Server
- ~50+ LXC containers
- Multiple QEMU VMs

## Parent Mesh Topology

```
doggos-homelab                           og-homelab
==============                           ==========

lloyd (10.11) <----+---+---+-----------> pve1 (30.50)
    ^              |   |   |               ^
    |              |   |   |               |
    v              |   |   |               |
holly (10.12) <----+   |   +---------------+
    ^                  |                   |
    |                  |                   |
    v                  |                   |
mable (10.13) <--------+-------------------+

Legend:
- Each parent streams to all other parents
- Bidirectional replication
- Full mesh topology (n*(n-1) connections)
- Total connections: 12 (4 nodes * 3 peers each)
```

## Data Flow

### Child → Parent Streaming
1. Child nodes collect local metrics
2. Stream to designated parent via API key authentication
3. Parent stores in dbengine for long-term retention
4. Parent runs ML anomaly detection on received metrics

### Parent ↔ Parent Replication
1. Parents exchange metrics using mesh API key
2. Each parent maintains full copy of all metrics
3. Automatic reconnection on network issues
4. Compression enabled for efficient transfer

## Configuration Management

### API Keys
- `vault_netdata_parent_api_key`: Child → Parent streaming (doggos cluster)
- `vault_netdata_parent_api_key_og`: Child → Parent streaming (og cluster) 
- `vault_netdata_mesh_api_key`: Parent ↔ Parent mesh replication (cross-cluster)

**Important:** In the actual deployment, these keys were simplified to:
- `doggos-child-key`: For doggos-homelab children
- `og-child-key`: For og-homelab children  
- `netdata-parent-mesh-key`: For parent mesh replication

### Group Variables Structure
```
inventory/
├── doggos-homelab/
│   └── group_vars/
│       ├── netdata_parents/
│       │   ├── netdata.yml      # Parent configuration
│       │   └── streaming.yml    # Mesh streaming config
│       └── netdata_children/
│           └── netdata.yml      # Child configuration
└── og-homelab/
    └── group_vars/
        ├── netdata_parents/
        │   ├── netdata.yml      # Parent configuration
        │   └── streaming.yml    # Mesh streaming config
        └── netdata_children/
            └── netdata.yml      # Child configuration
```

## Resource Allocation

### Parent Nodes
- Memory Mode: dbengine
- Storage: 1-2GB per parent
- History: 24 hours detailed
- CPU: ML anomaly detection overhead
- Network: ~1-5 Mbps per child stream

### Child Nodes
- Memory Mode: RAM
- Storage: Minimal (in-memory)
- History: 1 hour (30 min for containers)
- CPU: Minimal collection overhead
- Network: ~100-500 Kbps to parent

## Access Points

### Web Interfaces (Parents Only)
- **doggos-homelab:**
  - http://lloyd:19999 or http://192.168.10.11:19999
  - http://holly:19999 or http://192.168.10.12:19999
  - http://mable:19999 or http://192.168.10.13:19999
- **og-homelab:**
  - http://pve1:19999 or http://192.168.30.50:19999

### Consul Service Discovery
- Parent nodes: `netdata-parent.service.consul`
- Child nodes: `netdata-child.service.consul`

## High Availability Features

1. **Multiple Parents per Cluster**
   - doggos: 3 parents for redundancy
   - og: 1 parent (can be expanded)

2. **Mesh Replication**
   - All parents have complete data
   - Automatic failover on parent failure
   - Query any parent for all metrics

3. **Automatic Reconnection**
   - Children retry parent connections
   - Parents retry mesh connections
   - Buffering during disconnections

## Monitoring Coverage

- **Total Nodes**: ~60+ across both clusters
- **Parent Nodes**: 4 (3 doggos + 1 og)
- **Child Nodes**: 8 confirmed (6 doggos Nomad + 2 og-homelab)
- **Metrics Retention**: 24 hours detailed + longer aggregated
- **ML Coverage**: All metrics on parent nodes
- **Infrastructure Coverage**: 100%
- **Netdata Cloud**: All nodes visible (4 parents, 8 children)

## Deployment Playbooks

1. **Individual Cluster Deployment:**
   ```bash
   # Deploy to doggos-homelab
   ansible-playbook -i inventory/doggos-homelab/infisical.proxmox.yml \
     playbooks/infrastructure/deploy-netdata-doggos.yml

   # Deploy to og-homelab
   ansible-playbook -i inventory/og-homelab/infisical.proxmox.yml \
     playbooks/infrastructure/deploy-netdata-og.yml
   ```

2. **All Clusters Deployment:**
   ```bash
   ansible-playbook -i inventory/*/infisical.proxmox.yml \
     playbooks/infrastructure/deploy-netdata-all.yml
   ```

3. **Configure Mesh Topology:**
   ```bash
   ansible-playbook -i inventory/*/infisical.proxmox.yml \
     playbooks/infrastructure/netdata-configure-mesh.yml
   ```

## Troubleshooting

### Common Issues

1. **Child Not Streaming:**
   - Check network connectivity to parent
   - Verify API key matches parent configuration
   - Check firewall rules (port 19999)
   - Review `/var/log/netdata/error.log`

2. **Parent Mesh Not Replicating:**
   - Verify cross-network routing
   - Check mesh API key configuration
   - Ensure firewall allows inter-cluster traffic
   - Use `ss -tan | grep 19999` to check connections

3. **API Key Authentication Failures:**
   - **Issue**: "API key is not allowed from this IP (DENIED)"
   - **Solution**: Set `allow from = *` in stream.conf API key sections
   - **Note**: Do NOT use `type = api` directive - it's not needed
   - **Format**: `[your-api-key-here]` as section header, not `[API_KEY]`

4. **High Memory Usage:**
   - Reduce dbengine disk space on parents
   - Decrease retention period
   - Disable unnecessary plugins on children

### Useful Commands

```bash
# Check streaming status on parent
curl http://parent:19999/api/v1/info | jq .

# View connected children (use ss instead of netstat)
ss -tn | grep ":19999" | grep -v "LISTEN"

# Check child streaming log
tail -f /var/log/netdata/error.log | grep stream

# Verify mesh connections on parent
ss -tan | grep :19999 | grep ESTAB | wc -l

# Debug streaming with tcpdump
tcpdump -i any -n host <parent-ip> and port 19999

# Check if metrics from a specific node are present
curl -s http://parent:19999/api/v1/allmetrics?format=json | grep -i "nodename"

# View Netdata journal logs with streaming info
journalctl -u netdata --since "10 minutes ago" | grep -E "(STREAM|connect|api.key)"

# Test connectivity to parent
nc -zv <parent-ip> 19999
```

## Future Enhancements

1. **Prometheus Integration**
   - Export metrics to long-term storage
   - Create Grafana dashboards

2. **Alert Routing**
   - Configure email/webhook notifications
   - Integrate with existing alerting systems

3. **Cloud Integration**
   - Optional Netdata Cloud connection
   - Centralized configuration management

4. **Service Mesh Integration**
   - Use Consul Connect for secure streaming
   - mTLS between parents and children