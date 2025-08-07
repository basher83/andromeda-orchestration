# Phase 4: PowerDNS-NetBox Integration

**Target Timeline**: August 7-14, 2025
**Status**: 🚧 In Progress
**Prerequisites**: Phase 3 Complete (NetBox populated)

---

Navigation: [Current Sprint](../current-sprint.md) | [Task Summary](../task-summary.md) | [Phase 3](./phase-3-netbox.md) | [Phase 5](./phase-5-optimization.md)
---

## Phase Overview

Integrate PowerDNS with NetBox to establish NetBox as the authoritative source for DNS records, enabling automatic synchronization and management.

## Current Progress

### ✅ Completed

- NetBox operational at https://192.168.30.213/
- PowerDNS deployed and running on nomad-client-1
- Infrastructure fully documented in NetBox (3 sites, 8 devices, 6 VMs, 29 IPs)
- NetBox DNS plugin v1.3.5 installation initiated

### 🚧 In Progress

- Installing NetBox DNS plugin (upgrade in progress)
- Planning DNS zone structure

### 📅 Upcoming Tasks

1. **Configure DNS Zones in NetBox**
   - Create forward zones (homelab.local, etc.)
   - Configure reverse zones for all subnets
   - Set up zone delegation if needed

2. **PowerDNS API Integration**
   - Configure PowerDNS backend to query NetBox
   - Set up API authentication
   - Test connectivity between services

3. **Synchronization Setup**
   - Create sync script for NetBox → PowerDNS
   - Configure webhooks for real-time updates
   - Implement validation and rollback logic

4. **DNS Record Migration**
   - Export existing DNS records from Pi-hole
   - Import records into NetBox
   - Verify all records transferred correctly

5. **Testing & Validation**
   - Test forward and reverse lookups
   - Verify automatic PTR record generation
   - Check sync performance and reliability
   - Validate DNSSEC if enabled

## Technical Details

### NetBox DNS Plugin Features

- **Version**: 1.3.5
- **Author**: Peter Eckel
- **Capabilities**:
  - Zone management (forward/reverse)
  - Record types: A, AAAA, CNAME, MX, TXT, SRV, PTR, NS, SOA
  - Automatic PTR generation from IP assignments
  - DNSSEC support
  - PowerDNS API integration
  - Zone transfers
  - View support for split-horizon DNS

### Integration Architecture

```
NetBox (LXC 213)
  ↓ API/Webhook
  ↓ Sync Script
PowerDNS (nomad-client-1)
  ↓ DNS Queries
Clients
```

### Configuration Files Needed

1. **NetBox DNS Configuration**
   - Plugin settings in NetBox configuration
   - DNS zone templates
   - Record templates

2. **PowerDNS Backend Configuration**
   - API backend settings
   - NetBox connection parameters
   - Cache settings

3. **Sync Script**
   - `scripts/netbox-powerdns-sync.py`
   - Webhook receiver
   - Validation logic

## Success Criteria

- [ ] NetBox DNS plugin operational
- [ ] All DNS zones configured in NetBox
- [ ] PowerDNS successfully queries NetBox for records
- [ ] Automatic sync working for record changes
- [ ] PTR records auto-generated from IP assignments
- [ ] All existing DNS records migrated
- [ ] Zero DNS resolution failures during cutover

## Risk Mitigation

1. **Backup current DNS data** before any changes
2. **Test in isolated environment** first if possible
3. **Gradual migration** - start with test zones
4. **Monitor closely** during initial sync operations
5. **Maintain Pi-hole** as fallback during transition

## Next Phase

Once Phase 4 is complete, we'll move to Phase 5 (Optimization) which includes:
- Multi-site DNS strategy
- High availability configuration
- Performance tuning
- Security hardening
- Full production cutover
