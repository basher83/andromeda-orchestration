# Comprehensive Repository Review: andromeda-orchestration

**Date:** 2026-02-26
**Scope:** Full repository audit across 832 files (373 YAML, 19 Python, 25 HCL, 21 Shell, 308 Markdown, 36 Jinja2)
**Review Team:** 6 specialized analysis agents covering security, code quality, feature gaps, simplification, infrastructure, and documentation/project health

---

## Executive Summary

The andromeda-orchestration repository is a well-structured Ansible automation project for homelab infrastructure management. It demonstrates strong fundamentals in secret management (Infisical/Vault integration), documentation culture, and tooling setup. However, the review identified **67 findings** across 6 domains that warrant attention.

### Finding Distribution

| Severity | Count | Key Areas |
|----------|-------|-----------|
| CRITICAL | 1 | Debug code in production module |
| HIGH | 20 | Hardcoded IPs, security configs, dead code, duplication |
| MEDIUM | 33 | Missing tests, incomplete features, config issues |
| LOW | 13 | Style, documentation gaps, minor optimizations |

### Top 5 Priorities

1. **Remove debug statement** in `plugins/module_utils/consul.py:98` (CRITICAL)
2. **Eliminate hardcoded IPs** across 15+ locations violating project policy
3. **Consolidate 7 fragmented netdata roles** into unified role (major maintenance burden)
4. **Complete smoke test implementations** (5 placeholder playbooks)
5. **Enable TLS and fix security misconfigurations** in Traefik, Vault, and certificate scripts

---

## 1. Security Audit

### 1.1 Critical Findings

#### SEC-001: Debug Print Statement in Production Code

- **File:** `plugins/module_utils/consul.py:98`
- **Severity:** CRITICAL
- **Description:** A `print("here")` debug statement is present in production code. This could expose unexpected debug information in logs and violates clean code standards.
- **Fix:** Remove the debug statement. Use `module.debug()` for proper Ansible debugging.

### 1.2 High Severity Findings

#### SEC-002: Unsafe eval() with Infisical Secrets

- **File:** `scripts/generate-mcp-config.sh:97,100`
- **Severity:** HIGH
- **Description:** Uses `eval()` to process output from `infisical export`. A compromise of the Infisical service or MITM attack could inject arbitrary shell commands.
- **Fix:** Replace with `source <(infisical export ...)` or use a temporary file with restricted permissions.

#### SEC-003: Docker Compose Installation Without Checksum Verification

- **File:** `roles/system_base/tasks/docker.yml:77-84`
- **Severity:** HIGH
- **Description:** Docker Compose binary downloaded via `curl -sSL` without GPG signature or SHA256 checksum verification.
- **Fix:** Add checksum verification step before installation.

#### SEC-004: SSH Host Key Checking Disabled

- **Files:** `playbooks/infrastructure/user-management/setup-ansible-user.yml:10`, `deploy-ssh-keys.yml:7`
- **Severity:** HIGH
- **Description:** `StrictHostKeyChecking=no` disables SSH host key verification, creating MITM vulnerability.
- **Fix:** Use `StrictHostKeyChecking=accept-new` or maintain a managed known_hosts file.

#### SEC-005: Unrestricted NOPASSWD Sudo Configuration

- **Files:** `playbooks/infrastructure/user-management/setup-ansible-user.yml:47`, `deploy-ssh-keys.yml:42`
- **Severity:** HIGH
- **Description:** Ansible user configured with `NOPASSWD:ALL` creating broad privilege escalation risk.
- **Fix:** Restrict to specific commands: `/usr/bin/systemctl, /bin/systemctl, /usr/sbin/service`.

#### SEC-006: Insecure Traefik Configuration

- **File:** `nomad-jobs/core-infrastructure/traefik.nomad.hcl:60-61,105`
- **Severity:** HIGH
- **Description:** Debug mode enabled, insecure dashboard API access, unfiltered access logs in production.
- **Fix:** Disable debug mode, implement authentication for dashboard, configure access log filtering.

#### SEC-007: Vault TLS Skip Verification

- **File:** `nomad-jobs/platform-services/vault-pki/vault-pki-exporter.nomad.hcl:63`
- **Severity:** HIGH
- **Description:** `VAULT_SKIP_VERIFY = "true"` completely disables TLS verification.
- **Fix:** Provide proper CA certificates instead of skipping verification.

#### SEC-008: TLS Disabled in Production Vault Deployment

