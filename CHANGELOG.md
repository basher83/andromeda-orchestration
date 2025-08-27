# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2025-08-26] - Infrastructure Modernization & Security Hardening

### Changed

- **Complete Migration from Taskfile to Mise**
  - Migrated all development tasks to `.mise.toml` for unified tool management
  - Implemented auto-installation of development tools
  - Added smart caching for improved performance
  - Removed deprecated `Taskfile.yml`
  - Provides consistent cross-platform development experience
  - Fixes #62

- **Domain Parametrization Completion**
  - Completed domain parametrization across all active playbooks
  - Added lint prevention for hardcoded `.local` domains
  - Ensures all services use configurable `homelab_domain` variable
  - Fixes #19, #24

### Removed

- **Complete 1Password Purge**
  - Removed all 1Password Connect documentation and examples
  - Deleted legacy inventory files using 1Password
  - Removed 1Password Ansible plugin and scripts
  - Migration to Infisical for secrets management complete
  - Cleaned up over 1000 lines of deprecated 1Password code

### Security

- **Security Policy and Scanning**
  - Added comprehensive `SECURITY.md` policy document
  - Optimized KICS configuration for improved CI performance
  - Added Infisical secret scanning to development setup
  - Updated pre-commit hooks for security scanning
  - Fixes #82

### Documentation

- **Infrastructure Documentation Consolidation**
  - Consolidated Infisical configuration into single guide
  - Updated CLAUDE.md with accurate infrastructure state
  - Added comprehensive infrastructure repository cross-reference
  - Cleaned up archived documentation

## [2025-08-27] - Security Hardening & Status Check Implementation

### Security

- **Critical Token Removal from Git History**
  - Removed two exposed Nomad tokens from git history
  - Used `uvx git-filter-repo` to clean entire repository history
  - Replaced tokens with `[REDACTED]` placeholders throughout history
  - Updated affected playbooks to use environment variables or Infisical lookups
  - Affected files: `fix-nftables-compatibility.yml`, `update-server-consul-token.yml`

- **Credential Cleanup**
  - Removed hardcoded passwords from archived PostgreSQL job
  - Cleaned up hardcoded credentials in infrastructure playbooks
  - Removed hardcoded tokens from Consul/Nomad integration playbooks
  - Security scan revealed and fixed multiple credential exposures

### Added

- **Three-Tier Project Management System**
  - Implemented Strategic/Tactical/Operational project management tiers
  - Added Architecture Decision Records (ADR) framework with template
  - Created dynamic GitHub badges to eliminate manual date updates
  - Consolidated scattered project docs into organized structure
  - Moved technical documents to appropriate implementation directories

- **Dual-Approach HashiCorp Service Status Checks**
  - Created ADR-2025-08-27 documenting architectural decision for status check strategy
  - Added `playbooks/assessment/quick-status.yml` for authenticated status verification via Infisical
  - Implemented `mise run status:quick` for fast unauthenticated connectivity checks (< 1 second)
  - Implemented `mise run status:full` for comprehensive authenticated checks (~5 seconds)
  - Added individual service checks: `status:consul`, `status:nomad`, `status:vault`

- **Python Environment Compatibility Fix**
  - Downgraded Python from 3.13 to 3.12 for `infisical-python` package compatibility
  - Pinned `infisical-python==2.3.5` (last version with Linux wheels for Python 3.12)
  - Updated `.mise.toml` and `pyproject.toml` with Python version constraints

- **Enhanced Documentation**
  - Added technology badges to README with space exploration visual theme
  - Created comprehensive infrastructure repository cross-reference
  - Restructured inventory with clean archived file organization

### Changed

- **Repository Remote URL**
  - Updated git remote from `netbox-ansible` to `andromeda-orchestration`
  - New repository URL: `https://github.com/basher83/andromeda-orchestration.git`

- **Mise Status Tasks**
  - Fixed logic errors in status checks (was incorrectly reporting "cannot connect" when connected)
  - Changed Consul checks to use `consul members` instead of `consul info` (avoids ACL permission issues)
  - Added clear messaging distinguishing unauthenticated vs authenticated checks
  - Improved error messages with connectivity troubleshooting hints

### Fixed

- **Security Vulnerabilities**
  - `playbooks/infrastructure/docker/fix-nftables-compatibility.yml` - Now uses dynamic token variables
  - `playbooks/infrastructure/nomad/update-server-consul-token.yml` - Now uses environment variable lookup
  - Pre-commit hooks configuration for consistent code quality

