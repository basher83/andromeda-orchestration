# Current Sprint: August 5-12, 2025

**Sprint Focus**: Complete HashiCorp stack and accelerate NetBox integration (NetBox already deployed!)

---

Navigation: [Summary](./task-summary.md) | [Completed](./completed/) | [Phases](./phases/) | [Full Archive](./archive/)
---

## 🎉 Critical Update: NetBox Already Deployed

**NetBox Details**:

- **Deployed**: LXC 213 on pve1
- **URL**: <https://192.168.30.213/>
- **Impact**: Major Phase 3 prerequisite complete!

This changes our priorities significantly - we can now accelerate NetBox integration tasks.

## 🚀 Active Tasks

### 21. PowerDNS-NetBox Integration

**Description**: Configure PowerDNS to use NetBox as backend for DNS records
**Status**: 🚧 In Progress (2025-08-07)
**Priority**: Critical - Phase 4 requirement
**Blockers**: None - Both NetBox and PowerDNS are operational
**Related**: Phase 4 core task

**Sprint Tasks**:

- [x] Install NetBox DNS plugin (v1.3.5 - installed and operational)
- [ ] Configure DNS zones in NetBox
- [ ] Set up PowerDNS API integration with NetBox
- [ ] Create sync script for NetBox to PowerDNS
- [ ] Test DNS record synchronization
- [ ] Configure automatic PTR records
- [ ] Set up zone transfers from NetBox
- [ ] Configure automatic DNS updates

### 20. Bootstrap NetBox with Essential Records (ACCELERATED)

**Description**: Configure NetBox and seed with critical DNS records
**Status**: ✅ Completed (2025-08-07)
**Priority**: Critical (NetBox is ready!)
**Blockers**: None - NetBox deployed and accessible
**Related**: Phase 3 core task

**Completed Tasks**:

- [x] Access NetBox at <https://192.168.30.213/>
- [x] Configure NetBox IPAM and DCIM modules
- [x] Create initial data model (sites, prefixes, VLANs)
- [x] Import critical infrastructure (Proxmox hosts, VMs)
- [x] Test API access and functionality
- [x] Created 3 sites (OG Homelab, Doggos Homelab)
- [x] Configured 4 network prefixes (192.168.10.0/24, 192.168.11.0/24, 192.168.30.0/24)
- [x] Added 3 Proxmox physical hosts with interfaces and IPs
- [x] Created Proxmox cluster configuration
- [x] Added 6 Nomad VMs with dual network interfaces
- [x] Assigned 29 IP addresses total
- [x] Created 4 operational playbooks for NetBox management

### 15. Deploy HashiCorp Vault

**Description**: Complete the HashiCorp stack with Vault for advanced secrets management
**Status**: ✅ Completed (2025-08-06)
**Priority**: High
**Blockers**: None
**Related**: docs/implementation/vault/, HashiCorp stack completion

**Completed Tasks**:

- [x] Created comprehensive Vault Ansible role with dev/production modes
- [x] Developed deployment playbooks for both dev and production
- [x] Documented phased deployment strategy
- [x] Researched and analyzed production patterns from 3 repositories
- [x] Created enhanced deployment strategy with PKI, rotation, and DR
- [x] Generated architecture diagrams for Vault and HashiCorp stack
- [x] Prepared Nomad integration templates (JWT workload identity)
- [x] Deployed Vault in dev mode to all 3 nomad-server nodes
- [x] Verified Vault accessibility and health on all nodes
- [x] Registered Vault services in Consul
- [x] Tested KV secret engine functionality
- [x] Stored dev token securely in Infisical at `/apollo-13/vault/`
- [x] Created comprehensive Vault operations documentation

**Deployment Details**:
- Running on: nomad-server-1-lloyd (v1.15.5), nomad-server-2-holly (v1.20.1), nomad-server-3-mable (v1.20.1)
- Dev token secured in Infisical: `/apollo-13/vault/VAULT_DEV_ROOT_TOKEN`
- Accessible at: http://192.168.10.11:8200, http://192.168.10.12:8200, http://192.168.10.13:8200
- Operations guide: `docs/operations/vault-access.md`
- Ready for production deployment when needed