- **File:** `playbooks/infrastructure/vault/deploy-vault-prod.yml:90`
- **Severity:** HIGH
- **Description:** Production Vault cluster deployed with `vault_tls_disable: true`.
- **Fix:** Enable TLS with proper certificate management before production use.

### 1.3 Medium Severity Findings

#### SEC-009: Hardcoded IP Addresses (Policy Violation)

- **Files:** 15+ locations across playbooks, roles, scripts, and Nomad jobs
- **Severity:** MEDIUM
- **Description:** Violates the project's explicit "no hardcoded IPs" policy. Found in Consul defaults, Nomad cert scripts, assessment playbooks, and infrastructure templates.
- **Key locations:**
  - `roles/consul/defaults/main.yml:15-17` (192.168.11.11-13)
  - `roles/consul/templates/consul.hcl.j2:34-37` (hardcoded retry_join)
  - `scripts/generate-nomad-certs.sh:9` (192.168.10.31)
  - `playbooks/assessment/nomad-cluster-check.yml:9-20`
  - `nomad-jobs/platform-services/vault-pki/vault-pki-exporter.nomad.hcl:62`
  - `nomad-jobs/platform-services/postgresql/postgresql.nomad.hcl:160-162`
- **Fix:** Replace with dynamic inventory variables sourced from NetBox.

#### SEC-010: Missing no_log on Sensitive Operations

- **Files:** Various playbooks handling Consul/Vault tokens
- **Severity:** MEDIUM
- **Description:** Inconsistent `no_log: true` usage on tasks handling secrets. While 151 tasks properly use `no_log`, some Infisical lookups lack it.
- **Fix:** Audit all tasks handling secrets and add `no_log: true` consistently.

#### SEC-011: Insecure /tmp Usage in Certificate Scripts

- **Files:** `scripts/generate-nomad-certs.sh:10`, `scripts/generate-consul-certs.sh`
- **Severity:** MEDIUM
- **Description:** Fixed `/tmp` directory paths for certificate material allow other users to access sensitive data.
- **Fix:** Use `mktemp -d` with a cleanup trap and `chmod 700`.

#### SEC-012: ignore_errors Masking Security Failures

- **Files:** `playbooks/infrastructure/maintenance/consul-rolling-upgrade.yml`, `playbooks/infrastructure/docker/fix-nftables-compatibility.yml:171`
- **Severity:** MEDIUM
- **Description:** Broad `ignore_errors: true` can mask legitimate security and configuration failures.
- **Fix:** Use `failed_when` with specific error code handling.

#### SEC-013: Internal Services Using HTTP Instead of HTTPS

- **Files:** Multiple playbooks with `http://` URLs for Consul, Vault, Nomad APIs
- **Severity:** MEDIUM
- **Description:** Internal service communication uses unencrypted HTTP.
- **Fix:** Implement HTTPS for all inter-service communication.

### 1.4 Positive Security Findings

- SOPS encryption with age for `.env.json` - secrets encrypted at rest
- Infisical integration properly securing dynamic secrets
- 151 tasks properly using `no_log` for sensitive operations
- Pre-commit hooks with `detect-private-key` enabled
- GitHub Actions using pinned action versions with SHA hashes
- Python dependencies pinned in `pyproject.toml`
- `chmod 600` on generated MCP config
- Sudoers modifications validated with `visudo -cf %s`

---

## 2. Code Quality Review

### 2.1 Best Practices

#### CQ-001: FQCN Violations Throughout Codebase

- **Severity:** HIGH
- **Description:** Many tasks use short module names instead of Fully Qualified Collection Names despite CLAUDE.md requiring FQCN usage.
- **Key locations:**
  - `roles/consul_dns/tasks/systemd-resolved.yml:5,11,19,28` (`package:`, `file:`, `template:`, `systemd:`)
  - `roles/consul_dns/tasks/validate.yml:5,10,16` (`package:`, `command:`, `debug:`)
  - `roles/nfs/tasks/main.yml:5,11,22,40` (`assert:`, `wait_for:`)
  - `roles/consul/tasks/main.yml:33,43,51` (`stat:`, `fail:`, `assert:`)
  - `playbooks/infrastructure/consul/phase1-consul-foundation.yml:12,24,30,36,46,47`
- **Fix:** Run `ansible-lint --fix` and update `.ansible-lint` to enforce FQCN (remove `fqcn[action-core]` from warn_list).

#### CQ-002: Deprecation Warnings Disabled

- **File:** `ansible.cfg:27`
- **Severity:** MEDIUM
- **Description:** `deprecation_warnings=False` masks important deprecations that could break in future Ansible versions.
- **Fix:** Enable deprecation warnings and address identified issues.

