# NetBox-Ansible Project Task List

This document tracks all project management tasks for the NetBox-focused Ansible automation project, organized by priority and implementation phase.

## Project Status Overview

**Project Phase**: Post-Assessment Phase  
**Current Focus**: Addressing critical blockers before Phase 1  
**Last Updated**: 2025-07-28  
**Status**: Assessment completed, critical issues identified

### Key Objectives

- Transition from ad-hoc DNS management to service-aware infrastructure
- Implement NetBox as the central source of truth
- Deploy Consul, PowerDNS, and modern IPAM practices
- Ensure zero-downtime migration from existing infrastructure

## Task Organization by Priority

### High Priority - Immediate Action Required

These tasks must be completed before any implementation work begins.

#### 1. Complete Infrastructure Assessment (Phase 0)

**Description**: Run all assessment playbooks to understand current state  
**Status**: ✅ Completed (2025-07-27)  
**Blockers**: None  
**Related**: `dns-ipam-implementation-plan.md` - Phase 0

Tasks:

- [x] Execute `consul-health-check.yml` playbook
- [x] Execute `dns-ipam-audit.yml` playbook
- [x] Execute `infrastructure-readiness.yml` playbook
- [x] Document all findings in assessment reports

**Key Findings**:
- Consul: Healthy 6-node cluster but no Nomad integration
- DNS: Pi-hole HA cluster with keepalived VIP at 192.168.30.100
  - LXC 103 (192.168.30.103) on proxmoxt430
  - LXC 136 (192.168.30.136) on pve1  
  - LXC 139 (192.168.30.139) on pve1
  - All accessible via SSH and will be in og-homelab dynamic inventory
- Networks: 192.168.10.x (2.5G), 192.168.11.x (10G), 192.168.30.x
- Critical Gap: No service discovery configured

#### 2. Fix Proxmox Inventory Configuration ✅

**Description**: Proxmox inventory not extracting IP addresses, causing connection failures  
**Status**: Completed (2025-07-28)  
**Blockers**: None - Resolved with host_vars static IP mapping  
**Related**: Inventory configuration files, host_vars directories

Tasks:

- [x] Debug why ansible_host is not being populated with IP addresses
- [x] Update inventory configuration to extract IPs from Proxmox API
- [x] Create static IP mapping as temporary workaround
- [x] Test connectivity with fixed inventory
- [x] Deploy ansible user with SSH keys across all hosts

#### 3. Finalize Infisical Migration ✅

**Description**: Complete transition from 1Password to Infisical for secrets management  
**Status**: Phase 3 Completed (2025-07-28)  
**Blockers**: None - All playbooks migrated  
**Related**: `infisical-setup-and-migration.md`

Tasks:

- [x] Implement organized folder structure in Infisical
- [x] Update all inventory files to use organized paths
- [x] Add API_URL lookups for each cluster
- [x] Add shared credential lookups (USERNAME, TOKEN_ID)
- [x] Update playbooks to use new paths (Consul, Nomad, Infrastructure)
- [x] Migrate all secrets from 1Password lookups to Infisical
- [ ] Implement environment-aware lookups (Phase 4 - future)
- [ ] Archive 1Password configuration files

#### 4. Document Current Network State

**Description**: Create comprehensive documentation of existing infrastructure  
**Status**: Partially Complete  
**Blockers**: None - Pi-hole HA cluster identified  
**Related**: Assessment playbook outputs

Tasks:

- [x] Identify Pi-hole deployment type (Docker/LXC/VM) and which host it runs on
  - FOUND: 3x LXC containers in HA configuration with keepalived
  - LXC 103 on proxmoxt430, LXC 136 & 139 on pve1
- [ ] Document all DNS zones and records from Pi-hole
- [x] Map current IP allocations (found 3 networks)
- [ ] Identify all DHCP scopes
- [ ] Create network topology diagrams

#### 5. Establish Backup Procedures

**Description**: Implement backup strategy for critical configurations  
**Status**: Not Started  
**Blockers**: None - Pi-hole cluster identified  
**Related**: Risk mitigation strategy

Tasks:

- [ ] Backup Pi-hole configurations from all 3 LXC containers
- [ ] Document keepalived configuration for VIP failover
- [ ] Backup Unbound configurations  
- [ ] Backup DHCP reservations
- [ ] Create restoration procedures including HA setup
- [ ] Test restoration in development environment

### Medium Priority - Phase 0-1 Preparation

These tasks support the implementation but aren't immediate blockers.

#### 5. Create Development Environment

**Description**: Set up isolated testing environment for DNS/IPAM changes  
**Status**: Not Started  
**Blockers**: Infrastructure assessment needed first  
**Related**: `dns-ipam-implementation-plan.md` - Phase 1

Tasks:

- [ ] Deploy test VMs for Consul/PowerDNS
- [ ] Configure isolated network segment
- [ ] Set up test clients
- [ ] Document access procedures

#### 6. Design IP Address Schema

**Description**: Create comprehensive IP addressing plan for all networks  
**Status**: Not Started  
**Blockers**: Current state documentation required  
**Related**: NetBox IPAM configuration

