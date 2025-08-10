# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Milestones and Tracking

- Role-first refactor: playbook soup cleanup (Aug 2025) — due 2025-08-31

  - Milestone: https://github.com/basher83/andromeda-orchestration/milestone/1
  - Epic: [#17](https://github.com/basher83/andromeda-orchestration/issues/17)
  - Issues: [#10](https://github.com/basher83/andromeda-orchestration/issues/10), [#11](https://github.com/basher83/andromeda-orchestration/issues/11), [#12](https://github.com/basher83/andromeda-orchestration/issues/12), [#13](https://github.com/basher83/andromeda-orchestration/issues/13), [#14](https://github.com/basher83/andromeda-orchestration/issues/14), [#15](https://github.com/basher83/andromeda-orchestration/issues/15), [#16](https://github.com/basher83/andromeda-orchestration/issues/16)

- Migrate lab.local → spaceships.work (High Priority) — due 2025-08-20
  - Milestone: https://github.com/basher83/andromeda-orchestration/milestone/2
  - Epic: [#18](https://github.com/basher83/andromeda-orchestration/issues/18)
  - Issues: [#19](https://github.com/basher83/andromeda-orchestration/issues/19), [#20](https://github.com/basher83/andromeda-orchestration/issues/20), [#21](https://github.com/basher83/andromeda-orchestration/issues/21), [#22](https://github.com/basher83/andromeda-orchestration/issues/22), [#23](https://github.com/basher83/andromeda-orchestration/issues/23), [#24](https://github.com/basher83/andromeda-orchestration/issues/24)

## [2025-08-10] - Consul ACL Integration Fix

### Fixed

- **CRITICAL**: Fixed Nomad job templating with Consul KV store access
  - Resolved "Template failed: Permission denied" errors for jobs using `{{ key "path/to/key" }}` syntax
  - Root cause: Missing `key_prefix` read permissions in Consul ACL policies for Nomad agents
  - Affected service: PowerDNS deployment and any Nomad job using Consul KV templating

### Added

- Enhanced Nomad role with automated Consul ACL integration
  - New policy templates: `roles/nomad/files/consul-policies/nomad-server.hcl`, `nomad-client.hcl`
  - Automated ACL management: `roles/nomad/tasks/consul-acl.yml`
  - Dynamic token assignment in Nomad configuration templates
- Infrastructure playbooks for ACL policy management
  - `playbooks/infrastructure/consul-nomad/update-nomad-client-acl-kv.yml`
  - `playbooks/infrastructure/consul-nomad/update-all-nomad-acl-policies.yml`

### Changed

- Updated `nomad-server` and `nomad-client` Consul ACL policies to include KV read access
- Enhanced Nomad configuration template (`roles/nomad/templates/nomad.hcl.j2`) with proper Consul integration
- Nomad role now supports comprehensive Consul ACL token management

### Infrastructure Impact

- **Scope**: All 6 Nomad nodes (3 servers + 3 clients) across the cluster
- **Verification**: All nodes confirmed healthy with proper ACL permissions
- **Backward Compatibility**: Existing Nomad jobs continue to work without changes
- **New Capability**: All Nomad jobs can now use Consul KV templating

### Technical Details

- **ACL Policies Updated**: `nomad-server`, `nomad-client`
- **Permission Added**: `key_prefix "" { policy = "read" }`
- **Management Method**: Infrastructure as Code through Ansible playbooks
- **Token Source**: Infisical integration (`/apollo-13/consul/CONSUL_MASTER_TOKEN`)

---

_This changelog tracks significant infrastructure changes, role enhancements, and operational fixes._
