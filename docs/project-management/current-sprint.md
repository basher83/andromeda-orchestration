# Current Sprint: August 12-19, 2025

**Sprint Focus**: 🚨 CRITICAL domain migration (.local → spaceships.work) and PowerDNS deployment with PostgreSQL

**Previous Sprint**: [August 5-12 Summary](./completed/2025-08.md#august-5-12-sprint)

---

## Navigation: [Task Summary](./task-summary.md) | [Sprint Details](./sprint-2025-08-12.md) | [Critical Migration](./critical-domain-migration.md) | [Phases](./phases/)

## 🚨 Critical Priority

- **Domain Migration** ([Epic #18](https://github.com/basher83/netbox-ansible/issues/18)) — `.local` conflicts with macOS mDNS
  - [Full Migration Plan](./critical-domain-migration.md)
  - **Deadline**: August 20, 2025
  - **Impact**: Blocking macOS developers

## 🚀 Active Tasks

- **PowerDNS Mode A Deployment** (Phase 4) — PostgreSQL backend, Vault integration
  - Issues [#28-32](https://github.com/basher83/netbox-ansible/issues/28): Deploy, configure, health checks
  - [Phase 4: PowerDNS-NetBox Integration](./phases/phase-4-dns-integration.md)
- **NetBox DNS Configuration** — Setup zones with spaceships.work domain
  - Issue [#38](https://github.com/basher83/netbox-ansible/issues/38): Configure forward/reverse zones
  - Issue [#39](https://github.com/basher83/netbox-ansible/issues/39): API connectivity

## ⛔ Blocked Items

- None currently (service identity token issue resolved with workaround)

## ✅ Recently Completed (Last Sprint)

- PostgreSQL deployment with Vault integration (Aug 11)
- NetBox bootstrap and population (Aug 7)
- Vault deployed in dev mode across nomad-server nodes (Aug 6)
- Netdata monitoring optimization (Aug 4)
- Traefik load balancer deployment (Aug 2)

## 📊 Sprint Metrics

- **Sprint Tasks**: 16 (6 critical, 10 high priority)
- **GitHub Issues Active**: 45 open (tracking in GitHub)
- **Completed This Sprint**: 0 (sprint just started)
- **In Progress**: 3
  - Domain migration (6 issues)
  - PowerDNS deployment (5 issues)
  - NetBox zones (2 issues)
- **Blocked**: 0
- **Overall Project**: 17/51 tasks (33%)

## 🔗 Quick Links

- [Sprint Details](./sprint-2025-08-12.md)
- [Critical Domain Migration](./critical-domain-migration.md)
- [GitHub Issues](https://github.com/basher83/netbox-ansible/issues)
- [Phase 4: PowerDNS-NetBox Integration](./phases/phase-4-dns-integration.md)
- [Task Summary](./task-summary.md)
- [Troubleshooting](../getting-started/troubleshooting.md)