Tasks:

- [ ] Define network segments
- [ ] Allocate service ranges
- [ ] Plan for growth
- [ ] Document in NetBox

#### 7. Develop Service Templates

**Description**: Create Ansible templates for service configurations  
**Status**: Not Started  
**Blockers**: None  
**Related**: Implementation phases

Tasks:

- [ ] Consul configuration templates
- [ ] PowerDNS zone templates
- [ ] NetBox custom fields
- [ ] Integration scripts

#### 8. Implement Monitoring Strategy

**Description**: Deploy monitoring for DNS/IPAM services  
**Status**: Not Started  
**Blockers**: Services must be deployed first  
**Related**: Phase 2 implementation

Tasks:

- [ ] Define key metrics
- [ ] Set up Prometheus exporters
- [ ] Create Grafana dashboards
- [ ] Configure alerts

#### 9. Create Migration Runbooks

**Description**: Detailed procedures for each migration phase  
**Status**: Not Started  
**Blockers**: Architecture decisions needed  
**Related**: All implementation phases

Tasks:

- [ ] Phase 1 deployment procedures
- [ ] Phase 2 integration steps
- [ ] Phase 3 migration checklist
- [ ] Rollback procedures

#### 10. Establish Change Management Process

**Description**: Define how changes will be tracked and approved  
**Status**: Not Started  
**Blockers**: None  
**Related**: Project governance

Tasks:

- [ ] Create change request template
- [ ] Define approval workflow
- [ ] Set up change tracking
- [ ] Document in project wiki

#### 11. Bootstrap NetBox with Essential Records

**Description**: Seed NetBox with critical DNS records to enable early PowerDNS sync  
**Status**: Not Started  
**Blockers**: NetBox deployment required  
**Related**: Phase 3 bootstrap strategy per ROADMAP.md

Tasks:

- [ ] Identify critical DNS records (proxmox hosts, core services)
- [ ] Create minimal NetBox data model
- [ ] Test PowerDNS sync with limited dataset
- [ ] Plan incremental data migration approach

### Low Priority - Future Phases

These tasks are important but can wait until implementation begins.

#### 12. Plan Multi-Site DNS Strategy

**Description**: Design DNS architecture for og-homelab integration  
**Status**: Not Started  
**Blockers**: Single site must work first  
**Related**: Phase 4 expansion

Tasks:

- [ ] Assess og-homelab requirements
- [ ] Design cross-site replication
- [ ] Plan zone delegation
- [ ] Document architecture

#### 13. Develop Automation Workflows

**Description**: Create event-driven automation for DNS/IPAM  
**Status**: Not Started  
**Blockers**: Core services required  
**Related**: Phase 5 optimization

Tasks:

- [ ] NetBox webhook configuration
- [ ] Ansible AWX/Tower integration
- [ ] Auto-provisioning workflows
- [ ] Self-service portals

#### 14. Create User Documentation

**Description**: End-user guides for new DNS/IPAM services  
**Status**: Not Started  
**Blockers**: Implementation must be complete  
**Related**: Phase 3 migration

Tasks:

- [ ] DNS query troubleshooting
- [ ] Service discovery guides
- [ ] IPAM request procedures
- [ ] FAQ documentation

#### 15. Design Disaster Recovery Plan

**Description**: Comprehensive DR strategy for DNS/IPAM  
**Status**: Not Started  
**Blockers**: Architecture must be finalized  
**Related**: Production readiness

Tasks:

- [ ] Define RTO/RPO objectives
- [ ] Create DR procedures
- [ ] Test failover scenarios
- [ ] Document recovery steps

#### 16. Implement Security Hardening

**Description**: Security improvements for all components  
**Status**: Not Started  
**Blockers**: Base implementation required  
**Related**: Production readiness, Phase 5 TLS/SSL management

Tasks:

- [ ] DNSSEC implementation for authoritative zones
- [ ] mTLS for Consul service mesh
- [ ] API authentication for PowerDNS and NetBox
- [ ] Audit logging for all services
- [ ] DNS-01 ACME challenge setup via PowerDNS API
- [ ] Let's Encrypt wildcard certificates for *.lab.example.com
- [ ] Vault PKI integration for internal service certificates
- [ ] Consul Connect mTLS for service-to-service encryption
- [ ] Nomad periodic jobs for certificate renewal
- [ ] Certificate storage strategy (host volumes, Consul KV, or Vault)

#### 17. Performance Optimization

**Description**: Tune services for optimal performance  
**Status**: Not Started  
**Blockers**: Baseline metrics needed  
**Related**: Phase 5 optimization

Tasks:

- [ ] DNS query optimization
- [ ] Consul performance tuning
- [ ] Database optimization
- [ ] Cache configuration

#### 18. Capacity Planning

**Description**: Plan for future growth and scaling  
**Status**: Not Started  
**Blockers**: Current usage patterns needed  
**Related**: Long-term planning

Tasks:

- [ ] Growth projections
- [ ] Resource requirements
- [ ] Scaling strategies
- [ ] Budget planning

#### 19. Integration Testing

