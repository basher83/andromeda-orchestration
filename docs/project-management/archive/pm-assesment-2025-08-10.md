# Archived: Project Management Assessment (v1)

Date: 2025-08-10

Note: This document is archived. See the current assessment at `../pm-assesmentv2.md`.

---

## Project Management Assessment (Repo Reality vs `docs/project-management/`)

Date: 2025-08-10

### TL;DR

- **PowerDNS current state**: PostgreSQL backend (Mode A) deployed via `nomad-jobs/platform-services/postgresql.nomad.hcl`, using Vault dynamic DB credentials; PowerDNS schema loaded.
- Vault and NetBox statuses are broadly consistent; Testing/QA initiative reflects repo reality (no per-role Molecule, minimal unit tests).

Below are the concrete findings with evidence and recommended corrections to align the project-management docs for smooth continuation of deployment.

---

## Verified Repo Reality (ground truth)

- **Nomad jobs present**: `nomad-jobs/`
  - `core-infrastructure/traefik.nomad.hcl` (host networking, static 80/443) and `vault-reference.nomad.hcl` (reference-only)
  - `platform-services/powerdns.nomad.hcl` (MariaDB/MySQL backend) and `powerdns-sqlite.nomad.hcl` (SQLite args); `postgresql.nomad.hcl` present
- **PostgreSQL + Vault dynamic credentials (PowerDNS backend)**: Deployed via `nomad-jobs/platform-services/postgresql.nomad.hcl`; Vault Database Secrets Engine configured; PowerDNS schema applied. See `docs/implementation/powerdns/postgresql-vault-integration.md` and `docs/implementation/powerdns/postgresql-vault-quickstart.md`.
- **Playbooks and roles** exist for Phase 1 Consul DNS and PowerDNS secrets/ACLs; playbooks reference Nomad job deploy via `community.general.nomad_job`.
- **NetBox** dynamic inventory config: `inventory/netbox.yml` (endpoint `https://192.168.30.213`, `NETBOX_TOKEN` via env).
- **Testing infra**: Taskfile includes `test:quick`, `test:python`, `test:roles`; no per-role Molecule directories; 14 custom modules in `plugins/modules/` with minimal unit tests.

---

## Conflicts vs `docs/project-management/`

### 1) PowerDNS state (backend + status) (Resolved)

- Current state: PowerDNS uses a PostgreSQL backend (Mode A) with Vault dynamic DB credentials; schema applied.
  - Evidence: `nomad-jobs/platform-services/postgresql.nomad.hcl`, `docs/implementation/powerdns/postgresql-vault-integration.md`, `docs/implementation/powerdns/postgresql-vault-quickstart.md`.

### 2) Non-existent paths referenced (Resolved)

- Phase 4 doc and PowerDNS implementation README previously referenced `.testing` job paths. These have been updated to real paths:
  - Correct: `nomad-jobs/platform-services/postgresql.nomad.hcl`
  - Correct: `nomad-jobs/platform-services/powerdns.nomad.hcl` (configure for PostgreSQL backend)
- Impact: Copy/paste deploy commands now match repository files.

### 3) Directory name and playbook path drift (Resolved)

- Some docs use `jobs/…` but repo uses `nomad-jobs/…`.
- Some docs reference `playbooks/infrastructure/phase1-consul-dns.yml`, but the file is under `playbooks/infrastructure/consul/phase1-consul-dns.yml`.
- Impact: Friction executing the prescribed commands.

### 4) Phase labeling inconsistency (Resolved)

- One PM index labels Multi-Site as Phase 4, while the phases set labels Multi-Site as Phase 5.
  - Evidence: `docs/project-management/task-list.md` vs `docs/project-management/phases/README.md` and `phase-5-multisite.md`.
- Impact: Confusion on sequencing and milestone tracking.

### 5) Mixed completion vs. rollback for the same milestone (Resolved)

- PM Completed (Aug) says “Phase 2: Deploy PowerDNS” is done; Current Sprint says “rolled back to this point, still need to complete”.
- Impact: Delivery state ambiguous; planning and next steps unclear.

### 6) Status deltas inside operations docs (Resolved)

- `powerdns-deployment-final.md` is now clearly marked as an outdated SQLite prototype and links to the current PostgreSQL + Vault integration docs.
- `dns-deployment-status.md` reflects the current Mode A state (PostgreSQL backend, Vault dynamic credentials, API via Traefik/dynamic port).
- Source of Truth for operations: `docs/operations/dns-deployment-status.md` and PowerDNS implementation docs under `docs/implementation/powerdns/`.

---

## Items that are consistent and actionable

- **Vault**: Dev mode deployment confirmed and accurately reflected in PM docs and operations docs; `roles/vault/` exists and Ops has access/runbook details.
- **NetBox**: Deployed at `https://192.168.30.213`; PM docs reflect this; `inventory/netbox.yml` configured.
- **Traefik**: Job present with host networking and Consul Catalog integration; PM docs indicate it’s deployed.
- **Testing initiative**: Matches repo state (tests tasks exist; minimal tests in tree).

---

## Remaining recommendations

- Add a small banner in PM docs noting: “PowerDNS is Mode A with PostgreSQL backend and Vault dynamic credentials.”
- Include a compact “Run This Next” checklist in Phase 4:
  1. Verify DNS:53 and API via Traefik/dynamic port
  2. Confirm Vault DB config (connection + powerdns-role)
  3. Ensure PDNS job uses Vault dynamic credentials
  4. Execute NetBox → PowerDNS sync

---

## Specific discrepancies to correct (Resolved)

All previously listed discrepancies have been corrected in the referenced files.

---

## Confidence notes

- Evidence is drawn from current repository files and directories. Where runtime claims exist (e.g., API accessible), we relied on the most recent/explicit operations doc (`powerdns-deployment-final.md`). Where multiple operations docs conflict, we recommend selecting one “current state” and removing/archiving obsolete status to avoid confusion.

---

## Ready-to-execute references (no changes made)

- Traefik job: `nomad-jobs/core-infrastructure/traefik.nomad.hcl`
- PowerDNS jobs: `nomad-jobs/platform-services/powerdns-sqlite.nomad.hcl`, `nomad-jobs/platform-services/powerdns.nomad.hcl`
  - Note: `powerdns-sqlite.nomad.hcl` is a prototype/historical reference only
- PostgreSQL job: `nomad-jobs/platform-services/postgresql.nomad.hcl`
- Consul Phase 1: `playbooks/infrastructure/consul/phase1-consul-dns.yml`
- NetBox inventory: `inventory/netbox.yml`
- PowerDNS playbooks: `playbooks/infrastructure/powerdns/`
- Vault ops: `docs/operations/vault-access.md`
- PowerDNS PostgreSQL + Vault integration (comprehensive): `docs/implementation/powerdns/postgresql-vault-integration.md`
- PowerDNS PostgreSQL + Vault quickstart: `docs/implementation/powerdns/postgresql-vault-quickstart.md`

---

## Quick acceptance criteria after PM alignment

- A single PowerDNS status (current and target) appears across PM and Ops docs: “Mode A with PostgreSQL backend using Vault dynamic credentials; schema applied.”
- All paths in PM docs are executable against the repo as-is (no `.testing`, no `jobs/`).
- Phase names/numbers match `docs/project-management/phases/README.md`.
- “Completed” sections do not conflict with “Current Sprint” or Ops status.
