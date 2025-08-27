# Domain Migration Sprint Tracking (ARCHIVED - Planning Document)

> **NOTE**: This was a planning document created in January 2025 that was never executed.
> The actual domain migration work was completed in August 2025.
> See `/docs/project-management/completed/2025-08.md` for the actual implementation details.

**Original Planned Sprint Duration**: January 19-24, 2025
**Epic**: [#18](https://github.com/basher83/andromeda-orchestration/issues/18)
**Status**: ARCHIVED - Work completed in August 2025 instead

## Sprint Schedule

### Day 1 (Jan 19) - Foundation
**Target**: PRs #1 & #2

#### PR #1: homelab_domain Variable
- **Status**: Not Started
- **Assignee**: TBD
- **Time**: 30 minutes

**Checklist**:
- [ ] Fork and create branch `feat/homelab-domain-variable`
- [ ] Create `inventory/doggos-homelab/group_vars/all/main.yml`
- [ ] Create `inventory/og-homelab/group_vars/all/main.yml`
- [ ] Add variable: `homelab_domain: "spaceships.work"`
- [ ] Test: `ansible -m debug -a "var=homelab_domain" all`
- [ ] Create PR with testing evidence
- [ ] Merge after review

#### PR #2: Nomad HCL2 Variables
- **Status**: Not Started
- **Assignee**: TBD
- **Time**: 2 hours
- **Dependencies**: PR #1 merged

**Checklist**:
- [ ] Create branch `feat/nomad-hcl2-domain-vars`
- [ ] Update `traefik.nomad.hcl` with HCL2 variable
- [ ] Update `example-app.nomad.hcl` with HCL2 variable
- [ ] Update `deploy-job.yml` to pass NOMAD_VAR_homelab_domain
- [ ] Validate: `nomad job validate traefik.nomad.hcl`
- [ ] Test deployment with new variable
- [ ] Create PR with test results
- [ ] Deploy to staging after merge

### Day 2 (Jan 20) - NetBox DNS
**Target**: PR #3

#### PR #3: NetBox Zone Migration
- **Status**: Not Started
- **Assignee**: TBD
- **Time**: 3 hours
- **Dependencies**: PR #1 merged

**Pre-flight**:
- [ ] Backup existing NetBox DNS configuration
- [ ] Lower TTLs to 60 seconds on existing zones
- [ ] Document current zone structure

**Implementation**:
- [ ] Create branch `feat/netbox-dns-zones-migration`
- [ ] Update `setup-zones.yml` with parameterized domain
- [ ] Update `populate-records.yml` with variable references
- [ ] Update `test-dns-resolution.yml` for new domain
- [ ] Create spaceships.work zones in NetBox
- [ ] Run parallel with .local zones
- [ ] Test from macOS client
- [ ] Create PR with migration evidence

### Day 3 (Jan 21) - PowerDNS Integration
**Target**: PR #4

#### PR #4: PowerDNS Sync Updates
- **Status**: Not Started
- **Time**: 2 hours
- **Dependencies**: PR #3 merged

**Checklist**:
- [ ] Create branch `feat/powerdns-domain-updates`
- [ ] Update `sync-to-powerdns.yml`
- [ ] Update `powerdns-netbox-integration.yml`
- [ ] Configure zone transfers for new domains
- [ ] Test AXFR/IXFR
- [ ] Verify resolution from clients
- [ ] Create PR with test results

### Day 4 (Jan 22) - Ansible Playbooks
**Target**: PR #5

#### PR #5: Complete Ansible Updates
- **Status**: Not Started
- **Time**: 3 hours
- **Dependencies**: PRs #1-4 merged

**Checklist**:
- [ ] Create branch `feat/ansible-playbook-domains`
- [ ] Find all .local references: `rg '\.local' --type yaml`
- [ ] Update all playbooks to use variable
- [ ] Update role templates
- [ ] Update inventory host_vars
- [ ] Syntax check all playbooks
- [ ] Run check mode on critical playbooks
- [ ] Create PR with comprehensive change list

### Day 5 (Jan 23) - Documentation & CI
**Target**: PR #6

#### PR #6: Documentation and Linting
- **Status**: Not Started
- **Time**: 2 hours
- **Dependencies**: All previous PRs merged

**Checklist**:
- [ ] Create branch `feat/docs-and-linting`
- [ ] Update all documentation files
- [ ] Create `.github/workflows/lint-domains.yml`
- [ ] Add pre-commit hooks for .local detection
- [ ] Update README with migration notes
- [ ] Document macOS mDNS issue
- [ ] Test CI/CD pipeline
- [ ] Create final PR

### Day 6 (Jan 24) - Validation & Cutover
**Target**: Complete migration

**Final Validation**:
- [ ] All services accessible via spaceships.work
- [ ] macOS clients fully functional
- [ ] No .local references in code
- [ ] CI/CD preventing regression
- [ ] Performance metrics normal
- [ ] Decommission .local zones
- [ ] Restore normal TTLs
- [ ] Close Epic #18

## Risk Register

| Risk | Mitigation | Status |
|------|------------|--------|
| PR #70 conflicts | Close PR #70 before starting | Pending |
| Service disruption | Run parallel zones | Planned |
| DNS caching | Lower TTLs, document clearing | Ready |
| Missed references | Comprehensive grep, CI checks | Planned |

## Communication Log

| Date | Message | Audience |
|------|---------|----------|
| Jan 19 AM | Migration starting, PR #70 closed | Team |
| Jan 19 PM | Foundation PRs #1-2 complete | Team |
| Jan 20 AM | NetBox zones migrating | Team |
| Jan 20 PM | Testing needed from macOS | macOS users |
| Jan 24 | Migration complete | All users |

## Metrics

- **PRs Planned**: 6
- **PRs Merged**: 0/6
- **Time Budgeted**: 12.5 hours
- **Time Spent**: 0 hours
- **Issues Resolved**: 0/7 (Epic + 6 sub-issues)
- **Test Coverage**: 0%

## Blockers & Issues

- PR #70 needs to be closed before starting
- Need macOS test environment for validation
- Coordination with PowerDNS deployment team

## Notes

- PR #70 failed due to Jinja2 in HCL files - using HCL2 variables instead
- Keep .local zones running in parallel during migration
- Focus on macOS compatibility testing throughout
- Document all commands for reproducibility
