# andromeda-orchestration Project Task List

This document tracks all project management tasks for the NetBox-focused Ansible automation project, organized by priority and implementation phase.

## Project Status Overview

**Project Phase**: Phase 2 Implementation Complete + Infrastructure Monitoring
**Current Focus**: Service mesh infrastructure operational, monitoring systems optimized
**Last Updated**: 2025-08-04
**Status**: Phase 1 & 2 completed, Traefik with service registration working, Netdata monitoring optimized

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
**Status**: Completed (2025-07-29)
**Blockers**: None - All tasks completed
**Related**: `infisical-setup-and-migration.md`

Tasks:

- [x] Implement organized folder structure in Infisical
- [x] Update all inventory files to use organized paths
- [x] Add API_URL lookups for each cluster
- [x] Add shared credential lookups (USERNAME, TOKEN_ID)
- [x] Update playbooks to use new paths (Consul, Nomad, Infrastructure)
- [x] Migrate all secrets from 1Password lookups to Infisical
- [x] Archive 1Password configuration files (completed 2025-07-29 - files in docs/archive/)
- [ ] Implement environment-aware lookups (Phase 4 - future)

#### 4. Document Current Network State ✅

**Description**: Create comprehensive documentation of existing infrastructure
**Status**: Completed (2025-07-30)
**Blockers**: None
**Related**: Assessment playbook outputs, `docs/operations/pihole-ha-cluster.md`

Tasks:

- [x] Identify Pi-hole deployment type (Docker/LXC/VM) and which host it runs on
  - FOUND: 3x LXC containers in HA configuration with keepalived
  - LXC 103 on proxmoxt430, LXC 136 & 139 on pve1
- [x] Document all DNS zones and records from Pi-hole
  - Full documentation in `docs/operations/pihole-ha-cluster.md`
  - Keepalived configuration with VIP 192.168.30.100
  - Network segments identified
  - Backup procedures documented
- [x] Map current IP allocations (found 3 networks)
- [x] Identify all DHCP scopes
- [x] Create network topology diagrams

#### 5. Apply Consul ACL Tokens to Nomad Configuration

**Description**: Apply existing Consul ACL tokens to Nomad nodes for service registration
**Status**: ✅ Completed (2025-07-30)
**Blockers**: None
**Related**: Consul-Nomad integration

Tasks:

- [x] Create Consul ACL tokens (completed 2025-07-29)
  - Server token: <redacted>
  - Client token: <redacted>
- [x] Store tokens in Infisical at /apollo-13/consul/
- [x] Create playbook to apply tokens (apply-consul-tokens-to-nomad.yml)
- [x] Execute playbook to apply tokens to all Nomad nodes (completed 2025-07-29)
  - Token configured in /etc/nomad.d/nomad.hcl on all Nomad servers
  - Nomad services restarted after token configuration
- [x] Restart Nomad services to activate token configuration (completed 2025-07-30)
- [x] Verify service registration in Consul (completed 2025-07-30)
  - All services registered successfully: consul, nomad (3 servers), nomad-client (3 clients)
  - ACL token required for service queries
  - All nodes including mable working correctly

#### 6. Fix Consul Service on nomad-client-3-mable

**Description**: Consul service is not running on nomad-client-3-mable
**Status**: ✅ Resolved - Service confirmed active (2025-07-30)
**Blockers**: None
**Related**: Consul cluster health

Tasks:

- [x] Create playbook to fix Consul configuration
- [x] Consul service verified active on all nodes including mable (2025-07-30)
  - All services (Nomad and Consul) confirmed active via systemctl
  - No manual intervention required
- [x] Verify Consul service is running
- [x] Confirm node joins Consul cluster

#### 7. Establish Backup Procedures

**Description**: Implement backup strategy for critical configurations
**Status**: ✅ Already Handled - Existing backup processes are in place and working
**Blockers**: None
**Related**: Risk mitigation strategy

**Note**: Backup procedures are already implemented and maintained outside of this project scope. No action required.

