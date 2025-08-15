# CRITICAL: Domain Migration from .local to spaceships.work

**Status**: 🚨 Critical Priority - Blocking Issue
**Epic**: GitHub Issue [#18](https://github.com/basher83/netbox-ansible/issues/18)
**Impact**: Affects all macOS developers and DNS resolution
**Target Completion**: August 20, 2025

## Problem Statement

- `.local` domain conflicts with macOS mDNS (Bonjour)
- Causes DNS resolution failures for macOS developers
- Hardcoded throughout codebase (playbooks, docs, Nomad jobs, configs)
- Prevents proper DNS functionality on Apple devices

## Task Checklist (Execute in Order)

### Phase 1: Parameterization

- [ ] [#19](https://github.com/basher83/netbox-ansible/issues/19): Create `homelab_domain` variable (default: spaceships.work)
  - Add to group_vars/all
  - Update role defaults
  - Ensure all playbooks use variable

### Phase 2: Service Configuration

- [ ] [#20](https://github.com/basher83/netbox-ansible/issues/20): Update Consul config to remove .local usage
  - Review roles/consul_dns/*
  - Update consul-resolved.conf.j2
  - Ensure only .consul domain for service discovery

### Phase 3: DNS Migration

- [ ] [#21](https://github.com/basher83/netbox-ansible/issues/21): Migrate NetBox zones from *.local to spaceships.work
  - Create new zones first
  - Copy records to new zones
  - Update NS/SOA records
  - Remove old zones after validation

### Phase 4: Infrastructure Updates

- [ ] [#22](https://github.com/basher83/netbox-ansible/issues/22): Update PowerDNS + Traefik + Nomad host rules
  - Update all Nomad job files
  - Fix Traefik host rules
  - Update TLS SANs

### Phase 5: Documentation

- [ ] [#23](https://github.com/basher83/netbox-ansible/issues/23): Update all documentation and examples
  - Replace .local references in docs/
  - Update README.md and ROADMAP.md
  - Add note explaining macOS mDNS conflict

### Phase 6: Prevention

- [ ] [#24](https://github.com/basher83/netbox-ansible/issues/24): Add lint rule to prevent .local reintroduction
  - Create CI check for .local usage
  - Document exceptions (historical references)
  - Fail PRs that introduce new .local references

## Implementation Notes

### Testing Strategy

1. Test changes in isolated environment first
2. Validate DNS resolution at each step
3. Keep Pi-hole running as fallback during transition
4. Monitor for failed lookups

### Rollback Plan

1. Variables allow quick reversion to .local if needed
2. Keep backup of NetBox zones before migration
3. Document old -> new mappings

### Risk Mitigation

- **Service Outages**: Stage changes during maintenance window
- **DNS Propagation**: Lower TTLs before migration
- **Client Caching**: Document cache clearing procedures
- **Monitoring**: Watch DNS query logs for failures

## Verification Checklist

- [ ] No .local references in code (except documented exceptions)
- [ ] All services resolve via spaceships.work
- [ ] macOS clients can resolve all services
- [ ] Consul service discovery still works (.consul domain)
- [ ] NetBox zones properly configured
- [ ] PowerDNS serving new zones
- [ ] Traefik routing working with new domains
- [ ] CI/CD prevents .local reintroduction

## Related Documentation

- [Phase 4: DNS Integration](./phases/phase-4-dns-integration.md)
- [Infrastructure Standards](../standards/infrastructure-standards.md)
- [DNS Deployment Status](../operations/dns-deployment-status.md)
- [Assessment Report](../../reports/assessment/phase0-assessment-summary-2025-07-27.md)

## Files Affected (Sample)

Based on grep results, approximately 20+ files contain .local references:

- playbooks/infrastructure/powerdns/README.md
- nomad-jobs/platform-services/README.md
- nomad-jobs/core-infrastructure/README.md
- docs/standards/*.md
- docs/operations/*.md
- docs/implementation/**/*.md
- Various job files and templates

## Success Criteria

1. Zero .local references in active code/configs
2. All services accessible via spaceships.work domain
3. No DNS resolution issues on macOS
4. Lint rules preventing regression
5. Documentation clearly explaining the change