**Description**: Comprehensive testing of all integrations  
**Status**: Not Started  
**Blockers**: Components must be deployed  
**Related**: Phase 2-3 validation

Tasks:

- [ ] NetBox-Consul integration
- [ ] PowerDNS-NetBox sync
- [ ] Ansible automation tests
- [ ] End-to-end scenarios

#### 20. Create Operational Dashboards

**Description**: Real-time visibility into DNS/IPAM operations  
**Status**: Not Started  
**Blockers**: Monitoring must be deployed  
**Related**: Phase 2 implementation

Tasks:

- [ ] Service health dashboards
- [ ] Query analytics
- [ ] IPAM utilization
- [ ] Trend analysis

#### 21. Develop SOP Documentation

**Description**: Standard operating procedures for common tasks  
**Status**: Not Started  
**Blockers**: Processes must be established  
**Related**: Operational readiness

Tasks:

- [ ] Daily checks
- [ ] Incident response
- [ ] Maintenance procedures
- [ ] Escalation paths

#### 22. Configure Automated Backups

**Description**: Automated backup solutions for all services  
**Status**: Not Started  
**Blockers**: Services must be deployed  
**Related**: Production readiness

Tasks:

- [ ] Backup scheduling
- [ ] Retention policies
- [ ] Off-site storage
- [ ] Recovery testing

#### 23. Implement Compliance Controls

**Description**: Ensure compliance with relevant standards  
**Status**: Not Started  
**Blockers**: Requirements gathering needed  
**Related**: Governance

Tasks:

- [ ] Identify requirements
- [ ] Implement controls
- [ ] Audit procedures
- [ ] Compliance reporting

#### 24. Plan Knowledge Transfer

**Description**: Ensure team has necessary skills  
**Status**: Not Started  
**Blockers**: Implementation experience needed  
**Related**: Operational readiness

Tasks:

- [ ] Training materials
- [ ] Hands-on workshops
- [ ] Documentation review
- [ ] Skills assessment

## Progress Tracking

### Overall Progress

- **Completed**: 1/25 tasks (4%)
- **In Progress**: 1/25 tasks (4%)
- **Not Started**: 23/25 tasks (92%)

### Phase Breakdown

- **High Priority**: 1/5 completed (Assessment done)
- **Medium Priority**: 0/7 completed
- **Low Priority**: 0/13 completed

## Risk Items and Blockers

### Critical Risks

1. **Proxmox Inventory Broken** 🚨: Cannot connect to any hosts - blocking all operations
2. **DNS Infrastructure Complexity**: Pi-hole runs as 3-node HA cluster with keepalived - migration more complex than expected
3. **No Backup Strategy**: Risk of data loss during migration
4. **Lack of Testing Environment**: Cannot validate changes safely

### Current Blockers

1. **Broken Inventory Configuration**: Proxmox not providing IP addresses
2. **Infisical Flat Structure**: Preventing organized secret management
3. **Pi-hole HA Complexity**: Must coordinate backups across 3 LXC containers and maintain keepalived VIP
4. **No Development Environment**: Cannot test configurations
5. **No Consul-Nomad Integration**: Service discovery not configured

## Recommendations for Task Execution

### Immediate Actions (Next 3-5 Days)

1. **Fix Proxmox inventory configuration** - Critical blocker
2. **Document Pi-hole HA cluster configuration** - Keepalived VIP and sync between 3 nodes
3. **Create network topology diagram** - Document 3 discovered networks
4. **Implement emergency backup procedures** for current DNS

### Week 2 Focus

1. **Complete Infisical folder reorganization**
2. **Enable Consul-Nomad integration** on doggos-homelab
3. **Design IP addressing schema** based on assessment findings
4. **Set up isolated development environment** for safe testing

### Month 2 Goals

1. **Complete Phase 0 and 1** of implementation plan
2. **Establish monitoring** for new services
3. **Begin Phase 2 integration** work
4. **Create operational documentation**

## Related Documentation

- [DNS & IPAM Implementation Plan](dns-ipam-implementation-plan.md) - Master implementation roadmap
- [NetBox Integration Patterns](netbox.md) - NetBox configuration and usage
- [Infisical Setup and Migration](infisical-setup-and-migration.md) - Secret management transition
- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
- [1Password Integration (Archived)](archive/1password-integration.md) - Legacy secret management (being replaced)

## Maintenance Notes

This document should be updated:

- Weekly during active implementation
- After each task completion
- When new tasks are identified
- When priorities change

Last review: 2025-07-28  
Next review: 2025-08-04

## Change Log

- **2025-07-28**: Updated after task-master analysis
  - Added critical Proxmox inventory blocker as Task #2
  - Updated assessment status to completed
  - Added infrastructure findings from assessment reports
  - Identified 5 critical blockers requiring immediate attention
  - Adjusted task priorities based on discovered issues
- **2025-07-28** (Update 2): Pi-hole infrastructure discovered
  - Identified Pi-hole as 3-node HA cluster with keepalived VIP
  - LXC 103 on proxmoxt430, LXC 136 & 139 on pve1
  - Updated risks to reflect migration complexity of HA setup
  - Removed blockers related to unknown Pi-hole location