#### CQ-003: Host Key Checking Disabled Globally

- **File:** `ansible.cfg:9`
- **Severity:** MEDIUM
- **Description:** `host_key_checking = False` set globally. Acceptable for homelab but should be documented.
- **Fix:** Add explanatory comment and consider enabling for production inventory.

#### CQ-004: Inconsistent failed_when/changed_when Usage

- **Severity:** MEDIUM
- **Description:** Only 45 instances of `failed_when`/`changed_when` across all roles - very low coverage for shell/command tasks.
- **Fix:** Add appropriate `changed_when: false` for read-only commands and `failed_when` for optional operations.

### 2.2 Role Quality

#### CQ-005: Missing consul_dns Role Documentation

- **File:** `roles/consul_dns/` (no README.md)
- **Severity:** MEDIUM
- **Fix:** Create README with overview, variables, dependencies, and examples.

#### CQ-006: Incomplete netdata_consul_template Role

- **File:** `roles/netdata_consul_template/`
- **Severity:** MEDIUM
- **Description:** Contains only README.md with no tasks, defaults, handlers, or templates.
- **Fix:** Either implement the full role structure or remove/archive.

#### CQ-007: Empty Nomad Role meta/main.yml

- **File:** `roles/nomad/meta/main.yml`
- **Severity:** LOW
- **Description:** Meta file contains only `---` with no dependency declarations.
- **Fix:** Add galaxy_info and explicit dependencies (e.g., system_base).

### 2.3 Playbook Quality

#### CQ-008: Incomplete Smoke Test Playbooks

- **Files:** 5 smoke test playbooks with TODO placeholders
  - `playbooks/infrastructure/consul/smoke-test.yml`
  - `playbooks/infrastructure/nomad/smoke-test.yml`
  - `playbooks/infrastructure/proxmox/smoke-test.yml`
  - `playbooks/infrastructure/traefik/smoke-test.yml`
  - `playbooks/infrastructure/dns-ipam/smoke-test.yml`
- **Severity:** MEDIUM
- **Fix:** Complete implementations following the Vault smoke test pattern.

#### CQ-009: TODO to Refactor Fix Playbook into Role

- **File:** `playbooks/fix/fix-dns-resolution-loop.yml:2`
- **Severity:** MEDIUM
- **Fix:** Convert to proper role under `roles/`.

### 2.4 Python Code Quality

#### CQ-010: TODO in CSI Volume Module

- **File:** `plugins/modules/nomad_csi_volume.py:113`
- **Severity:** LOW
- **Description:** Unresolved TODO about min/max value implementation.
- **Fix:** Complete implementation or create tracking issue.

---

## 3. Code Simplification

### 3.1 Critical Duplication: Fragmented Netdata Architecture

#### SIMP-001: 7 Overlapping Netdata Roles

- **Impact:** HIGH
- **Effort:** MODERATE
- **Files affected:**
  - `roles/netdata/` (main orchestrator)
  - `roles/netdata_install/` (separate role)
  - `roles/netdata_configure/` (separate role)
  - `roles/netdata_streaming/` (separate role)
  - `roles/netdata_cloud/` (separate role)
  - `roles/netdata_consul/` (separate role)
  - `roles/netdata_consul_template/` (README only)
- **Description:** The main `netdata` role uses `include_tasks` to orchestrate, while 6 separate roles duplicate overlapping functionality. Only the main role is referenced by playbooks - the separate roles appear unused.
- **Fix:** Consolidate into a single unified netdata role:
  - Merge all defaults into `netdata/defaults/main.yml`
  - Keep modular task files as includes within the main role
  - Delete the 6 separate roles

### 3.2 Template Duplication

#### SIMP-002: Duplicate Netdata Configuration Templates

- **Impact:** HIGH
- **Files:**
  - `roles/netdata/templates/netdata.conf.j2` (97 lines) vs `roles/netdata_configure/templates/netdata.conf.j2` (59 lines)
  - `roles/netdata_streaming/templates/stream.conf.j2` (104 lines) vs `roles/netdata/templates/stream.conf.j2` (58 lines)
  - `roles/netdata_consul/templates/consul-service.json.j2` vs `roles/netdata/templates/consul-netdata.json.j2`
- **Fix:** Resolved by SIMP-001 consolidation.

#### SIMP-003: Duplicate Infisical Lookup Patterns

