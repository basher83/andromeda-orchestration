# GitHub Issue Tracker

**Repository**: [basher83/netbox-ansible](https://github.com/basher83/netbox-ansible)
**Open Issues**: 48
**Last Updated**: 2025-08-15

---

## Navigation: [Current Sprint](./current-sprint.md) | [Task Summary](./task-summary.md) | [Phases](./phases/)

## 🚨 Critical Priority (Immediate Action Required)

### Domain Migration Epic ([#18](https://github.com/basher83/netbox-ansible/issues/18))

**Impact**: Blocking macOS developers due to .local mDNS conflict
**Deadline**: August 20, 2025
**Status**: Active Sprint

| Issue | Title | Status |
|-------|-------|--------|
| [#19](https://github.com/basher83/netbox-ansible/issues/19) | Parametrize homelab domain (default: spaceships.work) | 🔴 Not Started |
| [#20](https://github.com/basher83/netbox-ansible/issues/20) | Consul config: remove .local usage | 🔴 Not Started |
| [#21](https://github.com/basher83/netbox-ansible/issues/21) | NetBox: rename zones from *.local → spaceships.work | 🔴 Not Started |
| [#22](https://github.com/basher83/netbox-ansible/issues/22) | PowerDNS + Traefik: switch host rules to spaceships.work | 🔴 Not Started |
| [#23](https://github.com/basher83/netbox-ansible/issues/23) | Docs: replace .local with spaceships.work | 🔴 Not Started |
| [#24](https://github.com/basher83/netbox-ansible/issues/24) | Add lint rule to block new .local usage | 🔴 Not Started |

## 🔥 High Priority (Current Sprint - Phase 4)

### PowerDNS-NetBox Integration ([#27](https://github.com/basher83/netbox-ansible/issues/27))

**Target**: August 12-19, 2025
**Prerequisites**: PostgreSQL ✅ Deployed

#### Infrastructure Setup

| Issue | Title | Status |
|-------|-------|--------|
| [#28](https://github.com/basher83/netbox-ansible/issues/28) | Deploy PowerDNS with PostgreSQL backend | 🟡 In Progress |
| [#29](https://github.com/basher83/netbox-ansible/issues/29) | Expose DNS :53 and API ports | 🔴 Not Started |
| [#30](https://github.com/basher83/netbox-ansible/issues/30) | Register Consul services | 🔴 Not Started |
| [#31](https://github.com/basher83/netbox-ansible/issues/31) | Configure Traefik routing for API | 🔴 Not Started |
| [#32](https://github.com/basher83/netbox-ansible/issues/32) | Add health checks | 🔴 Not Started |

#### NetBox Integration

| Issue | Title | Status |
|-------|-------|--------|
| [#38](https://github.com/basher83/netbox-ansible/issues/38) | Configure forward/reverse zones in NetBox | 🔴 Not Started |
| [#39](https://github.com/basher83/netbox-ansible/issues/39) | PowerDNS ←→ NetBox API connectivity | 🔴 Not Started |
| [#40](https://github.com/basher83/netbox-ansible/issues/40) | Implement sync script and webhooks | 🔴 Not Started |

#### Migration & Testing

| Issue | Title | Status |
|-------|-------|--------|
| [#41](https://github.com/basher83/netbox-ansible/issues/41) | Migrate DNS records from Pi-hole | 🔴 Not Started |
| [#42](https://github.com/basher83/netbox-ansible/issues/42) | Functional testing - lookups | 🔴 Not Started |
| [#43](https://github.com/basher83/netbox-ansible/issues/43) | Zone transfers configuration | 🔴 Not Started |

#### Production Readiness

| Issue | Title | Status |
|-------|-------|--------|
| [#33](https://github.com/basher83/netbox-ansible/issues/33) | Scale to HA (count=2) | 🔴 Not Started |
| [#34](https://github.com/basher83/netbox-ansible/issues/34) | Decommission MariaDB prototype | 🔴 Not Started |
| [#35](https://github.com/basher83/netbox-ansible/issues/35) | Migrate prototype data | 🔴 Not Started |
| [#36](https://github.com/basher83/netbox-ansible/issues/36) | Verify DNS resolution | 🔴 Not Started |
| [#37](https://github.com/basher83/netbox-ansible/issues/37) | Update runbooks to Mode A | 🔴 Not Started |

## 🟡 Medium Priority (Next Sprint)

### Code Quality & Linting Epic ([#63](https://github.com/basher83/netbox-ansible/issues/63))

**Goal**: Fix 391 ansible-lint violations and achieve production-ready code quality

| Issue | Title | Priority |
|-------|-------|----------|
| [#62](https://github.com/basher83/netbox-ansible/issues/62) | Install missing linting tools (nomad, terraform) | High |
| [#63](https://github.com/basher83/netbox-ansible/issues/63) | Ansible FQCN Migration - Fix 391 violations | High |
| [#64](https://github.com/basher83/netbox-ansible/issues/64) | Progressive linting strategy with profiles | Medium |
| [#65](https://github.com/basher83/netbox-ansible/issues/65) | Enhance pre-commit hooks | Medium |

### Architecture Refactoring Epic ([#17](https://github.com/basher83/netbox-ansible/issues/17))

**Goal**: Reduce playbook complexity through role-first architecture

| Issue | Title | Priority |
|-------|-------|----------|
| [#10](https://github.com/basher83/netbox-ansible/issues/10) | Create thin orchestrator playbooks | Medium-High |
| [#11](https://github.com/basher83/netbox-ansible/issues/11) | Introduce roles/powerdns | Medium-High |
| [#12](https://github.com/basher83/netbox-ansible/issues/12) | Refactor Consul playbooks | Medium-High |
| [#13](https://github.com/basher83/netbox-ansible/issues/13) | Create consul_nomad integration role | Medium-High |
| [#14](https://github.com/basher83/netbox-ansible/issues/14) | Standardize monitoring on netdata roles | Medium-High |
| [#15](https://github.com/basher83/netbox-ansible/issues/15) | Add ansible-lint enforcement | Medium-High |
| [#16](https://github.com/basher83/netbox-ansible/issues/16) | Update docs to role-first | Medium-High |

### Enhancements

| Issue | Title | Priority |
|-------|-------|----------|
| [#26](https://github.com/basher83/netbox-ansible/issues/26) | Integrate PowerDNS-Admin UI | Medium |
| [#46](https://github.com/basher83/netbox-ansible/issues/46) | Add milestone checklist to Phase 4 | Low |

## 🔵 Low Priority (Future - Phase 5)

### Multi-Site Expansion Epic ([#47](https://github.com/basher83/netbox-ansible/issues/47))

**Target**: Q4 2025
**Prerequisites**: Phase 4 Complete

| Issue | Title | Category |
|-------|-------|----------|
| [#48](https://github.com/basher83/netbox-ansible/issues/48) | Plan Multi-Site DNS Strategy | Planning |
| [#49](https://github.com/basher83/netbox-ansible/issues/49) | Deploy Consul to og-homelab | Infrastructure |
| [#50](https://github.com/basher83/netbox-ansible/issues/50) | Cross-datacenter replication | Infrastructure |
| [#51](https://github.com/basher83/netbox-ansible/issues/51) | Deploy PowerDNS at each site | Infrastructure |
| [#52](https://github.com/basher83/netbox-ansible/issues/52) | Implement GeoDNS | Enhancement |
| [#53](https://github.com/basher83/netbox-ansible/issues/53) | Security hardening | Security |
| [#54](https://github.com/basher83/netbox-ansible/issues/54) | Performance optimization | Performance |
| [#55](https://github.com/basher83/netbox-ansible/issues/55) | Disaster recovery plan | Operations |
| [#56](https://github.com/basher83/netbox-ansible/issues/56) | Advanced automation | Automation |

## 📊 Issue Metrics by Status

| Status | Count | Percentage |
|--------|-------|------------|
| 🔴 Not Started | 43 | 90% |
| 🟡 In Progress | 5 | 10% |
| 🟢 Completed | 0 | 0% |
| ⚪ Blocked | 0 | 0% |

## 📊 Issue Metrics by Priority

| Priority | Count | Issues |
|----------|-------|--------|
| Critical | 6 | Domain migration (#19-24) |
| High | 19 | PowerDNS Phase 4 (#28-43), Linting tools (#62-63) |
| Medium | 17 | Refactoring (#10-16), Linting (#64-65), Enhancements |
| Low | 6 | Phase 5 planning, future work |

## 🏷️ Issue Labels

### Priority Labels

- `🟡 priority-medium`: Important but not urgent
- `🚧 in-progress`: Currently being worked on

### Category Labels

- `🔧 crew-devops`: Infrastructure and DevOps
- `📚 documentation`: Documentation improvements
- `✨ enhancement`: New features
- `🧹 refactor`: Code improvements
- `🔒 security`: Security-related
- `⚡ performance`: Performance optimization
- `📊 monitoring`: Monitoring and observability
- `🔧 config`: Configuration related
- `🧪 testing`: Testing related
- `🏔️ effort-epic`: Major undertaking (3+ days)

## 🔗 Quick Links

- [All Open Issues](https://github.com/basher83/netbox-ansible/issues)
- [Domain Migration Milestone](https://github.com/basher83/netbox-ansible/milestone/2)
- [Phase 4 Epic](https://github.com/basher83/netbox-ansible/issues/27)
- [Phase 5 Epic](https://github.com/basher83/netbox-ansible/issues/47)
- [Refactoring Epic](https://github.com/basher83/netbox-ansible/issues/17)
- [Code Quality Epic](https://github.com/basher83/netbox-ansible/issues/63)

## 📝 Notes

1. **Domain Migration is CRITICAL** - Must be completed by August 20 to unblock macOS developers
2. **PowerDNS deployment** depends on PostgreSQL (✅ already deployed)
3. **Zone configuration** must use spaceships.work, NOT .local
4. **Refactoring** can proceed in parallel but lower priority than Phase 4
5. **Phase 5** planning can begin but execution waits for Phase 4 completion
