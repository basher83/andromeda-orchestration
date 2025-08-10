# Pi-hole HA Cluster Documentation

## Overview

The Pi-hole DNS infrastructure consists of a 3-node high-availability cluster using keepalived for VIP failover and Nebula Sync for configuration synchronization.

## Infrastructure Details

### Cluster Nodes

| Node | IP Address | Host | LXC ID | Role |
|------|------------|------|--------|------|
| pihole (VIP) | 192.168.30.100 | - | - | Virtual IP |
| pihole-1 | 192.168.30.103 | proxmoxt430 | 103 | Backup |
| pihole-2 | 192.168.30.136 | pve1 | 136 | Master |
| pihole-3 | 192.168.30.139 | pve1 | 139 | Backup |

### Keepalived Configuration

**Master Node (192.168.30.136)**:

```ini
vrrp_instance VI_1 {
  state MASTER
  interface eth0
  virtual_router_id 55
  priority 150
  advert_int 1
  unicast_src_ip 192.168.30.136
  unicast_peer {
    192.168.30.103
    192.168.30.139
  }
  authentication {
    auth_type PASS
    auth_pass Y5z##!TeZAv6H@4&NCkL45!*p3
  }
  virtual_ipaddress {
    192.168.30.100/24
  }
}
```

### DNS Configuration

#### Upstream DNS Servers

1. Local Unbound (primary)
1. Cloudflare (1.1.1.1)
1. Google (8.8.8.8)

#### DNS Zone

**Domain**: `lab.spaceships.work`

#### Local DNS Records

| Hostname | IP Address | Service Type |
|----------|------------|--------------|
| dockerhost | 192.168.30.20 | Infrastructure |
| dockervm | 192.168.30.248 | Infrastructure |
| gitlab | 192.168.30.137 | Development |
| holly | 192.168.10.3 | Proxmox Node |
| komodo | 192.168.30.109 | Unknown |
| lloyd | 192.168.10.2 | Proxmox Node |
| mable | 192.168.10.4 | Proxmox Node |
| mac-mini | 192.168.30.58 | Workstation |
| netbox | 192.168.30.213 | IPAM |
| nomad-client-1 | 192.168.10.20 | Orchestration |
| nomad-client-2 | 192.168.10.21 | Orchestration |
| nomad-client-3 | 192.168.10.22 | Orchestration |
| nomad-server-1 | 192.168.10.11 | Orchestration |
| nomad-server-2 | 192.168.10.12 | Orchestration |
| nomad-server-3 | 192.168.10.13 | Orchestration |
| pbs | 192.168.30.200 | Backup |
| pihole | 192.168.30.100 | DNS (VIP) |
| proxmoxt430 | 192.168.30.30 | Proxmox Node |
| pve1 | 192.168.30.50 | Proxmox Node |
| traefik | 192.168.30.113 | Load Balancer |
| trilium | 192.168.30.223 | Notes |
| zabbix | 192.168.30.101 | Monitoring |

### Network Segments

1. **192.168.10.x** - 2.5G Network (Proxmox nodes, Nomad cluster)
1. **192.168.30.x** - Primary services network
1. **192.168.11.x** - 10G Network (not shown in DNS records)

### Synchronization

**Method**: Nebula Sync Docker container

- Performs teleporter transfer from master to slave nodes
- Ensures configuration consistency across all Pi-hole instances
- Syncs blocklists, custom DNS records, and settings

## DHCP Configuration

DHCP is **NOT** handled by Pi-hole. It is managed by the UniFi Controller.

## Backup Procedures

### Manual Backup

1. **Export from Master Node (192.168.30.136)**:

   ```bash
   # SSH to master Pi-hole
   ssh ansible@192.168.30.136

   # Create teleporter backup
   pihole -a -t
   ```

2. **Backup Keepalived Configuration**:

   ```bash
   # On each node
   sudo cp /etc/keepalived/keepalived.conf ~/keepalived.conf.backup
   ```

3. **Document Nebula Sync Configuration**:

   - Container settings
   - Sync schedule
   - Target nodes

### Automated Backup (Ansible)

```yaml
- name: Backup Pi-hole configurations
  hosts: pihole_nodes
  tasks:
    - name: Create Pi-hole teleporter backup
      command: pihole -a -t
      register: backup_result

    - name: Fetch backup file
      fetch:
        src: "{{ backup_result.stdout_lines[-1] }}"
        dest: "./backups/pihole/{{ inventory_hostname }}/"
        flat: no
```

## Migration Considerations

1. **High Availability**: Must maintain VIP availability during migration
1. **Sync Mechanism**: Nebula Sync must be replaced or integrated with new solution
1. **DNS Records**: All local DNS records must be migrated to NetBox
1. **Keepalived**: Consider Consul for health checking and failover

## Integration Points

1. **Consul**: Can replace keepalived for health checking
1. **NetBox**: Will become source of truth for DNS records
1. **PowerDNS**: Will replace Pi-hole for authoritative DNS
1. **Nomad**: Can manage PowerDNS and other DNS services

## Risk Mitigation

1. **Backup all configurations** before any changes
1. **Test in development** with same HA setup
1. **Staged migration** - one node at a time
1. **Maintain Pi-hole** as fallback during transition
1. **Monitor VIP availability** throughout migration

## Next Steps

1. Set up development environment with 3-node Pi-hole cluster
1. Test PowerDNS with same local DNS records
1. Plan Consul service registration for DNS health checks
1. Design NetBox data model for existing DNS records
1. Create migration runbook with rollback procedures
