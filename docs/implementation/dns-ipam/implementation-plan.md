# DNS & IPAM Implementation Plan

This document outlines the comprehensive plan for transitioning from ad-hoc DNS management to a robust, service-aware
infrastructure using Consul, PowerDNS, NetBox, and Nomad.

## Current Status (August 2025)

| Phase       | Status         | Description                                                                  | Timeline    |
| ----------- | -------------- | ---------------------------------------------------------------------------- | ----------- |
| **Phase 0** | ✅ Complete    | Infrastructure Assessment                                                    | July 2025   |
| **Phase 1** | ✅ Complete    | Consul DNS Foundation                                                        | August 2025 |
| **Phase 2** | ✅ Complete    | PowerDNS Deployment (Mode A, PostgreSQL backend + Vault dynamic credentials) | August 2025 |
| **Phase 3** | 🚀 Accelerated | NetBox Integration (NetBox deployed!)                                        | In Progress |
| **Phase 4** | ⏳ Planned     | Phase Out Pi-hole                                                            | Next        |
| **Phase 5** | ⏳ Future      | Scale, Harden & Automate                                                     | Future      |

**🎉 Major Milestone**: NetBox is already deployed at `https://192.168.30.213/` (LXC 213 on pve1)

## Overview

This implementation follows a phased approach designed to:

- Minimize disruption to existing services
- Provide rollback capabilities at each stage
- Build upon existing infrastructure (Consul, Nomad)
- Create a scalable, maintainable DNS/IPAM solution

## Current State

### Known Infrastructure

- **Proxmox Clusters**:
  - og-homelab (2 nodes: proxmoxt430, pve1)
  - doggos-homelab (3 nodes: lloyd, holly, mable)
- **Nomad**: Running on doggos-homelab with 3 servers and 3 clients
- **Consul**: Deployed (state unknown - requires assessment)
- **Current DNS**: Pi-hole + Unbound (authoritative for local domains)
- **IPAM**: Ad-hoc management, no central source of truth

### Assumptions Requiring Validation

- Consul cluster health and configuration
- Network connectivity between clusters
- Current DNS zone structure
- IP allocation patterns

## Implementation Phases

### Phase 0: Infrastructure Assessment ✅ COMPLETE

**Duration**: 1-2 weeks (Completed July 2025)
**Risk Level**: None (read-only operations)
**Status**: ✅ Complete

#### 0.1 Consul Cluster Health Check

- [x] Create `playbooks/assessment/consul-health-check.yml`
  - [x] Check Consul cluster members and leadership
  - [x] Verify Consul DNS configuration (port 8600)
  - [x] Test service discovery functionality
  - [x] Document ACL and encryption status
  - [x] Check Consul-Nomad integration

#### 0.2 Current DNS/IPAM Audit

- [x] Create `playbooks/assessment/dns-ipam-audit.yml`
  - [x] Inventory all DNS servers and their roles
  - [x] Document existing DNS zones and records
  - [x] Map current IP allocations by subnet
  - [x] Identify DHCP servers and configurations
  - [x] Trace DNS resolution paths

#### 0.3 Infrastructure Readiness

- [x] Create `playbooks/assessment/infrastructure-readiness.yml`
  - [x] Verify network connectivity between all nodes
  - [x] Check firewall rules and required ports
  - [x] Assess storage capabilities for stateful services
  - [x] Document resource availability (CPU, RAM, storage)
  - [x] Test Nomad job placement constraints

#### Phase 0 Deliverables

- [x] Infrastructure assessment report
- [x] Gap analysis document
- [x] Risk assessment matrix

---

### Phase 1: Consul Foundation ✅ COMPLETE

**Duration**: 2-3 weeks (Completed August 2025)
**Risk Level**: Low
**Dependencies**: Phase 0 completion
**Status**: ✅ Complete

#### 1.1 Consul DNS Configuration

- [x] Create `playbooks/consul/configure-dns.yml`

  - [x] Configure Consul DNS on all nodes
  - [x] Set up systemd-resolved forwarding
  - [x] Implement `.consul` domain resolution
  - [x] Configure upstream DNS servers

- [x] Create `playbooks/consul/dns-validation.yml`
  - [x] Test DNS resolution for Consul services
  - [x] Verify cross-cluster DNS functionality
  - [x] Performance benchmarking

#### 1.2 Service Registration Framework

- [x] Create `roles/consul_service/` (implemented as consul_dns role)

  - [x] Develop reusable Ansible role for service registration
  - [x] Support for health checks and metadata
  - [x] Templates for common service patterns

- [x] Create `playbooks/consul/register-infrastructure.yml`
  - [x] Register all Proxmox nodes
  - [x] Register Nomad servers and clients
  - [x] Register existing infrastructure services

