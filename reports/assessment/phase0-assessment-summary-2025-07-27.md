# Phase 0 Assessment Summary

Generated: 2025-07-27

## Executive Summary

Successfully gathered critical infrastructure information despite assessment playbook issues. Key findings show healthy Consul and Nomad clusters but no integration between them, and no DNS infrastructure using either service.

## Infrastructure Overview

### Network Architecture

- **192.168.11.x**: 10G high-speed network (servers)
- **192.168.10.x**: 2.5G network (clients and Proxmox nodes)

### Proxmox Clusters

1. **doggos-homelab**: 3 nodes (lloyd, holly, mable)
   - IPs: 192.168.10.2-4
   - Running 6 VMs (3 Nomad servers, 3 Nomad clients)

2. **og-homelab**: Unknown (assessment pending)

## Service Status

### ✅ Consul Cluster

- **Status**: Healthy and operational
- **Nodes**: 6 total (3 servers, 3 clients)
- **Version**: 1.21.2 (one client on 1.20.5)
- **Leader**: nomad-server-2 (192.168.11.12)
- **Services**: Only "consul" service registered
- **DNS**: Port 8600 responding but not integrated
- **ACLs**: Enabled (requiring tokens)

### ✅ Nomad Cluster  

- **Status**: Healthy and operational
- **Nodes**: 6 total (3 servers, 3 clients)
- **Version**: 1.10.2 (one client on 1.10.0)
- **Leader**: 192.168.11.12
- **Jobs**: No active workloads
- **Resources**:
  - Servers: 4 CPU cores, 15Gi RAM each
  - Clients: 4-8 CPU cores, 15Gi RAM each
- **Docker**: Available on all clients
- **ACLs**: Disabled

### ❌ DNS/IPAM Current State

- **Pi-hole**: Located at 192.168.30.100, serving as primary DNS
- **Proxmox nodes**: Configured to use Pi-hole (nameserver 192.168.30.100)
- **Domain**: lab.spaceships.work
- **DNS Records**: VMs registered with clean names (e.g., nomad-server-1.lab.spaceships.work)
- **Name Mismatch**: Proxmox VM names include node suffix (e.g., nomad-server-1-lloyd) but DNS doesn't
- **Consul DNS**: Not being used (port 8600 available but no forwarding)
- **Network Segments**:
  - 192.168.10.x (doggos-homelab 2.5G network)
  - 192.168.11.x (doggos-homelab 10G network)
  - 192.168.30.x (og-homelab subnet)

### ❌ Service Integration

- **Consul-Nomad**: No integration configured
- **DNS**: No services using Consul for DNS
- **Service Discovery**: Not implemented

## Critical Issues

### 1. DNS Resolution Problems

- VM hostnames (e.g., "nomad-server-1-lloyd") don't resolve
- No central DNS authority identified
- Need to locate Pi-hole instance

### 2. Inventory Configuration

- Proxmox inventory not extracting IP addresses correctly
- `ansible_host` not being set, falling back to hostnames
- Compose directive may have syntax issues

### 3. Assessment Playbook Bugs

- Template filter errors (`average`, `first`)
- Undefined variable access on skipped tasks
- Need defensive coding for optional components

## Recommendations

### Immediate Actions

1. **Fix Proxmox Inventory**: Update to use IP addresses directly
2. **Locate Pi-hole**: Check router or separate VM/container
3. **Document IPs**: Create static mapping until DNS fixed

### Phase 1 Preparation

1. **Enable Consul-Nomad Integration**: Configure Consul service registration
2. **Plan DNS Architecture**: Decide on Consul DNS vs PowerDNS approach
3. **Fix Assessment Tools**: Update playbooks for reliable assessment

### Network Considerations

- Leverage 10G network (192.168.11.x) for server-to-server traffic
- Consider network segmentation for services
- Plan for DNS forwarding architecture

## Next Steps

1. Fix inventory to use IPs instead of hostnames
2. Run assessment on og-homelab cluster
3. Locate and document current Pi-hole installation
4. Create network diagram with current state
5. Design target DNS/IPAM architecture