### Infrastructure Impact

- **Scope**: Development environment setup and security posture
- **Breaking Change**: Git history rewritten - collaborators must re-clone or rebase
- **Python Requirement**: Now requires Python 3.12 (was 3.13)
- **Security Improvement**: No exposed tokens in repository history

## [2025-08-25] - Vault Production Cluster Deployment

### Added

- **Vault Production Infrastructure**
  - Created dedicated `inventory/vault-cluster/` with production configuration
  - Added 4-node Vault cluster inventory (1 transit master + 3 Raft storage nodes)
  - Implemented `playbooks/infrastructure/vault/configure-production-nodes.yml` for secure deployment
  - Added `playbooks/infrastructure/vault/reset-vault.yml` for cluster reset operations
  - Added `playbooks/infrastructure/vault/unseal-vault.yml` for automated unsealing

- **Security Enhancements**
  - Integrated Infisical for all Vault secrets management (no hardcoded tokens)
  - Implemented token masking in debug output (shows first 8 + last 4 chars only)
  - Added pre-deployment validation for secret availability
  - Transit engine accessibility verification before deployment

- **Documentation**
  - Added Terraform-Ansible cross-reference documentation for Vault deployment
  - Updated DNS deployment status with new domain names

### Changed

- **Vault Deployment Architecture**
  - Migrated from dev mode to production Raft storage backend
  - Implemented auto-unseal using transit engine on master node
  - Configured comprehensive audit logging and telemetry
  - Added systemd service configuration for production stability

### Fixed

- **Pre-commit Configuration**
  - Removed disabled Ansible linting and security checks from `.pre-commit-config.yaml`
  - Restored full security scanning capabilities

### Infrastructure Impact

- **Scope**: Complete Vault cluster replacement (dev → production)
- **Nodes Affected**:
  - vault-master-lloyd (192.168.10.14): Transit engine master
  - vault-prod-1-holly (192.168.10.15): Raft storage node
  - vault-prod-2-mable (192.168.10.16): Raft storage node
  - vault-prod-3-lloyd (192.168.10.17): Raft storage node
- **Security**: Zero secrets exposure, all credentials via Infisical
- **Phase Completion**: Phase 2 of Vault deployment complete

## [2025-08-22] - Domain Migration Completion & Infrastructure Hardening

### Added

- **Comprehensive Troubleshooting Documentation**
  - Created `docs/troubleshooting/ansible-nomad-playbooks.md` - Complete guide for Nomad deployment issues
  - Added `docs/troubleshooting/domain-migration.md` - Domain migration troubleshooting guide
  - Added `docs/troubleshooting/dns-resolution-loops.md` - DNS resolution issue fixes
  - Added `docs/troubleshooting/traefik-external-access.md` - External access configuration guide

- **Assessment and Monitoring Playbooks**
  - `playbooks/assessment/nomad-job-status.yml` - Comprehensive job status reporting with detailed health checks
  - Automated report generation in `reports/nomad/` for tracking deployment status

- **Infrastructure Fix Playbooks**
  - `playbooks/fix/disable-iptables.yml` - Resolve iptables conflicts with Docker/nftables
  - `playbooks/fix/fix-dns-resolution-loop.yml` - Fix DNS resolution loops in infrastructure
  - `playbooks/infrastructure/network/update-nftables-traefik.yml` - Proper nftables configuration for Traefik

- **Mise Environment Management**
  - Implemented environment switching between local (192.168.11.11) and remote/Tailscale (100.108.219.48)
  - Added comprehensive setup tasks (`mise run setup`, `mise run setup:quick`)
  - Created `docs/getting-started/mise-setup-guide.md` - Complete mise integration documentation

### Changed

- **Traefik Load Balancer Hardening**
  - Enhanced `nomad-jobs/core-infrastructure/traefik.nomad.hcl` with improved health checks
  - Added proper DNS resolution configuration for Docker containers
  - Implemented robust service discovery with Consul integration
  - Fixed external access issues with proper entrypoint configuration

- **Nomad Deployment Reliability**
  - Improved `playbooks/infrastructure/nomad/deploy-job.yml` with better error handling
  - Added job validation and planning steps before deployment
  - Enhanced feedback and status reporting during deployments

- **Network Configuration**
  - Updated `roles/system_base/templates/nftables.conf.j2` for better Docker/Traefik compatibility
  - Resolved conflicts between iptables and nftables
  - Ensured proper DNS forwarding for containerized services

### Fixed