#### 1.3 Backup and Recovery

- [x] Consul ACL system configured with tokens
- [x] Service discovery operational
- [x] Recovery procedures documented

#### Phase 1 Deliverables

- [x] Consul DNS fully operational
- [x] All infrastructure services registered
- [x] ACL system configured and secured

---

### Phase 2: PowerDNS Deployment ✅ COMPLETE

**Duration**: 2-3 weeks (Completed August 2025)
**Risk Level**: Low-Medium
**Dependencies**: Phase 1 completion
**Status**: ✅ Complete

#### 2.1 Pre-deployment Planning

- [x] Create `nomad-jobs/platform-services/powerdns.nomad.hcl`

  - [x] Multi-task job specification (MariaDB + PowerDNS)
  - [x] MariaDB backend configuration
  - [x] Persistent volume setup
  - [x] Resource constraints and affinities

- [x] Create PowerDNS preparation playbooks
  - [x] Create necessary Consul KV configurations
  - [x] Set up persistent volumes on Nomad clients
  - [x] Configure network policies

#### 2.2 Deployment and Configuration

- [x] Deploy PowerDNS via Nomad

  - [x] Deploy PowerDNS via Nomad job
  - [x] Initialize database schema
  - [x] Configure API access (port 23601)
  - [x] Set up initial zones

- [x] PowerDNS Configuration
  - [x] Create forward zones
  - [x] Configure API authentication
  - [x] Set up Traefik integration for API access

#### 2.3 Integration Testing

- [x] PowerDNS Testing
  - [x] DNS query testing (port 53)
  - [x] API functionality verification
  - [x] Traefik routing confirmed
  - [x] Health checks passing

#### Phase Deliverables

- [x] PowerDNS running in Nomad on nomad-client-1
- [x] API fully functional at port 23601
- [x] Initial zones configured
- [x] Test results documented

---

### Phase 3: NetBox Integration 🚀 ACCELERATED

**Duration**: 3-4 weeks (In Progress - August 2025)
**Risk Level**: Medium
**Dependencies**: Phase 2 completion
**Status**: 🚀 Accelerated - NetBox already deployed!

#### 3.1 NetBox Deployment

- [x] 🎉 **NetBox ALREADY DEPLOYED** (LXC 213 on pve1)

  - [x] NetBox application running
  - [x] PostgreSQL database operational
  - [x] Redis cache configured
  - [x] Accessible at `https://192.168.30.213/`

- [ ] Configure NetBox
  - [ ] Set up authentication and API tokens
  - [ ] Configure IPAM and DCIM modules
  - [ ] Create initial data model
  - [ ] Set up backup procedures

#### 3.2 Data Migration

- [ ] Create `scripts/dns-ipam-export.py`

  - Export current DNS records
  - Export IP allocations
  - Generate NetBox-compatible format

- [ ] Create `playbooks/netbox/import-data.yml`
  - Import IP prefixes and VLANs
  - Import device records
  - Import DNS records
  - Validate imported data

#### 3.3 PowerDNS Synchronization

- [ ] Create `scripts/netbox-powerdns-sync.py`

  - NetBox webhook receiver
  - PowerDNS API integration
  - Change validation logic
  - Rollback capabilities

- [ ] Create `playbooks/netbox/configure-sync.yml`
  - Deploy sync service
  - Configure webhooks
  - Set up monitoring
  - Test synchronization

#### Phase Deliverables

- NetBox fully operational
- All IPAM data migrated
- PowerDNS sync functional
- Documentation complete

---

### Phase 4: Phase Out Pi-hole as Authoritative

**Duration**: 2-3 weeks
**Risk Level**: High
**Dependencies**: Phase 3 completion
**Status**: ⏳ Planned

#### 4.1 Preparation

- [ ] Create `playbooks/cutover/prepare.yml`
  - Lower DNS TTLs
  - Create rollback plan
  - Notify stakeholders
  - Schedule maintenance windows

#### 4.2 Gradual Migration

- [ ] Create `playbooks/cutover/migrate-dns.yml`

  - Configure Pi-hole forwarding
  - Update DHCP DNS servers
  - Monitor query patterns
  - Validate resolutions

- [ ] Create `playbooks/cutover/validate.yml`
  - Test all critical services
  - Check DNS resolution paths
  - Verify performance metrics
  - Document issues

#### 4.3 Cleanup

- [ ] Create `playbooks/cutover/cleanup.yml`
  - Decommission old DNS entries
  - Update documentation
  - Remove temporary configurations
  - Archive old data

#### Phase Deliverables

- PowerDNS as primary resolver
- Pi-hole in upstream-only mode
- All services validated
- Rollback plan tested

---

### Phase 5: Scale, Harden & Automate

