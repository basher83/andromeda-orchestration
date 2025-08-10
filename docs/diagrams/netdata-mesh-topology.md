# Netdata Mesh Topology Diagram

## Overview

This diagram illustrates the Netdata monitoring architecture with parent-child streaming and parent-to-parent mesh replication across multiple clusters.

## Architecture Diagram

```mermaid
graph TB
    subgraph "doggos-homelab Cluster"
        subgraph "Physical Hosts (Parents)"
            L[lloyd<br/>10.11/11.11]
            H[holly<br/>10.12/11.12]
            M[mable<br/>10.13/11.13]
        end

        subgraph "Nomad VMs (Children)"
            NS1[nomad-server-1]
            NS2[nomad-server-2]
            NS3[nomad-server-3]
            NC1[nomad-client-1]
            NC2[nomad-client-2]
            NC3[nomad-client-3]
        end

        %% Child to Parent Streaming
        NS1 -->|stream| L
        NC1 -->|stream| L
        NS2 -->|stream| H
        NC2 -->|stream| H
        NS3 -->|stream| M
        NC3 -->|stream| M
    end

    subgraph "og-homelab Cluster"
        subgraph "Proxmox Host (Parent)"
            P1[pve1<br/>30.50]
        end

        subgraph "Containers & VMs (Children)"
            P430[proxmoxt430]
            C1[50+ Containers]
            V1[Multiple VMs]
        end

        %% Child to Parent Streaming
        P430 -->|stream| P1
        C1 -->|stream| P1
        V1 -->|stream| P1
    end

    %% Parent Mesh Replication
    L <--> |mesh| H
    L <--> |mesh| M
    H <--> |mesh| M
    L <--> |mesh| P1
    H <--> |mesh| P1
    M <--> |mesh| P1

    %% Styling
    classDef parent fill:#4a9eff,stroke:#333,stroke-width:3px,color:#fff
    classDef child fill:#95d3ff,stroke:#333,stroke-width:2px
    classDef mesh stroke:#ff6b6b,stroke-width:3px,stroke-dasharray: 5 5

    class L,H,M,P1 parent
    class NS1,NS2,NS3,NC1,NC2,NC3,P430,C1,V1 child
```

## Data Flow Details

### Child → Parent Streaming (Blue Lines)

- **Protocol**: HTTP/HTTPS on port 19999
- **Direction**: Unidirectional (child to parent)
- **Authentication**: API key per cluster
- **Compression**: Enabled by default
- **Buffering**: 30 seconds on network failure

### Parent ↔ Parent Mesh (Red Dashed Lines)

- **Protocol**: HTTP/HTTPS on port 19999
- **Direction**: Bidirectional replication
- **Authentication**: Mesh-specific API key
- **Full Mesh**: Each parent connects to all others
- **Total Connections**: 12 (4 nodes × 3 peers each)

## Network Topology

### doggos-homelab Networks

```text
Management: 192.168.10.0/24 (1G) - Used for mesh cross-cluster
Data:       192.168.11.0/24 (10G) - Used for child streaming
```

### og-homelab Network

```text
Single:     192.168.30.0/24 (2.5G) - All traffic
```

### Cross-Cluster Routing

- og-homelab (30.0/24) → doggos management (10.0/24)
- doggos nodes use dual-NIC configuration
- Mesh traffic uses management network for cross-cluster

## Benefits of Mesh Topology

1. **Unified Monitoring**
   - Access all ~60+ nodes from any parent
   - Single pane of glass for entire infrastructure

2. **High Availability**
   - 4 parent nodes provide redundancy
   - Automatic failover if parent fails
   - No single point of failure

3. **Load Distribution**
   - Query any parent node
   - Distribute dashboard load
   - Parallel query processing

4. **Cross-Cluster Visibility**
   - View og-homelab from doggos cluster
   - View doggos cluster from og-homelab
   - Correlate metrics across locations

## Access Points

### Web Dashboards

- [http://lloyd:19999](http://lloyd:19999) - Full infrastructure view
- [http://holly:19999](http://holly:19999) - Full infrastructure view
- [http://mable:19999](http://mable:19999) - Full infrastructure view
- [http://192.168.30.50:19999](http://192.168.30.50:19999) - Full infrastructure view

### API Endpoints

- `/api/v1/info` - Node information
- `/api/v1/data` - Query metrics
- `/api/v1/alarms` - Active alarms
- `/api/v1/contexts` - Available metrics

## Configuration Keys

### API Key Architecture

```yaml
# Child streaming keys (per cluster)
vault_netdata_parent_api_key: "doggos-child-key"
vault_netdata_parent_api_key_og: "og-child-key"

# Mesh replication key (shared)
vault_netdata_mesh_api_key: "parent-mesh-key"
```

### Resource Allocation

```yaml
# Parent nodes
Memory: dbengine mode
Storage: 1-2GB per parent
Retention: 24 hours detailed

# Child nodes
Memory: RAM mode
Storage: In-memory only
Retention: 1 hour (30min for containers)
```

## Deployment Order

1. **Deploy Parents First**
   - Configure dbengine storage
   - Set up API keys
   - Enable web interface

2. **Deploy Children**
   - Configure streaming destination
   - Disable web interface
   - Minimize plugins

3. **Configure Mesh**
   - Update parent streaming configs
   - Add mesh API key
   - Restart parents

4. **Verify Topology**
   - Check connection counts
   - Test cross-cluster visibility
   - Verify redundancy

## Related Documentation

- [Netdata Role README](../../roles/netdata/README.md)
- [Infrastructure Architecture](../infrastructure/netdata-architecture.md)
- [Deployment Playbooks](../../playbooks/infrastructure/)