### 29. Add Unit Tests for Custom Modules (NEW - Critical)

**Description**: Create unit tests for 14 custom modules with zero coverage
**Status**: Not Started
**Priority**: P0 (Critical) - No test coverage for custom code
**Blockers**: None
**Related**: Testing & QA Initiative, modules/*, tests/unit/

**Sprint Tasks**:

- [ ] Create test structure: `mkdir -p tests/unit/modules`
- [ ] Start with Consul modules (8 total) - highest usage
- [ ] Add pytest configuration and coverage setup
- [ ] Target: 80% code coverage minimum
- [ ] Run with: `task test:python`

## 🚧 Blocked Items

### PowerDNS Service Identity Tokens

**Issue**: Nomad workload identity tokens not being properly created
**Impact**: PowerDNS can't use Consul KV templates
**Workaround**: Deployed without service blocks
**Investigation Status**: Root cause identified - Nomad not deriving tokens

**Next Steps**:

- Monitor Nomad GitHub issues for fixes
- Consider alternative authentication methods
- Document permanent workaround if needed

## ✅ Recently Completed (Last 7 Days)

1. **NetBox Bootstrap and Population** (Aug 7)
   - Created sites, prefixes, and device roles
   - Added all physical hosts and VMs
   - Configured network interfaces and IP assignments
   - Created management playbooks

1. **Netdata Monitoring Optimization** (Aug 4)
   - Disabled unused Statsd collectors
   - Verified streaming architecture
   - All health checks passing

2. **Traefik Load Balancer** (Aug 2)
   - Deployed with full Consul integration
   - HTTP/HTTPS ports active
   - Service discovery working

3. **PowerDNS Deployment** (Aug 1)
   - Running on nomad-client-1
   - API accessible via Traefik
   - MySQL data persisted

### 30. Initialize Molecule Testing for Critical Roles (NEW)

**Description**: Add Molecule tests for HashiCorp stack roles
**Status**: Not Started
**Priority**: P1 (High) - Critical roles lack testing
**Blockers**: None
**Related**: Testing & QA Initiative, roles/*/molecule/

**Sprint Tasks**:

- [ ] Initialize Molecule for consul, nomad, vault roles
- [ ] Create default test scenarios
- [ ] Configure Docker/Podman drivers
- [ ] Run with: `task test:roles`

## 📋 Next Priorities (Updated for NetBox + Testing)

1. **PowerDNS-NetBox Integration** (Can start immediately!)
   - Install NetBox DNS plugin
   - Configure PowerDNS API integration
   - Test record sync capabilities

2. **Design IP Address Schema in NetBox**
   - Import existing network segments
   - Define service IP ranges
   - Create VLAN documentation

3. **Testing Infrastructure** (Critical gap identified!)
   - Unit tests for 14 custom modules
   - Molecule tests for critical roles
   - Fix syntax check issues
   - Document testing standards

## 📊 Sprint Metrics

- **Completed This Sprint**: 3 (Netdata optimization, Vault deployment, NetBox bootstrap)
- **In Progress**: 1 (PowerDNS-NetBox integration)
- **Blocked**: 1 (Service identity tokens)
- **Not Started**: 2 (Testing initiatives)
- **Overall Project**: 17/36 tasks (47%) - Phase 4 now active!

## 🔗 Quick Links

- [Task Summary](./task-summary.md) - Project overview
- [Phase 4 DNS Integration](./phases/phase-4-dns-integration.md) - Current phase
- [Phase 3 NetBox](./phases/phase-3-netbox.md) - Completed phase
- [Troubleshooting](../troubleshooting.md) - Known issues
- [Full Task Archive](./archive/full-task-list-2025-08-05.md) - Complete history
