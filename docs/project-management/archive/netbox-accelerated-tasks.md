# NetBox Accelerated Tasks - August 5, 2025

## Tasks Now Possible with NetBox Deployment

Since NetBox is already deployed at <https://192.168.30.213/>, we can immediately begin the following integration tasks:

### Immediate Actions (This Week)

#### 1. NetBox Initial Configuration

- [ ] Access NetBox admin interface
- [ ] Create initial users and API tokens
- [ ] Configure basic settings (site name, timezone, etc.)
- [ ] Set up authentication methods

#### 2. Data Model Setup

- [ ] Create sites (og-homelab, doggos-homelab)
- [ ] Define device roles (server, client, network)
- [ ] Create device types for Proxmox nodes
- [ ] Set up manufacturers (Proxmox, Docker, etc.)

#### 3. Network Documentation

- [ ] Create IP prefixes for each network segment
  - 192.168.11.0/24 (Proxmox/infrastructure)
  - 192.168.30.0/24 (Services network)
  - 192.168.1.0/24 (Main LAN)
- [ ] Define VLANs if applicable
- [ ] Document network topology

#### 4. Ansible Integration Setup

- [ ] Install netbox.netbox collection
- [ ] Configure NetBox dynamic inventory
- [ ] Test inventory plugin connectivity
- [ ] Create example playbooks using NetBox data

### Next Sprint Actions

#### 5. PowerDNS-NetBox Integration

- [ ] Install NetBox DNS plugin
- [ ] Configure PowerDNS API connection
- [ ] Create DNS zones in NetBox
- [ ] Test record synchronization

#### 6. Device Import

- [ ] Import all Proxmox nodes
- [ ] Import LXC containers with proper relationships
- [ ] Document service-to-host mappings
- [ ] Add management IP addresses

#### 7. Service Registry

- [ ] Document all running services in NetBox
- [ ] Create service templates
- [ ] Link services to devices/VMs
- [ ] Add service dependencies

### Integration Benefits Now Available

1. **Dynamic Inventory**: Replace static Proxmox inventory with NetBox-driven inventory
2. **IPAM**: Centralized IP address management instead of scattered documentation
3. **DNS Management**: PowerDNS can pull records directly from NetBox
4. **Service Discovery**: Consul can be enriched with NetBox data
5. **Automation**: Ansible can query NetBox for device details during playbook runs

### Technical Details for Implementation

```yaml
# Example NetBox inventory configuration
# inventory/netbox.yml
---
plugin: netbox.netbox.nb_inventory
api_endpoint: https://192.168.30.213
validate_certs: false
group_by:
  - device_roles
  - sites
  - platforms
  - cluster
device_query_filters:
  - has_primary_ip: true

# Example usage in playbook
- name: Query NetBox for device information
  set_fact:
    device_info: "{{ query('netbox.netbox.nb_lookup', 'devices',
                          api_filter='name=' + inventory_hostname,
                          api_endpoint='https://192.168.30.213',
                          validate_certs=False) }}"
```

### Migration Strategy

1. **Parallel Operation**: Keep existing Proxmox inventory while building NetBox
2. **Gradual Transition**: Move one cluster at a time to NetBox inventory
3. **Validation**: Ensure NetBox inventory matches Proxmox before cutover
4. **Documentation**: Update all playbooks to use NetBox as source of truth

This accelerated timeline means we can potentially complete Phase 3 by the end of August instead of September!
