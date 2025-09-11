# DNS & IPAM Infrastructure Audit Summary

Generated: 2025-08-22 21:03

## Executive Summary

The DNS and IPAM audit of the Nomad infrastructure reveals a basic DNS setup using external resolvers with Consul DNS available on port 8600. No dedicated DNS servers (BIND, PowerDNS, Pi-hole) are running, indicating the infrastructure is ready for DNS service deployment.

## Key Findings

### DNS Configuration

**Current State:**

- **DNS Resolvers**: All nodes use external public DNS (Google: 8.8.8.8, 8.8.4.4 and Cloudflare: 1.1.1.1, 1.0.0.1)
- **Search Domain**: `tailfb3ea.ts.net` (Tailscale network)
- **Local DNS Services**: None (no BIND, dnsmasq, PowerDNS, Pi-hole, or unbound)
- **Consul DNS**: Available on port 8600 on all nodes
- **systemd-resolved**: Not running (disabled to prevent DNS loops with Consul)

### Network Configuration

**Network Segments:**

- **192.168.10.0/24**: Primary 2.5G network (all nodes have eth0 on this network)
- **192.168.11.0/24**: Secondary 10G network (all nodes have eth1 on this network)
- **172.17.0.0/16**: Docker network (docker0 interface)
- **100.x.x.x/32**: Tailscale VPN network (tailscale0 interface)
- **10.0.3.0/24**: LXC bridge network (only on client nodes)

**Node IP Assignments:**

| Node | 2.5G Network (eth0) | 10G Network (eth1) | Tailscale |
|------|-------------------|------------------|-----------|
| nomad-server-1 | 192.168.10.11 | 192.168.11.11 | 100.108.219.48 |
| nomad-server-2 | 192.168.10.12 | 192.168.11.12 | 100.112.25.28 |
| nomad-server-3 | 192.168.10.13 | 192.168.11.13 | 100.73.191.53 |
| nomad-client-1 | 192.168.10.20 | 192.168.11.20 | 100.89.113.45 |
| nomad-client-2 | 192.168.10.21 | 192.168.11.21 | 100.122.184.49 |
| nomad-client-3 | 192.168.10.22 | 192.168.11.22 | 100.118.136.20 |

### IPAM Status

**IP Allocation:**

- Default Gateway: 192.168.10.1
- ARP table entries: ~16 per node
- No DHCP servers detected
- Static IP configuration on all nodes
- Custom hosts file entries: 5 per node (standard localhost entries)

### Service Availability

**DNS Ports Status:**

- Port 53 (Standard DNS): **Not listening** on any node
- Port 8600 (Consul DNS): **Active** on all nodes
- Port 5353 (mDNS): **Not listening** on any node

## Recommendations

### Immediate Actions

1. **Deploy PowerDNS**: No DNS server is currently running. PowerDNS should be deployed as planned.
2. **Configure DNS forwarding**: Set up PowerDNS to forward Consul queries to port 8600.
3. **Update resolv.conf**: Point nodes to local PowerDNS once deployed instead of external DNS.

### Network Optimization

1. **Utilize 10G network**: Consider moving critical services to the 192.168.11.x network for better performance.
2. **DNS redundancy**: Deploy PowerDNS on multiple nodes for high availability.
3. **IPAM integration**: Implement NetBox for centralized IP address management.

### Security Considerations

1. **Internal DNS**: Moving from external DNS to internal will improve security and reduce latency.
2. **DNS filtering**: Consider implementing DNS filtering/blocking once PowerDNS is deployed.
3. **DNSSEC**: Plan for DNSSEC implementation in PowerDNS.

## Current Infrastructure Readiness

✅ **Ready for DNS deployment:**

- Consul DNS is operational
- No conflicting DNS services
- Network segmentation in place
- All nodes accessible via multiple networks

⚠️ **Areas needing attention:**

- No FQDN resolution (hostnames not in DNS)
- Reliance on external DNS servers
- No centralized IPAM
- No DNS redundancy

## Next Steps

1. Deploy PowerDNS via Nomad as per implementation plan
2. Configure PowerDNS zones for local networks
3. Integrate with Consul for service discovery
4. Implement NetBox for IPAM
5. Update all nodes to use local DNS servers
6. Document DNS architecture and zone structure