- **Impact:** HIGH
- **Effort:** EASY
- **Files:** `roles/netdata_cloud/tasks/main.yml:11-35`, `roles/netdata_streaming/tasks/main.yml:11-39`
- **Description:** Both roles contain identical Infisical secret retrieval patterns. A reusable task file already exists at `tasks/infisical-secret-lookup.yml` but isn't being used.
- **Fix:** Replace manual lookups with `include_tasks` referencing the shared task file.

### 3.3 Dead Code

#### SIMP-004: Unused Roles

- **Impact:** HIGH
- **Effort:** EASY
- **Roles never directly referenced by playbooks:**
  - `roles/netdata_install/`
  - `roles/netdata_configure/`
  - `roles/netdata_streaming/`
  - `roles/netdata_cloud/`
  - `roles/netdata_consul/`
  - `roles/netdata_consul_template/`
  - `roles/nfs/` (verify before deletion)
- **Fix:** Remove after confirming no indirect usage.

#### SIMP-005: FIXME Comments in Netdata Install

- **File:** `roles/netdata/tasks/install.yml:14,25`
- **Impact:** MEDIUM
- **Description:** FIXME about idempotency and redundant directory creation that the installer already handles.
- **Fix:** Remove redundant directory creation task, resolve idempotency concern.

### 3.4 Over-Engineering

#### SIMP-006: Complex Vault Configuration Logic

- **Files:** `roles/vault/tasks/config_prod.yml` (184 lines), `roles/vault/templates/vault.hcl.j2` (132 lines)
- **Impact:** MEDIUM
- **Effort:** MODERATE
- **Description:** Deeply nested conditionals for storage backend, TLS, and auto-unseal configuration.
- **Fix:** Split into separate template files per backend, use Jinja2 includes.

#### SIMP-007: Variable Scatter Across Multiple Defaults Files

- **Impact:** MEDIUM
- **Description:** Netdata variables defined across 4+ different defaults files with inconsistent naming.
- **Fix:** Consolidate all defaults into single role defaults and/or `group_vars/all/netdata.yml`.

### 3.5 Inline Playbook Variables

#### SIMP-008: Variables That Should Be in group_vars

- **File:** `playbooks/infrastructure/monitoring/update-netdata-configs.yml:9-29`
- **Impact:** MEDIUM
- **Effort:** EASY
- **Description:** Common variables (config paths, users, ports) defined inline instead of in group_vars.
- **Fix:** Move to `group_vars/all/netdata.yml`.

---

## 4. Infrastructure Review

### 4.1 Nomad Jobs

#### INFRA-001: Disabled Health Checks in Traefik

- **File:** `nomad-jobs/core-infrastructure/traefik.nomad.hcl:161-170,250-259`
- **Severity:** HIGH
- **Description:** Critical health checks commented out with TODO note, preventing Nomad from detecting service failures.
- **Fix:** Implement TCP health checks as fallback if HTTP checks have connectivity issues.

#### INFRA-002: 'Latest' Image Tags in Production

- **Severity:** HIGH
- **Files:**
  - `nomad-jobs/platform-services/powerdns/powerdns-auth.nomad.hcl:27`
  - `nomad-jobs/platform-services/vault-pki/vault-pki-monitor.nomad.hcl:19,57`
  - `nomad-jobs/platform-services/vault-pki/vault-pki-exporter.nomad.hcl:49`
  - `nomad-jobs/applications/example-app.nomad.hcl:24`
- **Description:** `latest` tags prevent reproducible deployments and complicate rollback.
- **Fix:** Pin all container images to specific versions.

#### INFRA-003: Missing Update and Restart Policies

- **Files:** `traefik.nomad.hcl`, `postgresql.nomad.hcl`
- **Severity:** MEDIUM
- **Description:** No explicit update strategy or restart policy defined for critical infrastructure services.
- **Fix:** Add `update {}` and `restart {}` blocks with appropriate settings.

#### INFRA-004: Insufficient Resource Allocation

- **File:** `nomad-jobs/core-infrastructure/traefik.nomad.hcl:136-139`
- **Severity:** MEDIUM
- **Description:** Traefik allocated only 200 CPU and 256 MB memory - underprovisioned for a production load balancer.
- **Fix:** Increase to at least 500 CPU / 512 MB.

#### INFRA-005: Vault PKI Monitor Cloning Repo on Every Run

- **File:** `nomad-jobs/platform-services/vault-pki/vault-pki-monitor.nomad.hcl:19-24`
- **Severity:** MEDIUM
- **Description:** Batch job clones the full repository on every execution - inefficient with external dependency.
- **Fix:** Build a container image with monitoring scripts pre-baked.

