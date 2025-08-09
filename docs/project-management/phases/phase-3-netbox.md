# Phase 3: NetBox Integration and DNS Migration

**Target Timeline**: August 2025 (ACCELERATED)
**Status**: In Progress
**Prerequisites**: Phase 1 & 2 Complete ✅, NetBox Deployed ✅

---

## Navigation: [Current Sprint](../current-sprint.md) | [Task Summary](../task-summary.md) | [Next Phase](./phase-4-dns-integration.md)

## Phase Overview

Integrate NetBox as the source of truth for DNS and IPAM, migrating existing DNS records from Pi-hole to PowerDNS with NetBox as the authoritative data source.

**🎉 CRITICAL UPDATE**: NetBox is already deployed!

- **Location**: LXC 213 on pve1
- **URL**: <https://192.168.30.213/>
- **Impact**: We can immediately begin integration tasks!

## High Priority Tasks

### 20. Bootstrap NetBox with Essential Records

**Description**: Seed NetBox with critical DNS records to enable early PowerDNS sync
**Status**: In Progress
**Blockers**: None - NetBox is deployed!
**Related**: Phase 3 bootstrap strategy per ROADMAP.md

Tasks:

- [✅] Deploy NetBox to infrastructure (Complete - LXC 213 on pve1)
- [✅] Access NetBox at <https://192.168.30.213/>
- [✅] Configure NetBox IPAM and DCIM modules
- [✅] Identify critical DNS records (proxmox hosts, core services)
- [✅] Create minimal NetBox data model
- [✅] Import essential records manually
- [] Test PowerDNS sync with limited dataset
- [ ] Plan incremental data migration approach

### DNS Record Migration

**Description**: Migrate all DNS records from Pi-hole to NetBox/PowerDNS
**Status**: Ready to Start
**Blockers**: None - NetBox is operational!

Tasks:

- [ ] Export all DNS records from Pi-hole
- [ ] Create import scripts for NetBox
- [ ] Validate record integrity
- [ ] Implement staged migration plan
- [ ] Test DNS resolution at each stage
- [ ] Create rollback procedures

### PowerDNS-NetBox Integration

**Description**: Configure automatic sync between NetBox and PowerDNS
**Status**: Ready to Start
**Blockers**: None - Both services are operational!

Tasks:

- [✅] Install NetBox DNS plugin
- [ ] Configure PowerDNS API integration
- [ ] Set up sync schedules
- [ ] Test record propagation
- [ ] Monitor sync performance
- [ ] Document troubleshooting procedures

## Medium Priority Tasks

### 17. Design IP Address Schema

**Description**: Create comprehensive IP addressing plan for all networks
**Status**: Ready to Start
**Blockers**: None - Can be implemented directly in NetBox!

Tasks:

- [✅] Define network segments
- [✅] Allocate service ranges
- [✅] Reserve growth capacity
- [✅] Document in NetBox IPAM
- [] Create visual network diagrams
- [ ] Define naming conventions

### 22. Integration Testing

**Description**: Comprehensive testing of all integrations
**Status**: Ready to Start
**Blockers**: None - Core components are deployed!

Tasks:

- [ ] NetBox-Consul service registration tests
- [ ] PowerDNS-NetBox sync validation
- [ ] Ansible automation tests
- [ ] End-to-end DNS query tests
- [ ] Performance benchmarking
- [ ] Failure scenario testing

## Success Criteria

- [ ] NetBox operational with core data model
- [ ] All DNS records migrated from Pi-hole
- [ ] PowerDNS serving all queries from NetBox data
- [ ] Zero DNS resolution failures during migration
- [ ] Automated sync working reliably
- [ ] Complete documentation for operations

## Risk Mitigation

1. **Data Loss During Migration**

   - Export full Pi-hole backup before starting
   - Implement staged migration with validation
   - Maintain Pi-hole as fallback during transition

2. **Service Disruption**

   - Use weighted DNS during transition
   - Implement health checks at each stage
   - Document immediate rollback procedures

3. **Integration Complexity**
   - Start with minimal dataset
   - Test thoroughly in dev environment
   - Have manual override procedures ready