- **Domain Migration Issues**
  - Resolved DNS resolution loops affecting service discovery
  - Fixed Traefik external access for spaceships.work domain
  - Corrected Consul DNS forwarding for Docker containers
  - Eliminated iptables/nftables conflicts causing connectivity issues

### Infrastructure Impact

- **Scope**: Complete Traefik redeployment across Nomad cluster
- **Services Affected**: All HTTP/HTTPS ingress traffic routing
- **Migration Status**: Successfully migrated to spaceships.work domain
- **Stability**: Significantly improved with comprehensive health checks and monitoring

### Milestones and Tracking

- Role-first refactor: playbook soup cleanup (Aug 2025) — due 2025-08-31

  - Milestone: <https://github.com/basher83/andromeda-orchestration/milestone/1>
  - Epic: [#17](https://github.com/basher83/andromeda-orchestration/issues/17)
  - Issues: [#10](https://github.com/basher83/andromeda-orchestration/issues/10), [#11](https://github.com/basher83/andromeda-orchestration/issues/11), [#12](https://github.com/basher83/andromeda-orchestration/issues/12), [#13](https://github.com/basher83/andromeda-orchestration/issues/13), [#14](https://github.com/basher83/andromeda-orchestration/issues/14), [#15](https://github.com/basher83/andromeda-orchestration/issues/15), [#16](https://github.com/basher83/andromeda-orchestration/issues/16)

- Migrate lab.local → spaceships.work (High Priority) — due 2025-08-20
  - Milestone: <https://github.com/basher83/andromeda-orchestration/milestone/2>
  - Epic: [#18](https://github.com/basher83/andromeda-orchestration/issues/18)
  - Issues: [#19](https://github.com/basher83/andromeda-orchestration/issues/19), [#20](https://github.com/basher83/andromeda-orchestration/issues/20), [#21](https://github.com/basher83/andromeda-orchestration/issues/21), [#22](https://github.com/basher83/andromeda-orchestration/issues/22), [#23](https://github.com/basher83/andromeda-orchestration/issues/23), [#24](https://github.com/basher83/andromeda-orchestration/issues/24)

## [2025-08-19] - Domain Migration Infrastructure

### Added

- **Domain Migration Support**: Implemented configurable domain infrastructure for homelab environments
  - Added `homelab_domain` variable to group_vars for centralized domain management ([#71](https://github.com/basher83/andromeda-orchestration/pull/71))
  - Introduced HCL2 variable support in Nomad jobs for domain flexibility ([#72](https://github.com/basher83/andromeda-orchestration/pull/72))
  - Updated NetBox DNS playbooks to use configurable domain variables ([#76](https://github.com/basher83/andromeda-orchestration/pull/76))

### Changed

- **CRITICAL MIGRATION**: Infrastructure prepared for domain transition from `.local` to `spaceships.work`
  - All Ansible group variables now use `homelab_domain` variable (default: `spaceships.work`)
  - Nomad jobs converted to HCL2 format with `variable "homelab_domain"` support
  - NetBox DNS discovery and zone creation playbooks updated for dynamic domain configuration
  - PowerDNS configurations made domain-agnostic through variable substitution

### Infrastructure Impact

- **Scope**: Complete infrastructure stack (Ansible, Nomad, NetBox, PowerDNS)
- **Migration Status**: 50% complete (infrastructure ready, service migration pending)
- **Backward Compatibility**: Maintained through configurable domain variables
- **Risk Mitigation**: Gradual rollout enabled via per-environment domain configuration

### Technical Details

- **Variable Implementation**:
  - Ansible: `{{ homelab_domain }}` in all group_vars (og-homelab, doggos-homelab)
  - Nomad: HCL2 variables with `var.homelab_domain` references
  - NetBox: Dynamic zone creation with `{{ homelab_domain }}` templating
- **Files Modified**:
  - `inventory/og-homelab/group_vars/all.yml`
  - `inventory/doggos-homelab/group_vars/all.yml`
  - `nomad-jobs/platform-services/powerdns.nomad.hcl`
  - `playbooks/infrastructure/netbox-dns-discover.yml`
  - `playbooks/infrastructure/netbox-dns-zones.yml`
- **Milestone Progress**: <https://github.com/basher83/andromeda-orchestration/milestone/2> (50% complete)

### Dependencies Updated

- Python updated to v3.13.7 ([#74](https://github.com/basher83/andromeda-orchestration/pull/74))
- markdownlint-cli2 updated to v0.18.1 ([#73](https://github.com/basher83/andromeda-orchestration/pull/73))

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
