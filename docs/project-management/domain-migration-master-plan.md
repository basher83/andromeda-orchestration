# Domain Migration Master Plan: .local → spaceships.work

**Status**: 🚧 IN PROGRESS - 50% Complete
**Epic**: [#18](https://github.com/basher83/andromeda-orchestration/issues/18)
**Created**: 2025-01-19
**Target Completion**: 2025-01-24
**Impact**: Blocking macOS developers due to mDNS conflicts

---

## Executive Summary

Complete migration from `.local` to `spaceships.work` domain across all infrastructure components. The `.local` domain conflicts with macOS mDNS (Bonjour), causing DNS resolution failures for Apple device users.

### Critical Finding from PR #70

PR #70 failed because it used Ansible Jinja2 syntax (`{{ homelab_domain }}`) in Nomad HCL files. The `community.general.nomad_job` module loads HCL files directly without template processing. This plan uses Nomad HCL2 variables instead.

## Sprint Breakdown

### Sprint 1: Foundation & Critical Path (Day 1) ✅ COMPLETE
**Duration**: 4 hours
**PRs**: #71, #72

#### PR #71: Foundation - Variable Setup ✅ MERGED
**Branch**: `feat/homelab-domain-variable`
**Estimated Time**: 30 minutes
**Commit**: 5ecac8d

**Tasks**:
- [x] Create `inventory/doggos-homelab/group_vars/all/main.yml`
- [x] Create `inventory/og-homelab/group_vars/all/main.yml`
- [x] Add `homelab_domain: "spaceships.work"` to both files
- [x] Test variable resolution: `ansible -m debug -a "var=homelab_domain" all`

**Success Criteria**:
- Variable accessible from all playbooks
- Default value properly set
- No breaking changes to existing playbooks

#### PR #72: Nomad Jobs with HCL2 Variables ✅ MERGED
**Branch**: `feat/nomad-hcl2-domain-vars`
**Estimated Time**: 2 hours
**Commit**: 260486a
**Dependencies**: PR #71 merged

**Implementation Checklist**:

1. **Update Traefik Job** (`nomad-jobs/core-infrastructure/traefik.nomad.hcl`):
   ```hcl
   # Add at top
   variable "homelab_domain" {
     type    = string
     default = "spaceships.work"
   }
   ```
   - [x] Replace all `lab.local` with `${var.homelab_domain}`
   - [x] Replace all `*.lab.local` with `*.${var.homelab_domain}`
   - [x] Replace all `*.doggos.lab.local` with `*.doggos.${var.homelab_domain}`
   - [x] Replace all `traefik.lab.local` with `traefik.${var.homelab_domain}`

2. **Update Example App** (`nomad-jobs/applications/example-app.nomad.hcl`):
   - [x] Add variable declaration
   - [x] Replace domain references

3. **Update Deployment Playbook** (`playbooks/infrastructure/nomad/deploy-job.yml`):
   - [x] Use Nomad API /v1/jobs/parse endpoint to inject variables
   - [x] Parse HCL with Variables payload (not NOMAD_VAR_* env vars)
   - [x] Default to spaceships.work if not set

**Testing Commands**:
```bash
# Validate HCL syntax
nomad job validate nomad-jobs/core-infrastructure/traefik.nomad.hcl

# Test deployment with variable (CLI supports NOMAD_VAR_*)
NOMAD_VAR_homelab_domain=spaceships.work nomad job plan traefik.nomad.hcl

# Deploy via playbook (uses API parsing, not env vars)
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-traefik.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

**Important**: The `community.general.nomad_job` module doesn't support NOMAD_VAR_* environment variables. The playbook uses Nomad's /v1/jobs/parse API endpoint instead.

**Rollback Plan**:
- Keep backup of original HCL files
- Variable defaults allow instant reversion
- Test in dev environment first

### Sprint 2: NetBox DNS Infrastructure (Day 2) ✅ COMPLETE
**Duration**: 3 hours
**PR**: #76

#### PR #76: NetBox DNS Zone Migration ✅ MERGED
**Branch**: `feat/netbox-dns-zones-migration`
**Estimated Time**: 3 hours
**Commit**: 9567b22
**Dependencies**: PR #71 merged

**Pre-Implementation Tasks**:
- [x] Backup existing NetBox DNS zones (archived to playbooks/.archive/)
- [x] Document current .local zones
- [x] Lower TTLs to 60 seconds

**Implementation Checklist**:

1. **Zone Setup** (`playbooks/infrastructure/netbox/dns/setup-zones.yml`):
   - [x] Update nameserver references to use `{{ homelab_domain }}`
   - [x] Create spaceships.work forward zone
   - [x] Create doggos.spaceships.work forward zone
   - [x] Create og.spaceships.work forward zone
   - [x] Create reverse zones for all subnets

2. **Record Population** (`playbooks/infrastructure/netbox/dns/populate-records.yml`):
   - [x] Replace all `zone: "homelab.local"` with `zone: "{{ homelab_domain }}"`
   - [x] Update all FQDN references
   - [x] Ensure PTR records point to new domain

3. **Testing Updates** (`playbooks/infrastructure/netbox/dns/test-dns-resolution.yml`):
   - [x] Update test queries to new domain
   - [x] Add parallel testing for both domains
   - [x] Include macOS-specific tests

**Testing Commands**:
```bash
# Create new zones
uv run ansible-playbook playbooks/infrastructure/netbox/dns/setup-zones.yml

# Verify zones in NetBox
curl -H "Authorization: Token $NETBOX_TOKEN" \
  https://192.168.30.213/api/plugins/netbox-dns/zones/

# Test resolution
dig @192.168.10.11 traefik.spaceships.work
nslookup traefik.spaceships.work 192.168.10.11
```

**Success Criteria**:
- All zones created in NetBox
- Records properly populated
- Both old and new zones active (parallel running)
- No service disruptions

### Sprint 3: PowerDNS Integration (Day 3)
**Duration**: 2 hours
**PR**: #4

#### PR #4: PowerDNS Integration Updates
**Branch**: `feat/powerdns-domain-updates`
**Estimated Time**: 2 hours
**Dependencies**: PR #3 merged

**Implementation Checklist**:

1. **Sync Configuration** (`playbooks/infrastructure/netbox/dns/sync-to-powerdns.yml`):
   - [ ] Update zone sync to include new domains
   - [ ] Ensure AXFR/IXFR for both old and new zones
   - [ ] Configure zone priorities

2. **Integration Updates** (`playbooks/infrastructure/netbox/dns/powerdns-netbox-integration.yml`):
   - [ ] Update API endpoints
   - [ ] Configure zone metadata
   - [ ] Set up NOTIFY for zone changes

**Testing Commands**:
```bash
# Sync zones to PowerDNS
uv run ansible-playbook playbooks/infrastructure/netbox/dns/sync-to-powerdns.yml

# Verify zones in PowerDNS
pdnsutil list-all-zones
pdnsutil show-zone spaceships.work

# Test AXFR
dig @192.168.10.11 spaceships.work AXFR

# Verify from macOS client
dscacheutil -q host -a name traefik.spaceships.work
```

**Success Criteria**:
- PowerDNS serving new zones
- Zone transfers working
- API sync operational
- Both domains resolving

### Sprint 4: Ansible & Service Updates (Day 4)
**Duration**: 3 hours
**PR**: #5

#### PR #5: Ansible Playbook Updates
**Branch**: `feat/ansible-playbook-domains`
**Estimated Time**: 3 hours
**Dependencies**: PRs #1-4 merged

**Implementation Checklist**:

1. **Playbook Updates**:
   - [ ] Update all hardcoded .local references
   - [ ] Fix inventory references
   - [ ] Update role defaults
   - [ ] Fix template files

2. **Consul Configuration**:
   - [ ] Verify .consul domain unchanged
   - [ ] Update external service registrations
   - [ ] Fix health check URLs

**File List** (from grep analysis):
```bash
# Files with .local references
playbooks/infrastructure/powerdns/README.md
playbooks/assessment/*.yml
roles/*/templates/*.j2
inventory/*/host_vars/*.yml
```

**Testing Commands**:
```bash
# Find remaining .local references
rg '\.local' --type yaml --type j2

# Test playbook syntax
uv run ansible-playbook --syntax-check playbooks/site.yml

# Dry run critical playbooks
uv run ansible-playbook playbooks/infrastructure/site.yml --check
```

### Sprint 5: Documentation & Prevention (Day 5)
**Duration**: 2 hours
**PR**: #6

#### PR #6: Documentation and CI/CD
**Branch**: `feat/docs-and-linting`
**Estimated Time**: 2 hours
**Dependencies**: All previous PRs merged

**Implementation Checklist**:

1. **Documentation Updates**:
   - [ ] Update all markdown files
   - [ ] Fix examples in READMEs
   - [ ] Add migration notes
   - [ ] Document macOS mDNS issue

2. **CI/CD Linting** (`.github/workflows/lint-domains.yml`):
   - [ ] Create workflow file
   - [ ] Add grep checks for .local
   - [ ] Configure exceptions
   - [ ] Test on PR

**Testing**:
```bash
# Test linting locally
grep -r '\.local' \
  --include="*.yml" \
  --include="*.yaml" \
  --include="*.hcl" \
  --exclude-dir=".archive" \
  --exclude-dir="reports"
```

## Risk Assessment & Mitigation

| Risk | Likelihood | Impact | Mitigation Strategy |
|------|------------|--------|--------------------|
| Service outage during migration | Medium | High | Parallel zones, staged rollout, off-hours deployment |
| DNS caching issues | High | Low | Lower TTLs to 60s, document cache clearing |
| Missed .local references | Medium | Medium | Comprehensive grep, CI/CD checks, code review |
| Consul disruption | Low | High | .consul domain unchanged, separate from migration |
| Nomad job failures | Low | Medium | HCL2 variables tested, rollback via variables |
| macOS resolution failures | Low | High | Test from macOS throughout migration |

## Validation Checklist

### Per-Sprint Validation

**Sprint 1**: ✅ COMPLETE
- [x] Variables accessible in all inventories
- [x] Nomad jobs deploy with new domain
- [x] Traefik routing functional

**Sprint 2**: ✅ COMPLETE
- [x] NetBox zones created
- [x] Records populated
- [x] API accessible

**Sprint 3**:
- [ ] PowerDNS serving zones
- [ ] Zone transfers working
- [ ] Sync operational

**Sprint 4**:
- [ ] All playbooks updated
- [ ] Services accessible
- [ ] Consul unchanged

**Sprint 5**:
- [ ] Documentation complete
- [ ] CI/CD preventing regression
- [ ] Migration guide published

### Final Validation

- [ ] Zero .local references in active code
- [ ] All services resolve via spaceships.work
- [ ] macOS clients working without issues
- [ ] Consul service discovery intact
- [ ] Monitoring shows no DNS failures
- [ ] Performance metrics unchanged

## Rollback Procedures

### Quick Rollback (< 5 minutes)
1. Change `homelab_domain` variable back to "lab.local"
2. Redeploy affected Nomad jobs
3. Services immediately revert

### Full Rollback (< 30 minutes)
1. Restore NetBox zones from backup
2. Sync original zones to PowerDNS
3. Revert all PR changes
4. Clear DNS caches

## Communication Plan

### Stakeholder Notifications

**T-24 hours**:
- Announce maintenance window
- Share testing instructions
- Provide cache clearing commands

**T-1 hour**:
- Final reminder
- Share status page link
- Confirm rollback plan

**During Migration**:
- Update status every 30 minutes
- Report any issues immediately
- Provide workarounds if needed

**Post-Migration**:
- Confirm completion
- Share new domain information
- Request testing feedback

## Commands Reference

### DNS Testing
```bash
# Test from macOS
dscacheutil -q host -a name service.spaceships.work
dig @192.168.10.11 service.spaceships.work
nslookup service.spaceships.work

# Clear macOS DNS cache
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Test from Linux
dig @192.168.10.11 service.spaceships.work
host service.spaceships.work 192.168.10.11
```

### Monitoring
```bash
# Watch DNS queries
tcpdump -i any -n port 53

# Check PowerDNS logs
journalctl -u powerdns -f

# Monitor Nomad jobs
nomad job status
```

### Verification
```bash
# Find .local references
rg '\.local' --type-not md

# Check variable usage
ansible all -m debug -a "var=homelab_domain"

# Validate HCL files
find nomad-jobs -name "*.hcl" -exec nomad job validate {} \;
```

## Success Metrics

- **Downtime**: < 5 minutes per service
- **Migration Time**: < 5 days total
- **DNS Resolution**: 100% success rate
- **macOS Compatibility**: Full functionality
- **Rollback Time**: < 30 minutes if needed

## Related Documentation

- [GitHub Epic #18](https://github.com/basher83/andromeda-orchestration/issues/18)
- [Phase 4: DNS Integration](./phases/phase-4-dns-integration.md)
- [Infrastructure Standards](../standards/infrastructure-standards.md)
- [PowerDNS Architecture](../implementation/powerdns/deployment-architecture.md)
- [NetBox Integration Patterns](../implementation/dns-ipam/netbox-integration-patterns.md)

---

**Note**: This consolidated plan supersedes both `critical-domain-migration.md` and `domain-migration-implementation.md`. Archive those files after this migration is complete.
