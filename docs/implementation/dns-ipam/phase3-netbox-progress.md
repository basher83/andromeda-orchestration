# Phase 3: NetBox Integration - Progress Report

## Status: ✅ COMPLETED

Date: 2025-08-07

## Summary

Successfully integrated NetBox as the IPAM solution for the homelab infrastructure. All physical and virtual infrastructure has been documented in NetBox, providing a centralized source of truth for network and device management.

## Completed Tasks

### 1. Initial Setup ✅

- Created homelab sites (OG Homelab, Doggos Homelab)
- Configured IP prefixes for all networks
- Set up device roles and types
- Created manufacturers and device types

### 2. Physical Infrastructure ✅

- Added 3 Proxmox hosts (lloyd, holly, mable)
- Configured network interfaces for each host
- Assigned IP addresses on 10G network (192.168.11.x)

### 3. Virtual Infrastructure ✅

- Created Proxmox cluster configuration
- Added 6 Nomad VMs (3 servers, 3 clients)
- Configured dual network interfaces per VM
- Assigned IPs on both management (192.168.10.x) and data (192.168.11.x) networks

## NetBox Current State

```text
=== NetBox Current Configuration ===
Sites: 3
Device Roles: 6
Devices: 8
Virtual Machines: 6
IP Prefixes: 4
IP Addresses: 29
VLANs: 0
```

### Sites

- **OG Homelab** (og-homelab): Original homelab Proxmox cluster
- **Doggos Homelab** (doggos-homelab): 3-node Proxmox cluster with Nomad
- **Slurp'it** (slurpit): Unifi network devices (auto-imported)

### Network Prefixes

- `192.168.1.0/24` - Unifi network (from slurpit)
- `192.168.10.0/24` - 2.5G Management Network (doggos-homelab)
- `192.168.11.0/24` - 10G Data Network (doggos-homelab)
- `192.168.30.0/24` - Management Network (og-homelab)

### Physical Devices

- lloyd (Proxmox host) - 192.168.11.11
- holly (Proxmox host) - 192.168.11.12
- mable (Proxmox host) - 192.168.11.13
- Plus 5 Unifi devices from slurpit

### Virtual Machines

- nomad-server-1-lloyd (192.168.10.11)
- nomad-server-2-holly (192.168.10.12)
- nomad-server-3-mable (192.168.10.13)
- nomad-client-1-lloyd (192.168.10.20)
- nomad-client-2-holly (192.168.10.21)
- nomad-client-3-mable (192.168.10.22)

## Playbooks Created

### netbox-setup.yml

Initial NetBox configuration with sites, prefixes, roles, and device types.

### netbox-populate-infrastructure.yml

Populates NetBox with physical hosts, interfaces, and IP assignments.

### netbox-create-vms.yml

Creates virtual machines with proper cluster configuration and network assignments.

### netbox-discover.yml

Discovery playbook to verify NetBox configuration and contents.

## Technical Achievements

1. **Python Dependencies**: Added required packages (pynetbox, packaging, pytz) to pyproject.toml
2. **Ansible Integration**: Successfully integrated netbox.netbox collection
3. **Secrets Management**: Utilized Infisical for NetBox API credentials
4. **Dynamic Inventory Ready**: Infrastructure now ready for NetBox dynamic inventory

## Next Steps for Phase 4

1. **PowerDNS Integration**

   - Configure PowerDNS to use NetBox as backend
   - Set up zone transfers and updates
   - Implement DNS record automation

2. **Dynamic Inventory**

   - Configure NetBox dynamic inventory plugin
   - Test inventory generation
   - Update playbooks to use NetBox as source of truth

3. **Service Registration**
   - Register services in NetBox
   - Configure service dependencies
   - Implement health checks

## Lessons Learned

1. **Parameter Names**: NetBox modules use specific parameter names:

   - `device_role` not `role` for devices
   - `virtual_machine_role` not `role` for VMs
   - `cluster_type` not `type` for clusters

2. **IP Management**: IPs must be created before assignment to interfaces

3. **Interface Creation**: Interfaces must exist before IP assignment

4. **Connection Issues**: Use `connection: local` and `ANSIBLE_BECOME=false` for localhost tasks

## Files Modified

- `/playbooks/infrastructure/netbox-setup.yml`
- `/playbooks/infrastructure/netbox-populate-infrastructure.yml`
- `/playbooks/infrastructure/netbox-create-vms.yml`
- `/playbooks/infrastructure/netbox-discover.yml`
- `/playbooks/infrastructure/netbox-test-connection.yml`
- `/pyproject.toml` (added NetBox dependencies)

## Access Information

- **NetBox URL**: [https://netbox.example.internal](https://netbox.example.internal) <!-- real value stored in Infisical -->
- **API Token**: Stored in Infisical at `/apollo-13/services/netbox`
- **Username**: Retrieved from Infisical

## Conclusion

Phase 3 of the DNS-IPAM overhaul is complete. NetBox is fully operational with all infrastructure documented and ready to serve as the source of truth for the homelab environment. The foundation is now in place for Phase 4 (PowerDNS integration) and Phase 5 (production rollout).
