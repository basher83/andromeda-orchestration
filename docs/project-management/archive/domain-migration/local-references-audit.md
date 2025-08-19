# .local References Audit

## Summary
- **Total Files**: 57 files contain `.local` references
- **Total Occurrences**: 195 instances
- **Date**: 2025-08-19

## Status by Component

### 🔴 Critical - Active Components (Needs Immediate Update)

#### Nomad Jobs (Active)
- `nomad-jobs/core-infrastructure/traefik.nomad.hcl` (4 references)
  - Lines 113-116: Certificate domain configuration
  - Line 165: Traefik dashboard host rule
- `nomad-jobs/applications/example-app.nomad.hcl` (1 reference)
  - Example app host rule

#### Ansible Playbooks (Active)
- `playbooks/infrastructure/netbox/netbox-populate-infrastructure.yml` (3 references)
  - DNS names for VMs and interfaces
- `playbooks/infrastructure/netbox/dns/*.yml` (multiple files, ~30 references)
  - Zone configurations
  - DNS record definitions
  - Test queries
- `playbooks/infrastructure/nomad/deploy-traefik.yml` (references in comments/docs)

### 🟡 Medium Priority - Documentation
- `docs/operations/*.md` - Operational guides with examples
- `docs/implementation/*.md` - Implementation docs with examples
- `docs/standards/*.md` - Standards docs with domain examples
- `docs/project-management/*.md` - Planning docs (can remain for historical context)

### 🟢 Low Priority - Archived/Historical
- `nomad-jobs/**/.archive/*.hcl` - Archived job definitions
- `playbooks/infrastructure/.archive/**/*.yml` - Archived playbooks
- `docs/project-management/archive/**/*.md` - Historical planning docs

## Migration Pattern

### For Ansible Playbooks
Replace hardcoded domains with variables:
```yaml
# Before
dns_name: "{{ item.name }}.homelab.local"

# After
dns_name: "{{ item.name }}.{{ homelab_domain }}"
```

### For Nomad Jobs
Use HCL2 variables (**Note: `var.fqdn_suffix` will be introduced in PR #2 - Nomad HCL2 Variables**):
```hcl
# Before
"traefik.http.routers.api.rule=Host(`traefik.lab.local`)"

# After (available after PR #2)
"traefik.http.routers.api.rule=Host(`traefik.${var.fqdn_suffix}`)"
```

### For Documentation
Update examples to use the new domain:
```bash
# Before
dig @192.168.11.20 ns1.homelab.local

# After
dig @192.168.11.20 ns1.spaceships.work
```

## Next Steps

1. ✅ **PR #1: Foundation - Variables defined**
   - Acceptance: Variables available in all inventories, CI passes

2. 🔄 **PR #2: Nomad HCL2 variables**
   - Acceptance: All Nomad jobs use `var.*` variables, `nomad validate` passes

3. ⏳ **PR #3: NetBox zone migration**
   - Acceptance: Zones created for `{{ homelab_domain }}`, NetBox entries verified

4. ⏳ **PR #4: PowerDNS sync updates**
   - Acceptance: Sync job creates/updates zones without drift

5. ⏳ **PR #5: Ansible playbook updates**
   - Acceptance: No hardcoded `.local` in active playbooks, idempotent runs

6. ⏳ **PR #6: Documentation updates**
   - Acceptance: All examples use new domain format, docs reviewed

## Notes
- Many references are in archived files which don't need updating
- Some references in project management docs should remain for historical context
- The migration will be done incrementally across multiple PRs to minimize risk