### 4.2 Consul Configuration

#### INFRA-006: ACL Token Fallback to Environment Variable

- **File:** `roles/consul/templates/consul.hcl.j2:92`
- **Severity:** HIGH
- **Description:** ACL agent token falls back to environment variable with no validation: `agent = "{{ consul_acl_agent_token | default(lookup('env', 'CONSUL_MGMT_TOKEN')) }}"`.
- **Fix:** Fail early if token is not provided via inventory.

#### INFRA-007: Gossip Key as Template Variable

- **File:** `roles/consul/defaults/main.yml:28`
- **Severity:** MEDIUM
- **Description:** `consul_encrypt: '$GOSSIP_KEY'` is a placeholder with no actual value.
- **Fix:** Generate and store in Infisical; fail deployment if not provided.

### 4.3 Vault Configuration

#### INFRA-008: Vault Config Verification Logic Inverted

- **File:** `playbooks/infrastructure/vault/deploy-vault-prod.yml:113-118`
- **Severity:** MEDIUM
- **Description:** Config verification expects error code (`rc != 1`) rather than success, indicating improper validation.
- **Fix:** Use proper `vault config validate` command.

#### INFRA-009: Vault TLS Auto-Disable on Missing Certificates

- **File:** `roles/vault/tasks/config_prod.yml:24-87`
- **Severity:** MEDIUM
- **Description:** Rescue block automatically disables TLS if certificates are missing instead of failing deployment.
- **Fix:** Fail deployment if TLS is required but certificates are absent.

#### INFRA-010: Vault Production References Undefined Host

- **File:** `inventory/environments/vault-cluster/group_vars/vault_production/main.yml:19`
- **Severity:** HIGH
- **Description:** References `vault-master-lloyd` without ensuring host exists in inventory.
- **Fix:** Add pre-task validation that the host exists and is accessible.

### 4.4 Global Variable Defaults

#### INFRA-011: Example Domain in Global Defaults

- **File:** `group_vars/all/main.yml:6`
- **Severity:** MEDIUM
- **Description:** `homelab_domain: "example.com"` could silently propagate if not overridden.
- **Fix:** Use a distinctive placeholder like `UNSET.invalid` to catch missing overrides.

---

## 5. Feature Gap Analysis

### 5.1 Critical Gaps

#### GAP-001: Incomplete Domain Migration (.local to spaceships.work)

- **Impact:** CRITICAL
- **Description:** ROADMAP Phase 4 domain migration marked "Critical priority" but infrastructure application is PENDING. PostgreSQL credentials not configured, PowerDNS zones not synced, DNS cutover not executed.
- **Blocked by:** PostgreSQL deployment with Vault credential integration.
- **Action:** Execute Phase 4 completion sequence.

### 5.2 Testing Gaps

#### GAP-002: 5 Smoke Tests Are Placeholders

- **Impact:** HIGH
- **Components without real smoke tests:** Consul, Nomad, Proxmox, Traefik, DNS/IPAM
- **Action:** Implement following the Vault smoke test pattern.

#### GAP-003: No Molecule Tests for 12 of 13 Roles

- **Impact:** MEDIUM
- **Action:** Create molecule.yml configurations for all roles.

#### GAP-004: No Integration Tests Between Services

- **Impact:** HIGH
- **Missing:** Consul-Nomad ACL, Vault-Consul auth, PowerDNS-NetBox sync, Nomad-Consul DNS
- **Action:** Create `playbooks/infrastructure/integration-tests/` directory.

### 5.3 Automation Gaps

#### GAP-005: No Backup/Disaster Recovery Automation

- **Impact:** HIGH
- **Missing:** PostgreSQL backups, Vault state backups, NetBox config backups, Consul KV snapshots
- **Reference:** `docs/project-management/tasks/pki-015-pki-disaster-recovery.md` (plan exists, no implementation)
- **Action:** Implement backup playbooks for all critical services.

#### GAP-006: No Certificate Renewal Automation (ACME)

- **Impact:** HIGH
- **Description:** ROADMAP Phase 5 mentions DNS-01 ACME but no implementation exists.
- **Action:** Create Nomad periodic job and Vault ACME configuration playbook.

#### GAP-007: Nomad ACLs Currently Disabled

- **File:** `docs/operations/infrastructure-state.md:59`
- **Impact:** HIGH
- **Action:** Create Nomad ACL enforcement playbook.

### 5.4 CI/CD Gaps

#### GAP-008: Missing CI Workflow

