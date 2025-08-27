# Domain Migration Implementation Plan: .local → spaceships.work

> **NOTE**: This document has been consolidated into [Domain Migration Master Plan](./domain-migration-master-plan.md)
> Please refer to the master plan for the authoritative implementation approach with sprint breakdown.

---

# Domain Migration Implementation Plan: .local → spaceships.work

**Created**: 2025-01-19
**Status**: Ready for Implementation
**Epic**: [#18](https://github.com/basher83/andromeda-orchestration/issues/18)
**Related PR**: [#70](https://github.com/basher83/andromeda-orchestration/pull/70)

## Executive Summary

Complete migration from `.local` domains to `spaceships.work` across all infrastructure components. This addresses macOS mDNS conflicts and provides a proper domain namespace for the homelab environment.

## Critical Finding

PR #70 attempted to use Ansible Jinja2 syntax (`{{ homelab_domain }}`) in Nomad HCL files, which won't work because the `community.general.nomad_job` module loads HCL files directly without template processing. This plan corrects that approach using Nomad HCL2 variables.

## Implementation Phases

### Phase 1: Variable Creation & Parameterization

#### 1.1 Create homelab_domain Variable

**Files to create/update:**
```yaml
# inventory/doggos-homelab/group_vars/all/main.yml
# inventory/og-homelab/group_vars/all/main.yml
homelab_domain: "spaceships.work"
```

**Rationale**: Central configuration point for domain across all Ansible playbooks.

### Phase 2: Nomad Jobs with HCL2 Variables

#### 2.1 Update Active Nomad Jobs

**File**: `nomad-jobs/core-infrastructure/traefik.nomad.hcl`
```hcl
# Add at top of file
variable "homelab_domain" {
  type    = string
  default = "spaceships.work"
}

# Replace throughout file:
# "lab.local" → "${var.homelab_domain}"
# "*.lab.local" → "*.${var.homelab_domain}"
# "*.doggos.lab.local" → "*.doggos.${var.homelab_domain}"
# "traefik.lab.local" → "traefik.${var.homelab_domain}"
```

**File**: `nomad-jobs/applications/example-app.nomad.hcl`
```hcl
# Add variable declaration
variable "homelab_domain" {
  type    = string
  default = "spaceships.work"
}

# Replace:
# "myapp.lab.local" → "myapp.${var.homelab_domain}"
```

#### 2.2 Update Deployment Playbook

**File**: `playbooks/infrastructure/nomad/deploy-job.yml`
```yaml
# Parse HCL with variables using Nomad API
- name: Parse HCL job with variables
  ansible.builtin.uri:
    url: "{{ nomad_api_endpoint }}/v1/jobs/parse"
    method: POST
    body_format: json
    body:
      JobHCL: "{{ job_spec.content | b64decode }}"
      Variables:
        homelab_domain: "{{ homelab_domain }}"
        cluster_subdomain: "{{ cluster_subdomain | default('') }}"
        fqdn_suffix: "{{ fqdn_suffix | default('') }}"
      Canonicalize: true
  register: parsed_job
  when: job_spec.content | b64decode is search('variable\\s')

# Deploy the parsed job
- name: Deploy job with parsed content
  community.general.nomad_job:
    host: "{{ nomad_api_endpoint | urlsplit('hostname') }}"
    port: "{{ nomad_api_endpoint | urlsplit('port') | default(4646, true) }}"
    use_ssl: "{{ nomad_api_endpoint.startswith('https') }}"
    content: "{{ parsed_job.json | to_json }}"
    content_format: json
    state: present
    force_start: "{{ force_start }}"
  register: deploy_result
  when: parsed_job is defined and parsed_job.json is defined
```

**Note**: The `community.general.nomad_job` module doesn't support NOMAD_VAR_* environment variables. We must use Nomad's /v1/jobs/parse API endpoint to inject variables.

### Phase 3: NetBox DNS Infrastructure

#### 3.1 Zone Setup Migration

**File**: `playbooks/infrastructure/netbox/dns/setup-zones.yml`
```yaml
vars:
  homelab_domain: "{{ homelab_domain | default('spaceships.work') }}"

  nameservers:
    - name: "ns1.{{ homelab_domain }}"
      description: "Primary nameserver for homelab"

  dns_zones:
    forward:
      - name: "{{ homelab_domain }}"
        description: "Primary homelab domain"
      - name: "doggos.{{ homelab_domain }}"
        description: "Doggos cluster domain"
      - name: "og.{{ homelab_domain }}"
        description: "OG homelab cluster domain"
```

#### 3.2 Record Population

**File**: `playbooks/infrastructure/netbox/dns/populate-records.yml`
- Replace all `zone: "homelab.local"` with `zone: "{{ homelab_domain }}"`

#### 3.3 DNS Testing Updates

**File**: `playbooks/infrastructure/netbox/dns/test-dns-resolution.yml`
- Update all test queries from `.homelab.local` to `.{{ homelab_domain }}`

### Phase 4: PowerDNS Configuration

#### 4.1 Sync Configuration

**File**: `playbooks/infrastructure/netbox/dns/sync-to-powerdns.yml`
- Ensure zone synchronization uses parameterized domain

#### 4.2 Integration Updates

**File**: `playbooks/infrastructure/netbox/dns/powerdns-netbox-integration.yml`
- Update any hardcoded domain references

### Phase 5: Consul Configuration

#### 5.1 Service Discovery Clarification

**Important**: Consul's internal `.consul` domain remains unchanged. This is for service discovery only.

**File**: `roles/consul_dns/defaults/main.yml`
```yaml
consul_domain: consul  # This stays as 'consul', NOT changed
```

#### 5.2 External Service References

Any external services registered in Consul should use `{{ homelab_domain }}` for their external DNS names.

### Phase 6: Documentation Updates

Files requiring updates (20+ identified):
- All files in `docs/standards/`
- All files in `docs/operations/`
- All README.md files
- Architecture diagrams
- Example configurations

### Phase 7: CI/CD Prevention

Create `.github/workflows/lint-domains.yml`:
```yaml
name: Domain Linting
on: [pull_request]

jobs:
  check-domains:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Check for .local domains
        run: |
          # Exclude archives and reports
          if grep -r "\.local" \
            --include="*.yml" \
            --include="*.yaml" \
            --include="*.hcl" \
            --exclude-dir=".archive" \
            --exclude-dir="reports" \
            --exclude-dir=".git"; then
            echo "Error: Found .local domain references"
            echo "Please use the homelab_domain variable instead"
            exit 1
          fi
```

## Pull Request Sequence

### PR Strategy
Given the issues identified with PR #70, we will close it and implement via incremental PRs following this sequence:

### PR #1: Foundation - Variable Setup
**Branch**: `feat/homelab-domain-variable`
**Files**:
- `inventory/doggos-homelab/group_vars/all/main.yml`
- `inventory/og-homelab/group_vars/all/main.yml`

**Description**: Create homelab_domain variable with default value "spaceships.work"

### PR #2: Nomad Jobs with HCL2 Variables
**Branch**: `feat/nomad-hcl2-domain-vars`
**Files**:
- `nomad-jobs/core-infrastructure/traefik.nomad.hcl`
- `nomad-jobs/applications/example-app.nomad.hcl`
- `playbooks/infrastructure/nomad/deploy-job.yml`

**Description**: Update Nomad jobs to use HCL2 variables and modify deployment playbook to pass domain variable

### PR #3: NetBox DNS Zone Migration
**Branch**: `feat/netbox-dns-zones-migration`
**Files**:
- `playbooks/infrastructure/netbox/dns/setup-zones.yml`
- `playbooks/infrastructure/netbox/dns/populate-records.yml`
- `playbooks/infrastructure/netbox/dns/test-dns-resolution.yml`

**Description**: Migrate NetBox DNS zones from .local to spaceships.work

### PR #4: PowerDNS Integration Updates
**Branch**: `feat/powerdns-domain-updates`
**Files**:
- `playbooks/infrastructure/netbox/dns/sync-to-powerdns.yml`
- `playbooks/infrastructure/netbox/dns/powerdns-netbox-integration.yml`

**Description**: Update PowerDNS synchronization to use new domain zones

### PR #5: Ansible Playbook Updates
**Branch**: `feat/ansible-playbook-domains`
**Files**:
- All remaining playbooks with .local references
- Consul DNS validation updates

**Description**: Update all remaining Ansible playbooks to use homelab_domain variable

### PR #6: Documentation and CI/CD
**Branch**: `feat/docs-and-linting`
**Files**:
- All documentation files
- `.github/workflows/lint-domains.yml`

**Description**: Update documentation and add CI/CD linting to prevent .local reintroduction

## Implementation Order

Following the PR sequence above:
1. **Day 1**: PR #1 (Foundation) + PR #2 (Nomad)
2. **Day 2**: PR #3 (NetBox zones)
3. **Day 3**: PR #4 (PowerDNS)
4. **Day 4**: PR #5 (Ansible playbooks)
5. **Day 5**: PR #6 (Documentation + CI/CD)

## Testing Strategy

### Pre-Implementation
- [ ] Backup current DNS configuration
- [ ] Document all services using .local
- [ ] Lower DNS TTLs to 60 seconds

### During Implementation
- [ ] Test each service after update
- [ ] Monitor DNS query logs
- [ ] Keep parallel .local zones active

### Post-Implementation
- [ ] Verify all services resolve
- [ ] Test from macOS client
- [ ] Remove .local zones
- [ ] Restore normal TTLs

## Rollback Plan

If issues arise:
1. The `homelab_domain` variable allows instant reversion
2. Keep NetBox .local zones for 7 days post-migration
3. Document old → new domain mappings
4. PowerDNS can serve both zones simultaneously

## Success Criteria

- [ ] Zero .local references in active code
- [ ] All services accessible via spaceships.work
- [ ] macOS clients resolve without mDNS conflicts
- [ ] Consul service discovery unchanged (.consul domain)
- [ ] CI/CD prevents .local reintroduction
- [ ] Documentation updated

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Service outage during migration | Medium | High | Parallel zones, staged rollout |
| DNS caching issues | High | Low | Lower TTLs, document cache clearing |
| Missed .local references | Medium | Medium | Comprehensive grep, CI/CD checks |
| Consul disruption | Low | High | .consul domain unchanged |

## Notes on PR #70

PR #70's approach failed because:
- Used Ansible Jinja2 syntax in Nomad HCL files
- `community.general.nomad_job` doesn't process templates
- HCL files are loaded raw, not rendered

This plan corrects that by:
- Using Nomad HCL2 native variables
- Using Nomad API /v1/jobs/parse endpoint to inject variables
- Maintaining HCL file validity

**Critical Discovery**: The `community.general.nomad_job` module doesn't support NOMAD_VAR_* environment variables. While the Nomad CLI honors these variables, the Ansible module uses the HTTP API directly and requires using the /v1/jobs/parse endpoint with a Variables payload.

## Related Issues

- [#18](https://github.com/basher83/andromeda-orchestration/issues/18): Epic - Domain Migration
- [#19](https://github.com/basher83/andromeda-orchestration/issues/19): Parameterize homelab domain
- [#20](https://github.com/basher83/andromeda-orchestration/issues/20): Consul config updates
- [#21](https://github.com/basher83/andromeda-orchestration/issues/21): NetBox zone migration
- [#22](https://github.com/basher83/andromeda-orchestration/issues/22): PowerDNS/Traefik/Nomad updates
- [#23](https://github.com/basher83/andromeda-orchestration/issues/23): Documentation updates
- [#24](https://github.com/basher83/andromeda-orchestration/issues/24): Lint rule implementation

## Appendix: File Impact Analysis

### Active Infrastructure Files (High Priority)
- 2 Nomad job files (traefik, example-app)
- 18 Ansible playbook files
- 34 Consul-related role files
- 2 inventory group_vars files

### Documentation Files (Medium Priority)
- 20+ markdown files with examples
- README files in various directories

### Archive Files (Low Priority)
- 9 archived Nomad jobs
- Various archived playbooks
- Can be updated for completeness but not critical

## Conclusion

This comprehensive plan addresses all aspects of the domain migration, correcting the technical issues in PR #70 while ensuring a smooth transition from .local to spaceships.work across the entire infrastructure.
