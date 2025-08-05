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

### 20. Bootstrap NetBox with Essential Records (ACCELERATED)

**Description**: Configure NetBox and seed with critical DNS records
**Status**: In Progress
**Priority**: Critical (NetBox is ready!)
**Blockers**: None - NetBox deployed and accessible
**Related**: Phase 3 core task

**Sprint Tasks**:

- [ ] Access NetBox at <https://192.168.30.213/>
- [ ] Configure NetBox IPAM and DCIM modules
- [ ] Create initial data model (sites, prefixes, VLANs)
- [ ] Import critical DNS records (proxmox hosts, core services)
- [ ] Test API access from PowerDNS

### 15. Deploy HashiCorp Vault

**Description**: Complete the HashiCorp stack with Vault for advanced secrets management
**Status**: Not Started
**Priority**: High (but NetBox takes precedence)
**Blockers**: None - Traefik deployed for HTTPS access
**Related**: Secrets management strategy, HashiCorp stack completion

**Sprint Tasks**:

- [ ] Create Vault Nomad job specification (dev mode initially)
- [ ] Deploy Vault in dev mode for exploration
- [ ] Test basic secret storage and retrieval
- [ ] Document access patterns

### 28. Implement Markdown Linting and Enforcement

**Description**: Set up automated markdown linting to enforce documentation standards
**Status**: Not Started
**Priority**: P1 (High) - Growing documentation debt
**Blockers**: None
**Related**: docs/standards/documentation-standards.md (lines 53-55)

**Sprint Tasks**:

- [ ] Set up markdownlint or similar tool
- [ ] Create .markdownlint.json configuration enforcing:
  - Language specification for all code blocks
  - Blank lines around lists and code blocks
  - Other standards from documentation-standards.md
- [ ] Add pre-commit hooks for markdown validation
- [ ] Configure CI checks for pull requests
- [ ] Create cleanup script for existing violations
- [ ] Document linting setup in docs/standards/linting-standards.md

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

## 📋 Next Priorities (Updated for NetBox Availability)

1. **PowerDNS-NetBox Integration** (Can start immediately!)
   - Install NetBox DNS plugin
   - Configure PowerDNS API integration
   - Test record sync capabilities

2. **Design IP Address Schema in NetBox**
   - Import existing network segments
   - Define service IP ranges
   - Create VLAN documentation

3. **Ansible NetBox Integration**
   - Configure dynamic inventory
   - Test NetBox modules
   - Create automation playbooks

## 📊 Sprint Metrics

- **Completed This Sprint**: 1/1 (Netdata optimization)
- **In Progress**: 2 (NetBox bootstrap, Vault deployment)
- **Blocked**: 1 (Service identity tokens)
- **Not Started**: 1 (Markdown linting)
- **Overall Project**: 15/34 tasks (44%) - NetBox deployment counted!

## 🔗 Quick Links

- [Task Summary](./task-summary.md) - Project overview
- [Phase 3 Planning](./phases/phase-3-netbox.md) - Next major phase
- [Troubleshooting](../troubleshooting.md) - Known issues
- [Full Task Archive](./archive/full-task-list-2025-08-05.md) - Complete history