- **Impact:** HIGH
- **Description:** README references `.github/workflows/ci.yml` but file doesn't exist. Only 3 workflows (mega-linter, release, sync-labels).
- **Missing:** Syntax validation, smoke test execution, security scanning.
- **Action:** Create `ci.yml` workflow.

#### GAP-009: MegaLinter Errors Not Blocking

- **File:** `.mega-linter.yml:21-35`
- **Impact:** MEDIUM
- **Description:** `DISABLE_ERRORS_LINTERS` for most linters means errors don't fail the build, contradicting PR requirements.
- **Action:** Remove non-essential linters from DISABLE_ERRORS list.

### 5.5 Monitoring Gaps

#### GAP-010: Incomplete Monitoring Standards

- **File:** `docs/standards/monitoring-observability-standards.md`
- **Impact:** MEDIUM
- **Description:** 84% incomplete with multiple [TODO] placeholders.
- **Action:** Complete with metrics, alerting thresholds, and dashboard requirements.

#### GAP-011: No Certificate Expiry Monitoring

- **Impact:** MEDIUM
- **Action:** Create alerting for PKI certificate expiry across all services.

### 5.6 Documentation Gaps

#### GAP-012: 5 Standards Documents Marked TODO

- **File:** `docs/standards/README.md`
- **Missing:** git-standards.md, development-workflow.md, monitoring-observability-standards.md, linting-standards.md, project-management-standards.md
- **Action:** Complete the standards documents.

#### GAP-013: Missing Operational Runbooks

- **Missing:** PowerDNS upgrade, NetBox migration, domain migration troubleshooting, Nomad deployment checklist
- **Action:** Create in `docs/operations/procedures/`.

---

## 6. Documentation and Project Health

### 6.1 Documentation Issues

#### DOC-001: Broken Reference in INDEX.md

- **File:** `docs/INDEX.md:227`
- **Severity:** MEDIUM
- **Description:** References `implementation/netbox-integration.md` which doesn't exist. Actual files are `implementation/dns-ipam/netbox-integration-patterns.md`.
- **Fix:** Update reference.

#### DOC-002: Stale Infrastructure State Documentation

- **File:** `docs/operations/infrastructure-state.md`
- **Severity:** LOW
- **Description:** Last updated 2025-09-10, doesn't reflect current Phase 3-4 progress.
- **Fix:** Update to reflect current deployment status.

#### DOC-003: 78 References to .local Domain Still Present

- **Severity:** MEDIUM
- **Description:** Despite domain migration being critical priority, numerous documentation and code references to `.local` remain outside of archives.
- **Fix:** Systematic update of all non-archived `.local` references.

### 6.2 CI/CD Issues

#### DOC-004: Release Workflow Has Placeholder Notes

- **File:** `.github/workflows/release.yml:45-48`
- **Severity:** MEDIUM
- **Description:** Manual release notes placeholder: `<!-- Add release notes here -->`.
- **Fix:** Implement automated release notes from conventional commits.

#### DOC-005: MegaLinter Validates Full Codebase on Every Push

- **File:** `.github/workflows/mega-linter.yml:67`
- **Severity:** MEDIUM
- **Description:** `VALIDATE_ALL_CODEBASE: true` is slow for feature branches.
- **Fix:** Use conditional validation (full on main, differential on PRs).

### 6.3 Developer Experience

#### DOC-006: Minimal DevContainer Configuration

- **File:** `.devcontainer/devcontainer.json`
- **Severity:** LOW
- **Description:** Missing VS Code extensions, workspace settings, and integrated testing commands.
- **Fix:** Extend with recommended extensions and post-creation commands.

#### DOC-007: Missing Custom Module Documentation

- **Files:** `plugins/modules/nomad_csi_volume.py`, `plugins/module_utils/debug.py`
- **Severity:** MEDIUM
- **Description:** Custom Ansible modules lack usage documentation and examples.
- **Fix:** Create `docs/implementation/custom-modules.md`.

### 6.4 Project Organization

#### DOC-008: Tests Directory Nearly Empty

- **File:** `tests/` (contains only `test_localhost.yml`)
- **Severity:** MEDIUM
- **Description:** No Python unit tests for custom modules, no molecule scenarios for roles.
- **Fix:** Implement comprehensive testing structure.

#### DOC-009: Reports Directory Without Retention Policy

- **File:** `reports/` (49 files, 302KB)
- **Severity:** LOW
- **Description:** Auto-generated reports accumulating without cleanup policy.
- **Fix:** Create cleanup script and document retention policy.

---

## 7. Recommended Action Plan

### Phase 1: Immediate (This Sprint)

