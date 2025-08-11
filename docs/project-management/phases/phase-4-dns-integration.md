# Phase 4: PowerDNS-NetBox Integration

**Target Timeline**: August 7-14, 2025
**Status**: 🚧 In Progress
**Prerequisites**: Phase 3 Complete (NetBox populated)

---

## Navigation: [Current Sprint](../current-sprint.md) | [Task Summary](../task-summary.md) | [Prev Phase](./phase-3-netbox.md) | [Next Phase](./phase-5-multisite.md)

## Phase Overview

Integrate PowerDNS with NetBox to establish NetBox as the authoritative source for DNS records, enabling automatic synchronization and management.

## Implementation Plan Update (2025-08-09)

We are pivoting the PowerDNS implementation to the production-ready architecture described in the PowerDNS implementation docs. This supersedes the earlier MariaDB prototype.

- New baseline: PowerDNS Authoritative (Mode A) with external PostgreSQL backend
- Secrets: Vault; configuration: Consul KV
- API: Dynamic port via Traefik; DNS: static port 53
- High availability: count ≥ 2, distinct hosts, health checks on :53

References:

- PowerDNS Overview: [docs/implementation/powerdns/README.md](../../implementation/powerdns/README.md)
- Deployment Architecture: [docs/implementation/powerdns/deployment-architecture.md](../../implementation/powerdns/deployment-architecture.md)

### Mode A Implementation Tasks

1. Database provisioning (PostgreSQL)

   - [x] Deploy Nomad job: `nomad-jobs/platform-services/postgresql.nomad.hcl`
   - [x] Configure host volume for persistence
   - [x] Initialize PowerDNS schema

2. Secrets and configuration

   - [x] Write Consul KV entries for DB host/port/name/user
   - [x] Store `db_password` and `api_key` in Vault (Infisical references as needed)

3. Deploy PowerDNS Auth (Mode A)

   - [ ] Deploy/update PowerDNS job: `nomad-jobs/platform-services/powerdns.nomad.hcl` (configure for PostgreSQL backend)
   - [ ] Expose DNS on port 53 (TCP/UDP), API via dynamic port
   - [ ] Register Consul services (`powerdns-auth`, `powerdns-auth-api`)

4. Ingress and health

   - [ ] Configure Traefik routing for API access
   - [ ] Enable health checks for :53 and API
   - [ ] Scale to count=2 with distinct hosts

5. Migration from prototype

   - [ ] Decommission MariaDB-based prototype jobs
   - [ ] Migrate any initial data (if applicable)
   - [ ] Validate no consumers depend on old endpoints

6. Validation

   - [ ] Verify DNS queries resolve from PowerDNS
   - [ ] Verify API operations and metrics
   - [ ] Document runbook updates

## Current Progress

### ✅ Completed

- NetBox operational at [https://192.168.30.213/](https://192.168.30.213/)
- PowerDNS deployed and running on nomad-client-1
- Infrastructure fully documented in NetBox (3 sites, 8 devices, 6 VMs, 29 IPs)
- NetBox DNS plugin v1.3.5 installed and operational (Aug 8)

### 🚧 In Progress

- Configuring DNS zones in NetBox
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

## Detailed Checklist

### NetBox DNS Zones

- [ ] Create primary forward zones (e.g., homelab.local)
- [ ] Create reverse zones for all managed prefixes
- [ ] Configure SOA/NS records and TTLs per standard
- [ ] Define zone delegation if applicable

### PowerDNS API Integration

- [ ] Confirm NetBox DNS plugin v1.3.5 installed and enabled
- [ ] Configure PowerDNS backend to pull from NetBox
- [ ] Set API key/credentials (store in Infisical/Vault)
- [ ] Verify PowerDNS ↔ NetBox connectivity

### Sync and Automation

- [ ] Implement NetBox → PowerDNS sync script
- [ ] Configure NetBox webhooks for record changes
- [ ] Add validation and rollback safeguards
- [ ] Enable automatic PTR record generation
- [ ] Configure zone transfers if required
- [ ] Enable automatic DNS updates where needed

### Functional Testing

- [ ] Forward lookups resolve against PowerDNS
- [ ] Reverse lookups resolve with correct PTRs
- [ ] Changes in NetBox propagate to PowerDNS
- [ ] Performance and reliability validated

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

```text
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

- [x] NetBox DNS plugin operational
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

Once Phase 4 is complete, we'll move to Phase 5 (Multi-Site Expansion and Optimization) which includes:

- Multi-site DNS strategy
- High availability configuration
- Performance tuning
- Security hardening
- Full production cutover
