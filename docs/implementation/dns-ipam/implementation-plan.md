# DNS & IPAM Implementation Plan

This document outlines the comprehensive plan for transitioning from ad-hoc DNS management to a robust, service-aware
infrastructure using Consul, PowerDNS, NetBox, and Nomad.

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

### Phase 0: Infrastructure Assessment

**Duration**: 1-2 weeks
**Risk Level**: None (read-only operations)

#### 0.1 Consul Cluster Health Check

- [x] Create `playbooks/assessment/consul-health-check.yml`
  - Check Consul cluster members and leadership
  - Verify Consul DNS configuration (port 8600)
  - Test service discovery functionality
  - Document ACL and encryption status
  - Check Consul-Nomad integration

#### 0.2 Current DNS/IPAM Audit

- [x] Create `playbooks/assessment/dns-ipam-audit.yml`
  - Inventory all DNS servers and their roles
  - Document existing DNS zones and records
  - Map current IP allocations by subnet
  - Identify DHCP servers and configurations
  - Trace DNS resolution paths

#### 0.3 Infrastructure Readiness

- [x] Create `playbooks/assessment/infrastructure-readiness.yml`
  - Verify network connectivity between all nodes
  - Check firewall rules and required ports
  - Assess storage capabilities for stateful services
  - Document resource availability (CPU, RAM, storage)
  - Test Nomad job placement constraints

#### Phase 0 Deliverables

- Infrastructure assessment report
- Gap analysis document
- Risk assessment matrix

---

### Phase 1: Consul Foundation

**Duration**: 2-3 weeks
**Risk Level**: Low
**Dependencies**: Phase 0 completion

#### 1.1 Consul DNS Configuration

- [ ] Create `playbooks/consul/configure-dns.yml`

  - Configure Consul DNS on all nodes
  - Set up systemd-resolved or dnsmasq forwarding
  - Implement `.consul` domain resolution
  - Configure upstream DNS servers

- [ ] Create `playbooks/consul/dns-validation.yml`
  - Test DNS resolution for Consul services
  - Verify cross-cluster DNS functionality
  - Performance benchmarking

#### 1.2 Service Registration Framework

- [ ] Create `roles/consul_service/`

  - Develop reusable Ansible role for service registration
  - Support for health checks and metadata
  - Templates for common service patterns

- [ ] Create `playbooks/consul/register-infrastructure.yml`
  - Register all Proxmox nodes
  - Register Nomad servers and clients
  - Register existing infrastructure services

#### 1.3 Backup and Recovery

- [ ] Create `playbooks/consul/backup.yml`
  - Automated Consul snapshot creation
  - Snapshot storage and rotation
  - Recovery testing procedures

#### Phase 1 Deliverables

- Consul DNS fully operational
- All infrastructure services registered
- Backup/restore procedures documented

---

### Phase 2: PowerDNS Deployment

**Duration**: 2-3 weeks
**Risk Level**: Low-Medium
**Dependencies**: Phase 1 completion

#### 2.1 Pre-deployment Planning

- [ ] Create `nomad-jobs/powerdns/powerdns.nomad.hcl`

  - Multi-instance job specification
  - MariaDB backend configuration
  - Persistent volume setup
  - Resource constraints and affinities

- [ ] Create `playbooks/powerdns/prepare-deployment.yml`
  - Create necessary Consul KV configurations
  - Set up persistent volumes
  - Configure network policies

#### 2.2 Deployment and Configuration

- [ ] Create `playbooks/powerdns/deploy.yml`

  - Deploy PowerDNS via Nomad
  - Initialize database schema
  - Configure API access
  - Set up initial zones

- [ ] Create `playbooks/powerdns/configure-zones.yml`
  - Create forward and reverse zones
  - Configure zone transfers
  - Set up DNSSEC (if required)

#### 2.3 Integration Testing

- [ ] Create `playbooks/powerdns/test-deployment.yml`
  - DNS query testing
  - API functionality verification
  - Performance benchmarking
  - Failover testing

#### Phase Deliverables

- PowerDNS running in Nomad
- API fully functional
- Initial zones configured
- Test results documented

---

### Phase 3: NetBox Integration

**Duration**: 3-4 weeks
**Risk Level**: Medium
**Dependencies**: Phase 2 completion

#### 3.1 NetBox Deployment

- [ ] Create `nomad-jobs/netbox/netbox.nomad.hcl`

  - NetBox application job
  - PostgreSQL database job
  - Redis cache job
  - Persistent storage configuration

- [ ] Create `playbooks/netbox/deploy.yml`
  - Deploy NetBox stack
  - Initialize database
  - Configure authentication
  - Set up backup procedures

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

### Phase 4: DNS Cutover

**Duration**: 2-3 weeks
**Risk Level**: High
**Dependencies**: Phase 3 completion

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

### Phase 5: Production Hardening

**Duration**: 3-4 weeks
**Risk Level**: Low
**Dependencies**: Phase 4 completion

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