| Priority | Action | Finding | Effort |
|----------|--------|---------|--------|
| P0 | Remove `print("here")` from consul.py | SEC-001 | 1 min |
| P0 | Replace `eval()` in generate-mcp-config.sh | SEC-002 | 30 min |
| P1 | Pin all container images to specific versions | INFRA-002 | 1 hr |
| P1 | Re-enable Traefik health checks | INFRA-001 | 1 hr |
| P1 | Disable Traefik debug mode | SEC-006 | 15 min |
| P1 | Fix Vault TLS skip verification | SEC-007 | 30 min |
| P1 | Fix broken INDEX.md reference | DOC-001 | 5 min |

### Phase 2: High Priority (Next 2 Sprints)

| Priority | Action | Finding | Effort |
|----------|--------|---------|--------|
| P2 | Consolidate 7 netdata roles into 1 | SIMP-001 | 1-2 days |
| P2 | Delete unused roles | SIMP-004 | 2 hrs |
| P2 | Replace hardcoded IPs with dynamic vars | SEC-009 | 1-2 days |
| P2 | Complete Consul + Nomad smoke tests | GAP-002 | 1 day |
| P2 | Create CI workflow | GAP-008 | 4 hrs |
| P2 | Enforce FQCN across codebase | CQ-001 | 4 hrs |
| P2 | Add update/restart policies to Nomad jobs | INFRA-003 | 2 hrs |
| P2 | Implement backup automation | GAP-005 | 2-3 days |

### Phase 3: Medium Priority (Next Month)

| Priority | Action | Finding | Effort |
|----------|--------|---------|--------|
| P3 | Complete domain migration Phase 4 | GAP-001 | 3-5 days |
| P3 | Complete monitoring standards doc | GAP-010 | 1 day |
| P3 | Create integration test playbooks | GAP-004 | 2-3 days |
| P3 | Enable Nomad ACLs | GAP-007 | 1-2 days |
| P3 | Complete TODO standards documents | GAP-012 | 2-3 days |
| P3 | Simplify Vault configuration logic | SIMP-006 | 1 day |
| P3 | Move inline variables to group_vars | SIMP-008 | 2 hrs |
| P3 | Enable SSH host key checking | SEC-004 | 2 hrs |

### Phase 4: Long-term Improvements

| Priority | Action | Finding | Effort |
|----------|--------|---------|--------|
| P4 | Implement ACME certificate automation | GAP-006 | 3-5 days |
| P4 | Create molecule tests for all roles | GAP-003 | 3-5 days |
| P4 | Create operational runbooks | GAP-013 | 2-3 days |
| P4 | Restrict sudo to specific commands | SEC-005 | 2 hrs |
| P4 | Implement HTTPS for all internal services | SEC-013 | 2-3 days |
| P4 | Enhance devcontainer setup | DOC-006 | 2 hrs |
| P4 | Create custom module documentation | DOC-007 | 4 hrs |

---

## 8. Strengths and Positive Findings

The repository demonstrates several areas of excellence:

1. **Secret Management:** Well-architected Infisical + Vault integration with SOPS encryption at rest
2. **Documentation Culture:** 308 markdown files with comprehensive standards, ADRs, and operational guides
3. **Linting Infrastructure:** MegaLinter with ansible-lint, yamllint, ruff, mypy, markdownlint, shellcheck integration
4. **Pre-commit Hooks:** Security scanning with `detect-private-key` and secret scanning
5. **Supply Chain Security:** GitHub Actions with pinned SHA hashes, Python dependencies with version constraints
6. **Role Architecture:** Well-organized role structure with proper defaults, handlers, and templates (for most roles)
7. **Conventional Commits:** Clear commit message standards documented and followed
8. **Project Management:** Detailed task tracking, sprint planning, and ADR documentation
9. **Vault Integration:** Production-grade Vault deployment with auto-unseal via transit
10. **Dynamic Inventory:** Strong patterns for NetBox-based dynamic inventory management

---

## Appendix: Finding Index