**Duration**: 3-4 weeks
**Risk Level**: Low
**Dependencies**: Phase 4 completion
**Status**: ⏳ Future

#### 5.1 High Availability

- [ ] Create `playbooks/ha/configure-clustering.yml`
  - PowerDNS clustering setup
  - Database replication
  - Load balancer configuration
  - Failover testing

#### 5.2 Security Hardening

- [ ] Create `playbooks/security/harden-dns.yml`

  - Implement DNSSEC
  - Configure API authentication
  - Set up query ACLs
  - Enable audit logging

- [ ] Create `playbooks/security/tls-management.yml`
  - Deploy cert-manager in Nomad
  - Configure Let's Encrypt
  - Automate certificate renewal
  - Distribute certificates

#### 5.3 Monitoring and Observability

- [ ] Create `nomad-jobs/monitoring/dns-monitoring.nomad.hcl`

  - Prometheus exporters
  - Grafana dashboards
  - Alert rules
  - SLA tracking

- [ ] Create `playbooks/monitoring/deploy-stack.yml`
  - Deploy monitoring components
  - Configure data retention
  - Set up alerting
  - Create runbooks

#### Phase Deliverables

- HA DNS infrastructure
- Security controls implemented
- Comprehensive monitoring
- Operational runbooks

---

## Success Criteria

### Phase 0

- Complete infrastructure inventory
- All gaps identified and documented
- Risk assessment completed

### Phase 1

- 100% of infrastructure services in Consul
- DNS queries for .consul domain working
- Backup/restore tested successfully

### Phase 2

- PowerDNS handling test queries
- API responding correctly
- Performance meeting baselines

### Phase 3

- All IPAM data in NetBox
- Sync creating DNS records automatically
- No data loss during migration

### Phase 4

- All services resolving via PowerDNS
- No increase in resolution failures
- Rollback plan validated

### Phase 5

- 99.99% DNS availability
- All security controls active
- Monitoring catching issues proactively

## Risk Mitigation

### Technical Risks

1. **Data Loss**: Comprehensive backups at each phase
2. **Service Disruption**: Gradual migration with rollback plans
3. **Performance Degradation**: Benchmark and monitor continuously
4. **Security Vulnerabilities**: Security assessment at each phase

### Operational Risks

1. **Knowledge Gaps**: Document everything, create runbooks
2. **Dependency Failures**: Test all integrations thoroughly
3. **Resource Constraints**: Monitor and scale proactively

## Project Structure

```text
playbooks/
├── assessment/
│   ├── consul-health-check.yml
│   ├── dns-ipam-audit.yml
│   └── infrastructure-readiness.yml
├── consul/
│   ├── configure-dns.yml
│   ├── dns-validation.yml
│   ├── register-infrastructure.yml
│   └── backup.yml
├── powerdns/
│   ├── prepare-deployment.yml
│   ├── deploy.yml
│   ├── configure-zones.yml
│   └── test-deployment.yml
├── netbox/
│   ├── deploy.yml
│   ├── import-data.yml
│   └── configure-sync.yml
├── cutover/
│   ├── prepare.yml
│   ├── migrate-dns.yml
│   ├── validate.yml
│   └── cleanup.yml
├── ha/
│   └── configure-clustering.yml
├── security/
│   ├── harden-dns.yml
│   └── tls-management.yml
└── monitoring/
    └── deploy-stack.yml

nomad-jobs/
├── powerdns/
│   └── powerdns.nomad.hcl
├── netbox/
│   └── netbox.nomad.hcl
└── monitoring/
    └── dns-monitoring.nomad.hcl

scripts/
├── dns-ipam-export.py
└── netbox-powerdns-sync.py

roles/
└── consul_service/
    ├── tasks/main.yml
    ├── templates/
    └── defaults/main.yml
```

## Progress Tracking

Each phase has detailed checklists above. Additionally:

1. **Weekly Status Reports**: Document progress, blockers, decisions
2. **Testing Results**: Keep test logs and performance metrics
3. **Change Log**: Track all modifications to production
4. **Lessons Learned**: Document what worked and what didn't

## Next Steps

1. Review and approve this plan
2. Create project tracking in GitHub Issues/Projects
3. Begin Phase 0 assessment playbooks
4. Schedule regular review meetings

## Related Documentation

- [Project Task List](project-task-list.md) - Complete task tracking for all implementation phases
- [NetBox Integration Patterns](netbox.md) - Detailed NetBox automation guidance
- [Infisical Setup and Migration](infisical-setup-and-migration.md) - Secret management configuration
- [Infrastructure Assessment Reports](../reports/assessment/) - Phase 0 assessment results
- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions

---

_Last Updated: [Current Date]_
_Version: 1.0_
