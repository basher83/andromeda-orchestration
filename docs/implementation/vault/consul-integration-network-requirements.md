# Consul Client Agent Network Requirements for Vault Cluster

## Required Network Ports

The following ports must be open between Vault VMs and the existing Consul cluster for proper agent communication:

### Essential Ports

| Port | Protocol | Direction | Purpose | Required Between |
|------|----------|-----------|---------|-----------------|
| **8301** | TCP/UDP | Bidirectional | LAN Gossip (Serf) | All agents (Vault ↔ Consul cluster) |
| **8300** | TCP | Vault → Consul | Server RPC | Vault agents → Consul servers |
| **8600** | TCP/UDP | Local | DNS Interface | Local queries on Vault VMs |
| **8500** | TCP | Local | HTTP API | Local agent API (127.0.0.1 only) |
| **8502** | TCP | Optional | gRPC API | Service mesh (if needed) |

### Firewall Configuration

#### nftables Rules (for Vault VMs)

```nft
# Consul agent gossip
tcp dport 8301 accept comment "Consul LAN Serf"
udp dport 8301 accept comment "Consul LAN Serf"

# Consul server RPC (outbound)
tcp dport 8300 ip daddr { 192.168.11.11, 192.168.11.12, 192.168.11.13 } accept comment "Consul server RPC"

# Consul DNS (local)
tcp dport 8600 ip saddr 127.0.0.1 accept comment "Consul DNS"
udp dport 8600 ip saddr 127.0.0.1 accept comment "Consul DNS"

# Consul HTTP API (local only)
tcp dport 8500 ip saddr 127.0.0.1 accept comment "Consul HTTP API"
```

### Network Connectivity Matrix

| Source | Destination | Ports | Notes |
|--------|-------------|-------|-------|
| Vault VMs | Consul Servers (192.168.11.11-13) | 8300/tcp, 8301/tcp+udp | Agent to server communication |
| Vault VMs | All Consul Agents | 8301/tcp+udp | Gossip protocol |
| Vault VMs | Vault VMs | 8301/tcp+udp | Inter-agent gossip |
| localhost | localhost (on each Vault VM) | 8500/tcp, 8600/tcp+udp | Local agent API and DNS |

### Network Segments

The Vault cluster operates on the following network segments:

- **Management Network**: Tailscale overlay (*.tailfb3ea.ts.net)
- **Operations Network**: 192.168.11.0/24 (10G network for Consul/Nomad)

Consul agents on Vault VMs will:

1. Bind to the Tailscale interface for cluster communication
2. Join the Consul cluster via the operations network (192.168.11.x)
3. Provide local DNS resolution on port 8600
4. Expose HTTP API only on localhost (127.0.0.1:8500)

### Security Considerations

1. **Gossip Encryption**: All agent communication encrypted with shared key
2. **ACL Tokens**: Agents authenticate with scoped ACL tokens
3. **TLS**: Optional but recommended for agent-to-server communication
4. **API Access**: Restricted to localhost only (no remote API access)

### Testing Connectivity

After firewall configuration, test connectivity:

```bash
# Test gossip port from Vault VM to Consul server
nc -zv 192.168.11.11 8301

# Test RPC port to Consul servers
nc -zv 192.168.11.11 8300
nc -zv 192.168.11.12 8300
nc -zv 192.168.11.13 8300

# Test local DNS (after agent installation)
dig @localhost -p 8600 consul.service.consul
```

## Implementation Notes

- Ports 8301 and 8300 are the minimum required for basic functionality
- Port 8600 enables DNS-based service discovery
- Port 8500 provides local API access for Vault service registration
- Port 8502 only needed if implementing service mesh features