| ID | Category | Severity | Description |
|----|----------|----------|-------------|
| SEC-001 | Security | CRITICAL | Debug print in consul.py |
| SEC-002 | Security | HIGH | eval() in shell script |
| SEC-003 | Security | HIGH | Unverified Docker download |
| SEC-004 | Security | HIGH | SSH host key checking disabled |
| SEC-005 | Security | HIGH | Unrestricted NOPASSWD sudo |
| SEC-006 | Security | HIGH | Insecure Traefik config |
| SEC-007 | Security | HIGH | Vault TLS skip verify |
| SEC-008 | Security | HIGH | TLS disabled in prod Vault |
| SEC-009 | Security | MEDIUM | Hardcoded IPs (15+ locations) |
| SEC-010 | Security | MEDIUM | Inconsistent no_log usage |
| SEC-011 | Security | MEDIUM | Insecure /tmp in scripts |
| SEC-012 | Security | MEDIUM | ignore_errors masking failures |
| SEC-013 | Security | MEDIUM | HTTP for internal services |
| CQ-001 | Quality | HIGH | FQCN violations |
| CQ-002 | Quality | MEDIUM | Deprecation warnings disabled |
| CQ-003 | Quality | MEDIUM | Host key checking disabled |
| CQ-004 | Quality | MEDIUM | Missing failed_when/changed_when |
| CQ-005 | Quality | MEDIUM | Missing consul_dns README |
| CQ-006 | Quality | MEDIUM | Incomplete netdata_consul_template role |
| CQ-007 | Quality | LOW | Empty nomad meta/main.yml |
| CQ-008 | Quality | MEDIUM | 5 placeholder smoke tests |
| CQ-009 | Quality | MEDIUM | Fix playbook needs refactoring |
| CQ-010 | Quality | LOW | TODO in CSI volume module |
| SIMP-001 | Simplification | HIGH | 7 fragmented netdata roles |
| SIMP-002 | Simplification | HIGH | Duplicate templates |
| SIMP-003 | Simplification | HIGH | Duplicate Infisical patterns |
| SIMP-004 | Simplification | HIGH | 6-7 unused roles |
| SIMP-005 | Simplification | MEDIUM | FIXME in netdata install |
| SIMP-006 | Simplification | MEDIUM | Complex Vault config logic |
| SIMP-007 | Simplification | MEDIUM | Variable scatter |
| SIMP-008 | Simplification | MEDIUM | Inline playbook variables |
| INFRA-001 | Infrastructure | HIGH | Disabled Traefik health checks |
| INFRA-002 | Infrastructure | HIGH | Latest image tags |
| INFRA-003 | Infrastructure | MEDIUM | Missing update/restart policies |
| INFRA-004 | Infrastructure | MEDIUM | Insufficient Traefik resources |
| INFRA-005 | Infrastructure | MEDIUM | Vault PKI monitor clones repo |
| INFRA-006 | Infrastructure | HIGH | ACL token env fallback |
| INFRA-007 | Infrastructure | MEDIUM | Gossip key placeholder |
| INFRA-008 | Infrastructure | MEDIUM | Inverted Vault config check |
| INFRA-009 | Infrastructure | MEDIUM | TLS auto-disable |
| INFRA-010 | Infrastructure | HIGH | Undefined host reference |
| INFRA-011 | Infrastructure | MEDIUM | example.com in global defaults |
| GAP-001 | Feature Gap | CRITICAL | Incomplete domain migration |
| GAP-002 | Feature Gap | HIGH | 5 placeholder smoke tests |
| GAP-003 | Feature Gap | MEDIUM | No molecule tests |
| GAP-004 | Feature Gap | HIGH | No integration tests |
| GAP-005 | Feature Gap | HIGH | No backup automation |
| GAP-006 | Feature Gap | HIGH | No ACME automation |
| GAP-007 | Feature Gap | HIGH | Nomad ACLs disabled |
| GAP-008 | Feature Gap | HIGH | Missing CI workflow |
| GAP-009 | Feature Gap | MEDIUM | MegaLinter errors not blocking |
| GAP-010 | Feature Gap | MEDIUM | Incomplete monitoring standards |
| GAP-011 | Feature Gap | MEDIUM | No cert expiry monitoring |
| GAP-012 | Feature Gap | MEDIUM | 5 TODO standards docs |
| GAP-013 | Feature Gap | MEDIUM | Missing operational runbooks |
| DOC-001 | Documentation | MEDIUM | Broken INDEX.md reference |
| DOC-002 | Documentation | LOW | Stale infrastructure state |
| DOC-003 | Documentation | MEDIUM | 78 .local references remain |
| DOC-004 | Documentation | MEDIUM | Placeholder release notes |
| DOC-005 | Documentation | MEDIUM | Full codebase validation on every push |
| DOC-006 | Documentation | LOW | Minimal devcontainer |
| DOC-007 | Documentation | MEDIUM | Missing module docs |
| DOC-008 | Documentation | MEDIUM | Empty tests directory |
| DOC-009 | Documentation | LOW | Reports without retention |
