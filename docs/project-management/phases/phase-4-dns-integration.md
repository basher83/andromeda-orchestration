# Phase 4: PowerDNS-NetBox Integration

**Target Timeline**: August 12-19, 2025
**Status**: 🚧 In Progress
**Prerequisites**: Phase 3 Complete (NetBox populated)
**GitHub Epic**: [#27](https://github.com/basher83/netbox-ansible/issues/27)

> ⚠️ **CRITICAL DEPENDENCY**: Domain migration from .local to spaceships.work ([Epic #18](https://github.com/basher83/netbox-ansible/issues/18)) must be completed in parallel. See [Critical Domain Migration](../critical-domain-migration.md).

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

### Mode A Implementation Tasks (GitHub Issues)

**Epic**: [#27](https://github.com/basher83/netbox-ansible/issues/27) - Phase 4 PowerDNS-NetBox Integration Tracking

#### 1. Database provisioning (PostgreSQL) ✅ COMPLETED

- [x] Deploy Nomad job: `nomad-jobs/platform-services/postgresql.nomad.hcl`
- [x] Configure host volume for persistence
- [x] Initialize PowerDNS schema
- [x] Configure Vault Database Secrets Engine

#### 2. Infrastructure Setup (Active Sprint)

- [ ] [#28](https://github.com/basher83/netbox-ansible/issues/28): Deploy PowerDNS with PostgreSQL backend
- [ ] [#29](https://github.com/basher83/netbox-ansible/issues/29): Expose DNS :53 (TCP/UDP) and API via Traefik dynamic port
- [ ] [#30](https://github.com/basher83/netbox-ansible/issues/30): Register Consul services (powerdns-auth, powerdns-auth-api)
- [ ] [#31](https://github.com/basher83/netbox-ansible/issues/31): Configure Traefik routing and middlewares for API
- [ ] [#32](https://github.com/basher83/netbox-ansible/issues/32): Add health checks for :53 and API

#### 3. NetBox Integration

- [ ] [#38](https://github.com/basher83/netbox-ansible/issues/38): Configure forward/reverse zones in NetBox (use spaceships.work)
- [ ] [#39](https://github.com/basher83/netbox-ansible/issues/39): PowerDNS ←→ NetBox API connectivity
- [ ] [#40](https://github.com/basher83/netbox-ansible/issues/40): Implement sync script and webhooks

#### 4. Migration & Testing

- [ ] [#41](https://github.com/basher83/netbox-ansible/issues/41): Migrate DNS records from Pi-hole to NetBox
- [ ] [#42](https://github.com/basher83/netbox-ansible/issues/42): Functional testing - forward/reverse lookups
- [ ] [#43](https://github.com/basher83/netbox-ansible/issues/43): Zone transfers and automatic DNS updates

#### 5. Production Readiness

- [ ] [#33](https://github.com/basher83/netbox-ansible/issues/33): Scale to HA (count=2 on distinct hosts)
- [ ] [#34](https://github.com/basher83/netbox-ansible/issues/34): Decommission MariaDB prototype
- [ ] [#35](https://github.com/basher83/netbox-ansible/issues/35): Migrate data from prototype if needed
- [ ] [#36](https://github.com/basher83/netbox-ansible/issues/36): Verify DNS resolution and API operations
- [ ] [#37](https://github.com/basher83/netbox-ansible/issues/37): Update runbooks to Mode A PostgreSQL + Vault

#### 6. Enhancement (Optional)

- [ ] [#26](https://github.com/basher83/netbox-ansible/issues/26): Integrate PowerDNS-Admin web UI
- [ ] [#46](https://github.com/basher83/netbox-ansible/issues/46): Add milestone checklist to Phase 4 doc

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

**Note**: Detailed tasks are now tracked as GitHub issues. See [Mode A Implementation Tasks](#mode-a-implementation-tasks-github-issues) above for issue links.

### Quick Reference by Category

**Infrastructure** (Issues #28-33)

- Deploy PowerDNS, configure ports, Consul services, Traefik routing, health checks, HA

**NetBox Configuration** (Issues #38, #21)

- Create zones with spaceships.work domain (NOT .local)
- Configure forward/reverse zones with proper SOA/NS records
- Set TTLs per standard

**Integration** (Issues #39-40)

- API connectivity between PowerDNS and NetBox
- Sync script implementation
- Webhook configuration

**Migration** (Issues #41, #34-35)

- Pi-hole to NetBox record migration
- Prototype decommission
- Data migration if needed

**Testing** (Issues #42-43, #36)

- Forward/reverse lookup validation
- Zone transfer configuration
- API operations verification

**Documentation** (Issues #37, #46)

- Runbook updates for Mode A
- Phase 4 milestone checklist

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