### Medium Priority - Phase 0-1 Preparation

These tasks support the implementation but aren't immediate blockers.

#### 8. Import Infrastructure Roles from terraform-homelab

**Description**: Import existing Ansible roles and modules for infrastructure management
**Status**: ✅ Completed (2025-07-30)
**Blockers**: None
**Related**: Reusable infrastructure components

Tasks:

- [x] Import consul role for service discovery deployment
- [x] Import nomad role for workload orchestration
- [x] Import system_base role with firewall configurations
- [x] Import nfs role for shared storage
- [x] Import custom Consul/Nomad modules
- [x] Create consul_dns role for Phase 1
- [x] Document imported components
- [x] Update repository structure

#### 9. Enable Consul Telemetry and Monitoring

**Description**: Configure Prometheus metrics collection for Consul cluster
**Status**: ✅ Completed (2025-07-30)
**Blockers**: None
**Related**: Infrastructure monitoring and observability

Tasks:

- [x] Enable telemetry endpoints on all Consul nodes
- [x] Create ACL policy "prometheus-scraping" with read permissions
- [x] Generate ACL token for Prometheus/Netdata access
- [x] Configure Netdata collectors on all nodes
- [x] Store token in Infisical at `/apollo-13/consul/PROMETHEUS_SCRAPING_TOKEN`
- [x] Validate metrics collection is working
- [x] Create documentation for telemetry setup

**Documentation**: [Consul Telemetry Setup Guide](../../implementation/consul/telemetry-setup.md)

#### 10. Phase 1: Cement Consul Foundation ✅

**Description**: Enable Consul DNS on all nodes and configure service discovery
**Status**: Completed (2025-08-01)
**Blockers**: None
**Related**: `phase1-implementation-guide.md`, Phase 1 of ROADMAP

Tasks:

- [x] Deploy systemd-resolved configuration to all doggos-homelab nodes
- [x] Configure DNS forwarding for .consul domain to port 8600
- [x] Update /etc/resolv.conf symlinks to use systemd-resolved
- [x] Verify Consul DNS resolution (consul.service.consul queries)
- [x] Test service discovery for registered services

**Implementation Details**:

- Used `phase1-consul-dns.yml` playbook with consul_dns role
- Configured systemd-resolved on all 9 doggos-homelab nodes
- DNS forwarding rule: ~consul → 127.0.0.1:8600
- Service registration deferred (no consul_servers group defined)

#### 11. Phase 2: Deploy PowerDNS to Nomad ✅

**Description**: Deploy PowerDNS as authoritative DNS server in Nomad
**Status**: Completed (2025-08-01)
**Blockers**: None
**Related**: PowerDNS Nomad job, Phase 2 of ROADMAP

Tasks:

- [x] Generate secure passwords for MySQL and API access
- [x] Store PowerDNS secrets in Consul KV:
  - powerdns/mysql/root_password
  - powerdns/mysql/password
  - powerdns/api/key
- [x] Create host volumes on Nomad clients for MySQL persistence
- [x] Configure Nomad clients with host_volume "powerdns-mysql"
- [x] Enable anonymous read ACL for PowerDNS KV (temporary for testing)
- [x] Deploy PowerDNS Nomad job with MariaDB and PowerDNS tasks
- [x] Verify services are running and healthy

**Deployment Details**:

