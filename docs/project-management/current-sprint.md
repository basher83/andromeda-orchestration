# Current Sprint

![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/docs/project-management/current-sprint.md)
![Sprint Status](https://img.shields.io/badge/Sprint-2025--01--27%20to%202025--02--03-blue)
![Priority](https://img.shields.io/badge/Priority-Critical-red)

**Sprint Goal**: 🚨 CRITICAL domain migration (.local → spaceships.work) + Vault Production Deployment

## 🔗 Quick Links

- [ROADMAP](../../ROADMAP.md) | [GitHub Issues](https://github.com/basher83/andromeda-orchestration/issues) | [Domain Migration Plan](../implementation/dns-ipam/domain-migration-master-plan.md) | [Architecture Decisions](./decisions/)

## 🎯 Sprint Goals

### Aug 20 - Sprint 3: PowerDNS Integration

- **PR #4**: PowerDNS sync and integration (REVISED: 5.5 hrs)
- **Status**: ⚠️ Partially Complete - Infrastructure gaps discovered
- **Completed**: PostgreSQL deployed, PowerDNS job created
- **Blockers**: Port 53 conflicts, HCL2 variable passing issues

### Aug 21 - Sprint 4: Ansible Updates

- **PR #5**: Update all Ansible playbooks (3 hrs)
- **Status**: Not Started (Delayed due to Sprint 3 issues)
- **Target**: Fix remaining .local references

### Aug 22 (Today) - Infrastructure Assessment & Tooling

- **DNS IPAM Audit**: ✅ COMPLETED
  - Tailscale connectivity verified
  - Static inventory created (`inventory/tailscale-static.yml`)
  - Audit reports generated for all 6 Nomad nodes
  - Consul DNS confirmed on port 8600
  - No conflicting DNS services found (ready for PowerDNS)
- **Environment Setup**: ✅ COMPLETED
  - Mise/uv environment switching fixed
  - Tailscale documentation updated with safety guidelines
  - CHANGELOG updated with domain migration progress

### Aug 23-24 - Sprint 5: Documentation & Validation

- **PR #6**: Documentation and CI/CD (2 hrs)
- **Status**: Planning
- **Target**: Complete migration by Aug 24

## 📋 Active Tasks

### Deploy Vault in Production Mode ✅ PHASE 2 COMPLETE

- **Description**: Migrate Vault from dev mode to production with persistent storage
- **Status**: Completed (Phase 2)
- **Priority**: P0 (CRITICAL - Blocks ALL production services)
- **Blockers**: None
- **Deployment Guide**: [docs/implementation/vault/production-deployment.md](../implementation/vault/production-deployment.md)
- **Completion Evidence**:
  - ✅ 3-node Raft cluster operational (lloyd leader, holly/mable followers)
  - ✅ All nodes running Vault v1.20.2
  - ✅ Audit logging enabled at `/var/log/vault/audit.log`
  - ✅ Database and KV v2 secret engines enabled
  - ✅ Service policies created (postgresql-service, powerdns-service)
  - ✅ Cluster ID: `f96ca9f2-5c5a-791e-d08c-61653ba7e39c`
- **Next Phase**: Service Integration (PostgreSQL, PowerDNS)

### Apply Infrastructure Configuration (UNBLOCKED)

- **Description**: Apply repository domain changes to running infrastructure
- **Status**: Ready to Start
- **Priority**: P0 (Critical)
- **Blockers**: None (Vault Phase 2 complete)
- **Related**: PRs #71, #72, #76 (merged but not applied)
- **Next Actions**:
  1. Configure PostgreSQL connection in Vault
  2. Deploy PostgreSQL with Vault-managed credentials
  3. Apply domain configuration to services

### Create NetBox DNS Zones (Can do in parallel with Vault)

- **Description**: Execute PR #76 playbooks to create zones in NetBox
- **Status**: Ready to Start
- **Priority**: P0 (Critical - Can be done now)
- **Blockers**: None (NetBox is running, playbooks are ready)
- **Related**: PR #76 (merged but not executed)
- **Next Actions**:
  1. Run setup-zones.yml to create spaceships.work zones
  2. Run populate-records.yml to add DNS records
  3. Verify zones in NetBox UI

### Deploy PostgreSQL Backend (UNBLOCKED)

- **Description**: Deploy PostgreSQL for PowerDNS backend
- **Status**: Ready to Start
- **Priority**: P0 (Critical - PowerDNS dependency)
- **Blockers**: None (Vault Phase 2 complete, database engine enabled)
- **Related**: PowerDNS deployment
- **Next Actions**:
  1. Configure Vault database connection
  2. Create PostgreSQL role in Vault
  3. Deploy PostgreSQL via Nomad with dynamic credentials

### PowerDNS Integration Updates (PARTIALLY UNBLOCKED)

- **Description**: Sync new zones to PowerDNS
- **Status**: Partially Blocked
- **Priority**: P0 (Critical)
- **Blockers**:
  1. ✅ Vault in production mode (RESOLVED)
  2. PostgreSQL backend not deployed (Ready to start)
  3. Infrastructure configuration not applied (Ready to start)
- **Related**: [Master Plan](../implementation/dns-ipam/domain-migration-master-plan.md), Issue #28
- **Next Actions**: Deploy PostgreSQL, then PowerDNS

### Ansible Playbook Migration

- **Description**: Update remaining .local references in playbooks
- **Status**: Not Started
- **Priority**: P0 (Critical)
- **Blockers**: None
- **Related**: Issues #19, #22

### Documentation & CI Prevention

- **Description**: Update docs and add CI checks for .local
- **Status**: Not Started
- **Priority**: P1 (High)
- **Blockers**: None
- **Related**: Issue #18

## ✅ Completed (Aug 19-22)

### August 19-20

- ✅ PR #71: homelab_domain variable setup (merged)
- ✅ PR #72: Nomad HCL2 variables (merged)
- ✅ PR #76: NetBox DNS playbook updates (merged - code only, NOT executed)
- ✅ PR #73-74: Dependency updates (merged)

### August 22

- ✅ DNS IPAM Infrastructure Audit completed
  - All nodes using external DNS (Google/Cloudflare)
  - Consul DNS operational on port 8600
  - No DNS service conflicts detected
  - Infrastructure ready for PowerDNS deployment
- ✅ Tailscale remote development environment fixed
  - Static inventory created to avoid delegation issues
  - Documentation updated with critical safety info
- ✅ Mise/uv environment management improved
  - Setup tasks automated
  - Environment switching between local/remote working

## 📊 Sprint Metrics

- **Completed PRs**: 3 (PR #71, #72, #76) ✅ (merged but not applied to infrastructure)
- **Remaining PRs**: 3 (PR #4, #5, #6)
- **Progress**: 50% repository changes, 25% infrastructure changes (Vault deployed)
- **Risk Level**: MEDIUM - Vault deployed, PostgreSQL deployment next
- **Tomorrow's Focus**:
  1. ✅ Vault production deployment COMPLETE (Phase 2)
  2. Configure PostgreSQL with Vault integration
  3. Execute NetBox DNS zone creation
- **Key Finding**: Vault Phase 2 complete - unblocks PostgreSQL and PowerDNS deployments

## 🔗 Quick Links

- [Domain Migration Master Plan](../implementation/dns-ipam/domain-migration-master-plan.md)
- [GitHub Epic #18](https://github.com/basher83/andromeda-orchestration/issues/18)
- [Phase 4: DNS Integration](./phases/phase-4-dns-integration.md)
- [PowerDNS Job](../nomad-jobs/platform-services/powerdns-auth.nomad.hcl)