- Running on nomad-client-1 (allocation: b87b56bf)
- DNS service: 192.168.11.20:53
- API service: Dynamic port (accessible via Traefik at <https://powerdns.lab.local>)
- MySQL with persistent storage at /opt/nomad/volumes/powerdns-mysql
- Docker image: powerdns/pdns-auth-48:latest
- Updated to use dynamic port allocation for API (removed static 8081)

#### 12. Integrate Nomad Job Management ✅

**Description**: Organize Nomad jobs and implement standardized deployment patterns
**Status**: Completed (2025-08-02)
**Blockers**: None
**Related**: Infrastructure management patterns

Tasks:

- [x] Create nomad-jobs/ directory structure (core-infrastructure, platform-services, applications)
- [x] Migrate PowerDNS job to new structure with dynamic port allocation
- [x] Create Traefik load balancer job specification
- [x] Update deployment playbooks to use community.general.nomad_job Galaxy module
- [x] Create specialized deployment playbook for Traefik with validation
- [x] Document port allocation strategy (dynamic by default, static for DNS/LB only)
- [x] Update CLAUDE.md with Nomad job patterns

**Implementation Details**:

- Using Galaxy modules instead of custom modules for maintainability
- Traefik will own ports 80/443 for all HTTP/HTTPS traffic
- All other services use dynamic ports (20000-32000) with Consul service discovery
- PowerDNS API now accessible via <https://powerdns.lab.local> through Traefik

#### 13. Deploy Traefik Load Balancer ✅

**Description**: Deploy Traefik as the primary load balancer for all services
**Status**: Completed (2025-08-02)
**Blockers**: None
**Related**: Network architecture and service routing

Tasks:

- [x] Fixed Docker iptables/nftables compatibility on all nodes
- [x] Fixed Consul configuration blocks on Nomad servers and clients
- [x] Enabled ACLs on all Consul agents with proper tokens
- [x] Created Consul auth method for Nomad workloads
- [x] Deployed Traefik with service registration in Consul
- [x] Services registered: traefik, traefik-http, traefik-https
- [x] Verify ports 80/443 are available and bound
- [x] Confirm Consul Catalog integration working

**Implementation Details**:

- Running on nomad-client-1-lloyd (allocation: aa69be4a)
- HTTP: 192.168.11.20:80
- HTTPS: 192.168.11.20:443
- Admin: Dynamic port with Consul service registration
- All services properly registered in Consul with health checks

#### 14. Optimize Netdata Monitoring Infrastructure ✅

**Description**: Analyze and optimize Netdata configuration across all nodes
**Status**: Completed (2025-08-04)
**Blockers**: None
**Related**: Infrastructure monitoring and observability

Tasks:

- [x] Collected comprehensive Netdata configurations from all nodes
- [x] Analyzed streaming architecture and confirmed parent/child relationships
- [x] Verified Consul integration - all health checks passing
- [x] Identified and fixed statsd port misconfigurations
- [x] Disabled unused Statsd collectors on all nodes to save resources
- [x] Documented configuration findings and recommendations

**Key Findings**:

- Netdata streaming working correctly (issues were resolved 2025-08-02)
- Parent nodes: lloyd, holly, mable, pve1 (correctly configured)
- 192.168.11.x network used for dedicated Netdata streaming
- No Consul errors, all netdata-child health checks passing
- Statsd was enabled but completely unused - disabled on all nodes

#### 15. Deploy HashiCorp Vault

**Description**: Complete the HashiCorp stack with Vault for advanced secrets management
**Status**: Not Started
**Blockers**: Traefik should be deployed first for HTTPS access
**Related**: Secrets management strategy, HashiCorp stack completion

Tasks:

- [ ] Create Vault Nomad job specification (dev mode initially)
- [ ] Deploy Vault in dev mode for exploration
- [ ] Configure Consul as storage backend
- [ ] Set up auto-unseal mechanism
- [ ] Create basic ACL policies for services
- [ ] Test Nomad-Vault integration
- [ ] Migrate PowerDNS secrets from Consul KV to Vault
- [ ] Document Vault access patterns
- [ ] Plan production deployment with HA

#### 16. Create Development Environment

**Description**: Set up isolated testing environment for DNS/IPAM changes
**Status**: Skipped - doggos-homelab cluster is development environment
**Blockers**: None
**Related**: `dns-ipam-implementation-plan.md` - Phase 1

Tasks:

- [x] Decision: Use doggos-homelab as development environment
- [ ] ~~Deploy test VMs for Consul/PowerDNS~~ (not needed)
- [ ] ~~Configure isolated network segment~~ (not needed)
- [ ] ~~Set up test clients~~ (not needed)
- [ ] ~~Document access procedures~~ (not needed)

### Design IP Address Schema

**Description**: Create comprehensive IP addressing plan for all networks
**Status**: Not Started
**Blockers**: Current state documentation required
**Related**: NetBox IPAM configuration

Tasks:

- [ ] Define network segments
- [ ] Allocate service ranges
- [ ] Plan for growth
- [ ] Document in NetBox

### Develop Service Templates

**Description**: Create Ansible templates for service configurations
**Status**: Not Started
**Blockers**: None
**Related**: Implementation phases

Tasks:

- [ ] Consul configuration templates
- [ ] PowerDNS zone templates
- [ ] NetBox custom fields
- [ ] Integration scripts

### Implement Monitoring Strategy

**Description**: Deploy monitoring for DNS/IPAM services
**Status**: Not Started
**Blockers**: Services must be deployed first
**Related**: Phase 2 implementation

Tasks:

- [ ] Define key metrics
- [ ] Set up Prometheus exporters
- [ ] Create Grafana dashboards
- [ ] Configure alerts

### Create Migration Runbooks

**Description**: Detailed procedures for each migration phase
**Status**: Not Started
**Blockers**: Architecture decisions needed
**Related**: All implementation phases

Tasks:

- [ ] Phase 1 deployment procedures
- [ ] Phase 2 integration steps
- [ ] Phase 3 migration checklist
- [ ] Rollback procedures

### Establish Change Management Process

**Description**: Define how changes will be tracked and approved
**Status**: Not Started
**Blockers**: None
**Related**: Project governance

Tasks:

- [ ] Create change request template
- [ ] Define approval workflow
- [ ] Set up change tracking
- [ ] Document in project wiki

### Bootstrap NetBox with Essential Records

**Description**: Seed NetBox with critical DNS records to enable early PowerDNS sync
**Status**: Not Started
**Blockers**: NetBox deployment required
**Related**: Phase 3 bootstrap strategy per ROADMAP.md

Tasks:

- [ ] Identify critical DNS records (proxmox hosts, core services)
- [ ] Create minimal NetBox data model
- [ ] Test PowerDNS sync with limited dataset
- [ ] Plan incremental data migration approach

#### 28. Implement Markdown Linting and Enforcement

**Description**: Set up automated markdown linting to enforce documentation standards
**Status**: Not Started
**Blockers**: None
**Related**: docs/standards/documentation-standards.md (lines 53-55)

Tasks:

- [ ] Set up markdownlint or similar tool
- [ ] Create .markdownlint.json configuration enforcing:
  - Language specification for all code blocks
  - Blank lines around lists and code blocks
  - Other standards from documentation-standards.md
- [ ] Add pre-commit hooks for markdown validation
- [ ] Configure CI checks for pull requests
- [ ] Create cleanup script for existing violations
- [ ] Document linting setup in docs/standards/linting-standards.md

### Low Priority - Future Phases

These tasks are important but can wait until implementation begins.

#### 15. Plan Multi-Site DNS Strategy

**Description**: Design DNS architecture for og-homelab integration
**Status**: Not Started
**Blockers**: Single site must work first
**Related**: Phase 4 expansion

Tasks:

- [ ] Assess og-homelab requirements
- [ ] Design cross-site replication
- [ ] Plan zone delegation
- [ ] Document architecture

#### 16. Develop Automation Workflows

**Description**: Create event-driven automation for DNS/IPAM
**Status**: Not Started
**Blockers**: Core services required
**Related**: Phase 5 optimization

Tasks:

- [ ] NetBox webhook configuration
- [ ] Ansible AWX/Tower integration
- [ ] Auto-provisioning workflows
- [ ] Self-service portals

#### 17. Create User Documentation

**Description**: End-user guides for new DNS/IPAM services
**Status**: Not Started
**Blockers**: Implementation must be complete
**Related**: Phase 3 migration

Tasks:

- [ ] DNS query troubleshooting
- [ ] Service discovery guides
- [ ] IPAM request procedures
- [ ] FAQ documentation

#### 18. Design Disaster Recovery Plan

**Description**: Comprehensive DR strategy for DNS/IPAM
**Status**: Not Started
**Blockers**: Architecture must be finalized
**Related**: Production readiness

Tasks:

- [ ] Define RTO/RPO objectives
- [ ] Create DR procedures
- [ ] Test failover scenarios
- [ ] Document recovery steps

#### 19. Implement Security Hardening

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
- [ ] Let's Encrypt wildcard certificates for \*.lab.example.com
- [ ] Vault PKI integration for internal service certificates
- [ ] Consul Connect mTLS for service-to-service encryption
- [ ] Nomad periodic jobs for certificate renewal
- [ ] Certificate storage strategy (host volumes, Consul KV, or Vault)

#### 20. Performance Optimization

**Description**: Tune services for optimal performance
**Status**: Not Started
**Blockers**: Baseline metrics needed
**Related**: Phase 5 optimization

Tasks:

- [ ] DNS query optimization
- [ ] Consul performance tuning
- [ ] Database optimization
- [ ] Cache configuration

#### 21. Capacity Planning

**Description**: Plan for future growth and scaling
**Status**: Not Started
**Blockers**: Current usage patterns needed
**Related**: Long-term planning

Tasks:

- [ ] Growth projections
- [ ] Resource requirements
- [ ] Scaling strategies
- [ ] Budget planning

#### 22. Integration Testing

**Description**: Comprehensive testing of all integrations
**Status**: Not Started
**Blockers**: Components must be deployed
**Related**: Phase 2-3 validation

Tasks:

- [ ] NetBox-Consul integration
- [ ] PowerDNS-NetBox sync
- [ ] Ansible automation tests
- [ ] End-to-end scenarios

#### 23. Create Operational Dashboards

**Description**: Real-time visibility into DNS/IPAM operations
**Status**: Not Started
**Blockers**: Monitoring must be deployed
**Related**: Phase 2 implementation

Tasks:

- [ ] Service health dashboards
- [ ] Query analytics
- [ ] IPAM utilization
- [ ] Trend analysis

#### 24. Develop SOP Documentation

**Description**: Standard operating procedures for common tasks
**Status**: Not Started
**Blockers**: Processes must be established
**Related**: Operational readiness

Tasks:

- [ ] Daily checks
- [ ] Incident response
- [ ] Maintenance procedures
- [ ] Escalation paths

#### 25. Configure Automated Backups

**Description**: Automated backup solutions for all services
**Status**: Not Started
**Blockers**: Services must be deployed
**Related**: Production readiness

Tasks:

- [ ] Backup scheduling
- [ ] Retention policies
- [ ] Off-site storage
- [ ] Recovery testing

#### 26. Implement Compliance Controls

**Description**: Ensure compliance with relevant standards
**Status**: Not Started
**Blockers**: Requirements gathering needed
**Related**: Governance

Tasks:

- [ ] Identify requirements
- [ ] Implement controls
- [ ] Audit procedures
- [ ] Compliance reporting

#### 27. Plan Knowledge Transfer

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

- **Completed**: 14/33 tasks (42%)
- **In Progress**: 0/33 tasks (0%)
- **Not Started**: 19/33 tasks (58%)

### Phase Breakdown

- **High Priority**: 7/7 completed (100% - All high priority tasks complete)
- **Medium Priority**: 7/13 completed (54% - Roles imported, telemetry enabled, Phase 1 & 2 complete, Nomad jobs integrated, Traefik deployed, Netdata optimized)
- **Low Priority**: 0/13 completed (0%)

## Risk Items and Blockers

### Critical Risks

1. **DNS Infrastructure Complexity**: Pi-hole runs as 3-node HA cluster with keepalived - migration more complex than expected

### Current Blockers

1. **Service Identity Token Derivation**: Nomad workload identity tokens not being properly created for services
   - Auth method configured but tokens still using Nomad client token instead of workload-specific tokens
   - PowerDNS deployment blocked due to Consul KV access permissions
   - Need to investigate Nomad service identity configuration
   - **Investigation Complete (2025-08-02)**: Confirmed auth method is properly configured but Nomad is not deriving tokens
   - **Workaround Applied**: Deployed PowerDNS without service blocks to avoid validation errors

### Active Issues

1. **PowerDNS Deployment**: Currently using minimal deployment without service blocks
   - Service identity tokens not working for Consul KV access
   - Templates fail with "Permission denied" when trying to read KV values
   - Temporary workaround: Deploy without KV lookups using hardcoded values

## Recommendations for Task Execution

### Immediate Actions (Next 3-5 Days)

1. **Provision storage volumes** - Run provision-host-volumes.yml for Traefik
2. **Deploy Traefik load balancer** - Enable service routing and HTTPS access
3. **Deploy HashiCorp Vault (dev mode)** - Complete the HashiCorp stack
4. **Bootstrap NetBox with essential DNS records** - Phase 3 priority

### Week 2 Focus

1. **Configure Vault production mode** - Consul backend, auto-unseal, basic policies
2. **Migrate secrets from Consul KV to Vault** - Start with new services
3. **Configure PowerDNS sync with NetBox** - Enable authoritative DNS management
4. **Design IP addressing schema** for comprehensive IPAM

### Week 3-4 Focus

1. **Migrate critical DNS records from Pi-hole** to PowerDNS
2. **Test PowerDNS as authoritative resolver** for lab domains
3. **Plan cutover strategy** from Pi-hole to PowerDNS

### Month 2 Goals

1. **Complete Phase 3 NetBox integration** - DNS record migration
2. **Establish monitoring** for PowerDNS performance
3. **Begin Phase 5** - Multi-Site Expansion
4. **Create operational documentation** for DNS management

## Related Documentation

- [DNS & IPAM Implementation Plan](../../implementation/dns-ipam/implementation-plan.md) - Master implementation roadmap
- [Phase 1 Implementation Guide](../../implementation/dns-ipam/phase1-guide.md) - Consul DNS setup guide
- [Imported Infrastructure](../../implementation/imported-infrastructure.md) - Documentation of imported roles and modules
- [Repository Structure](../../getting-started/repository-structure.md) - Updated project organization
- [NetBox Integration Patterns](../../implementation/dns-ipam/netbox-integration-patterns.md) - NetBox configuration and usage
- [Infisical Setup and Migration](../../implementation/infisical/infisical-setup.md) - Secret management transition
- [Troubleshooting Guide](../../troubleshooting/README.md) - Common issues and solutions
- [1Password Integration (Archived)](../../archive/1PASSWORD_ARCHIVE_SUMMARY.md) - Legacy secret management (archived 2025-07-29)

## Maintenance Notes

This document should be updated:

- Weekly during active implementation
- After each task completion
- When new tasks are identified
- When priorities change

Last review: 2025-07-30
Next review: 2025-08-06

## Change Log

- **2025-08-04**: Netdata Monitoring Infrastructure Optimized
  - Completed comprehensive Netdata configuration analysis across all nodes
  - Confirmed Netdata streaming architecture working correctly:
    - Parent nodes properly identified: lloyd, holly, mable, pve1
    - All child nodes streaming successfully to parents
    - Dedicated 192.168.11.x network for Netdata streaming traffic
  - Verified Consul integration fully operational:
    - All netdata-child health checks passing
    - No active Consul-related alerts
    - Historical issues from 2025-08-03 have been resolved
  - Optimized resource usage:
    - Disabled unused Statsd collectors on all nodes
    - Fixed statsd port misconfigurations on parent nodes
    - Created disable-statsd.yml playbook for configuration management
  - Created comprehensive documentation:
    - Netdata configuration comparison report
    - Consul integration analysis report
    - Stream configuration analysis
  - Removed resolved issue: Netdata streaming authentication no longer a problem
  - Progress updated: 14/33 tasks completed (42%), Medium priority at 54%
  - Note: Check_MK was also purged from 4 nodes as part of cleanup
- **2025-08-02** (Update 4): Service Identity Investigation Complete
  - Investigated service identity token derivation issue using Netdata monitoring
  - Confirmed Consul auth method `nomad-workloads` is properly configured:
    - JWKS endpoint accessible from all nodes
    - Binding rules and roles correctly set up
    - Policies grant appropriate KV read access
  - Root cause identified: Nomad not attempting to derive workload tokens
  - Applied workaround: Deployed PowerDNS without service blocks
  - Current deployment status:
    - Traefik: Running with service blocks (working somehow)
    - PowerDNS: Running without service blocks (workaround)
  - Updated troubleshooting documentation with investigation findings
- **2025-08-02** (Update 3): Traefik Deployed with Service Mesh Infrastructure
  - Successfully deployed Traefik load balancer with full Consul service registration
  - Fixed multiple infrastructure issues to enable service mesh:
    - Docker iptables/nftables compatibility resolved on all nodes
    - Consul ACL configuration fixed on all agents
    - Multiple Consul configuration blocks cleaned up
    - Created auth method and policies for Nomad workload identities
  - Traefik services registered in Consul: traefik, traefik-http, traefik-https
  - Identified blocking issues for PowerDNS:
    - Service identity token derivation not working properly
    - Workloads using Nomad client token instead of derived tokens
    - PowerDNS templates fail with KV permission errors
  - Additional issue discovered: Netdata streaming authentication failures
  - Progress updated: 13/32 tasks completed (41%), Medium priority at 50%
- **2025-08-02** (Update 2): HashiCorp Vault Added to Deployment Strategy
  - Added HashiCorp Vault deployment task (#14) to complete the HashiCorp stack
  - Vault will provide advanced secrets management capabilities:
    - Dynamic database credentials
    - PKI/Certificate management
    - Encryption as a service
    - Native Nomad integration
  - Deployment strategy: Start with dev mode, migrate to production with Consul backend
  - Updated immediate actions to include Vault deployment after Traefik
  - Adjusted timeline: Week 2 for Vault production config, Week 3-4 for DNS migration
  - Total task count increased to 32 (was 31)
  - Rationale: Complete HashiCorp stack expertise > partial implementation
- **2025-08-02**: Nomad Job Management Integration and Infrastructure Enhancements
  - Integrated Nomad job management with standardized directory structure
    - Created nomad-jobs/ with core-infrastructure/, platform-services/, applications/
    - Migrated PowerDNS job with dynamic port allocation (removed static 8081)
    - Created Traefik load balancer job specification
  - Updated deployment patterns to use Galaxy modules
    - Leveraging community.general.nomad_job module
    - Created generic deploy-job.yml playbook
    - Created specialized deploy-traefik.yml with validation
  - Established port allocation strategy
    - Dynamic ports (20000-32000) by default
    - Static ports only for DNS (53) and load balancer (80/443)
    - All services accessible via Traefik routing
  - Documentation updates
    - Updated CLAUDE.md with Nomad patterns
    - Created comprehensive README files for nomad-jobs
    - Documented firewall and port strategies
  - Task count increased to 31 (added Nomad integration and Traefik deployment tasks)
  - PowerDNS API now accessible via <https://powerdns.lab.local> through Traefik
- **2025-08-01**: Phase 1 & 2 DNS Infrastructure Implementation Complete
  - Phase 1: Deployed Consul DNS foundation across doggos-homelab cluster
    - Configured systemd-resolved on all 9 nodes for .consul domain resolution
    - DNS forwarding rule: ~consul → 127.0.0.1:8600
    - All nodes successfully resolving consul.service.consul queries
  - Phase 2: PowerDNS deployed to Nomad as authoritative DNS server
    - Generated secure passwords and stored in Consul KV
    - Created host volumes for MySQL persistence
    - PowerDNS running on nomad-client-1 at 192.168.11.20:53
    - API accessible at 192.168.11.20:8081
    - MySQL data persisted at /opt/nomad/volumes/powerdns-mysql
  - Updated project status to "Phase 2 Implementation Complete"
  - Ready for Phase 3: NetBox integration and DNS record migration
- **2025-07-30** (Update 7): Consul telemetry and monitoring enabled
  - Enabled telemetry endpoints on all Consul nodes
  - Created "prometheus-scraping" ACL policy with read permissions
  - Generated ACL token for Prometheus/Netdata access
  - Configured Netdata collectors on all nodes with the token
  - Stored token in Infisical at `/apollo-13/consul/PROMETHEUS_SCRAPING_TOKEN`
  - Validated metrics collection is working (consul_local.\* charts available)
  - Created comprehensive documentation for telemetry setup
  - Task count increased to 29 (added telemetry task as #9)
- **2025-07-30** (Update 6): Infrastructure roles imported and documented
  - Imported consul, nomad, system_base, and nfs roles from terraform-homelab
  - Imported custom Consul/Nomad modules and utilities
  - Created consul_dns role for Phase 1 DNS implementation
  - Created comprehensive documentation for imported components
  - Updated repository structure to reflect new organization
  - Added Phase 1 implementation guide
  - Task count increased to 28 (added infrastructure import task)
- **2025-07-30** (Update 5): Consul-Nomad integration fully operational
  - Confirmed all Nomad services successfully registered in Consul after restart
  - Services registered: consul, nomad (3 servers), nomad-client (3 clients)
  - Removed service registration from risks and blockers
  - Updated immediate actions to focus on Phase 1 implementation
  - All high-priority pre-implementation tasks now complete
- **2025-07-30** (Update 4): Major status update based on verification
  - Marked Task 5 (Consul ACL Tokens) as completed - tokens already applied on 2025-07-29
  - Marked Task 6 (Fix Consul on mable) as resolved - service confirmed active
  - Updated progress: 7/27 tasks completed (26%), all high priority tasks complete
  - Discovered services not registering despite token configuration - needs restart
  - Updated immediate actions to focus on service restart and verification
- **2025-07-30** (Update 3): Updated backup procedures documentation
  - Marked Task 7 (Backup Procedures) as already handled - existing processes in place
  - Removed backup strategy from critical risks and current blockers
  - Updated immediate actions to remove backup-related tasks
  - Clarified that backups are maintained outside project scope
- **2025-07-30** (Update 2): Corrected task statuses based on evidence review
  - Marked Pi-hole HA Cluster Documentation as completed - full documentation exists in docs/infrastructure/pihole-ha-cluster.md
  - Corrected task 5 status to "Not Started" - playbook exists but hasn't been executed
  - Corrected task 6 status to "Not Started" - playbook exists but hasn't been executed
  - Updated progress metrics: 4/27 completed (15%), 0 in progress
- **2025-07-30**: Major status correction and task realignment
  - Corrected Consul ACL token status - tokens already created on 2025-07-29
  - Added two new high-priority tasks for applying tokens and fixing Consul on mable
  - Marked 1Password archive as completed (files in docs/archive/)
  - Updated task count to 27 total tasks
  - Reordered priorities to reflect actual next steps
  - Clarified that Consul-Nomad integration is partially complete (config applied, tokens pending)
- **2025-07-29**: Project status update and alignment check
  - Updated progress metrics: 3/25 tasks completed (12%)
  - Removed resolved blockers (Proxmox inventory fixed, Infisical Phase 3 complete)
  - Updated immediate actions to focus on remaining blockers
  - Added NetBox bootstrap task per ROADMAP.md recommendation
  - Adjusted priority tasks based on current completion status
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
