## Project Management Assessment (Repo Reality vs `docs/project-management/`)

Date: 2025-08-10

### TL;DR

- **PowerDNS status conflicts** across docs (SQLite vs MySQL vs PostgreSQL Mode A) and API accessibility; consolidate to a single current state and a single target state.
- **Path/name mismatches** (e.g., `jobs/` vs `nomad-jobs/`, missing `consul/` segment in playbook paths, non-existent `.testing` paths).
- **Phase naming drift** (Multi-Site labeled Phase 4 in one place, Phase 5 elsewhere) and mixed completion vs rollback notes for the same task.
- Vault and NetBox statuses are broadly consistent; Testing/QA initiative reflects repo reality (no per-role Molecule, minimal unit tests).

Below are the concrete findings with evidence and recommended corrections to align the project-management docs for smooth continuation of deployment.

---

## Verified Repo Reality (ground truth)

- **Nomad jobs present**: `nomad-jobs/`
  - `core-infrastructure/traefik.nomad.hcl` (host networking, static 80/443) and `vault-reference.nomad.hcl` (reference-only)
  - `platform-services/powerdns.nomad.hcl` (MariaDB/MySQL backend) and `powerdns-sqlite.nomad.hcl` (SQLite args); `postgresql.nomad.hcl` present
- **Operations docs**:
  - `docs/operations/powerdns-deployment-final.md`: PowerDNS deployed with **SQLite**, API enabled on dynamic port, DNS on 53
  - `docs/operations/dns-deployment-status.md`: PowerDNS currently **SQLite**, flags issues (API not responding at time of report), recommends MySQL fix
  - `docs/operations/vault-access.md`: Vault in dev mode on three nodes with addresses in `192.168.10.x`
- **Playbooks and roles** exist for Phase 1 Consul DNS and PowerDNS secrets/ACLs; playbooks reference Nomad job deploy via `community.general.nomad_job`.
- **NetBox** dynamic inventory config: `inventory/netbox.yml` (endpoint `https://192.168.30.213`, `NETBOX_TOKEN` via env).
- **Testing infra**: Taskfile includes `test:quick`, `test:python`, `test:roles`; no per-role Molecule directories; 14 custom modules in `plugins/modules/` with minimal unit tests.

---

## Conflicts vs `docs/project-management/`

### 1) PowerDNS state (backend + status)

- PM Completed (Aug 1) claims MariaDB-backed PowerDNS complete with persistence; Current Sprint notes a rollback; Phase 4 pivots to Mode A (PostgreSQL); Operations shows SQLite running and at least one time API issues.
  - Evidence: `docs/project-management/completed/2025-08.md` (Phase 2 complete), `docs/project-management/current-sprint.md` (rollback note), `docs/project-management/phases/phase-4-dns-integration.md` (Mode A with PostgreSQL), `docs/operations/powerdns-deployment-final.md` (SQLite), `docs/operations/dns-deployment-status.md` (SQLite + issues).
- Impact: Devs lack a single authoritative “current vs target” declaration for PowerDNS.

### 2) Non-existent paths referenced

- Phase 4 doc and PowerDNS implementation README reference `.testing` job paths that do not exist in repo:
  - Referenced: `nomad-jobs/platform-services/.testing/mode-a/powerdns-testing.nomad.hcl`
  - Actual: `nomad-jobs/platform-services/powerdns-sqlite.nomad.hcl`, `nomad-jobs/platform-services/powerdns.nomad.hcl`, `nomad-jobs/platform-services/postgresql.nomad.hcl`
- Impact: Copy/paste deploy commands will fail.

### 3) Directory name and playbook path drift

- Some docs use `jobs/…` but repo uses `nomad-jobs/…`.
- Some docs reference `playbooks/infrastructure/phase1-consul-dns.yml`, but the file is under `playbooks/infrastructure/consul/phase1-consul-dns.yml`.
- Impact: Friction executing the prescribed commands.

### 4) Phase labeling inconsistency

- One PM index labels Multi-Site as Phase 4, while the phases set labels Multi-Site as Phase 5.
  - Evidence: `docs/project-management/task-list.md` vs `docs/project-management/phases/README.md` and `phase-5-multisite.md`.
- Impact: Confusion on sequencing and milestone tracking.

### 5) Mixed completion vs. rollback for the same milestone

- PM Completed (Aug) says “Phase 2: Deploy PowerDNS” is done; Current Sprint says “rolled back to this point, still need to complete”.
- Impact: Delivery state ambiguous; planning and next steps unclear.

### 6) Status deltas inside operations docs

- `dns-deployment-status.md` states “API not accessible” and “needs fixes” while `powerdns-deployment-final.md` states “Successfully Deployed” with API enabled.
- Impact: Which status should devs trust when proceeding?

---

## Items that are consistent and actionable

- **Vault**: Dev mode deployment confirmed and accurately reflected in PM docs and operations docs; `roles/vault/` exists and Ops has access/runbook details.
- **NetBox**: Deployed at `https://192.168.30.213`; PM docs reflect this; `inventory/netbox.yml` configured.
- **Traefik**: Job present with host networking and Consul Catalog integration; PM docs indicate it’s deployed.
- **Testing initiative**: Matches repo state (tests tasks exist; minimal tests in tree).

---

## Recommendations to align `project-management` (no edits done yet)

- **PowerDNS single-source truth**:

  - Declare explicitly in PM:
    - Current state: PowerDNS running using `powerdns-sqlite.nomad.hcl` (SQLite, API via dynamic port), per `docs/operations/powerdns-deployment-final.md`.
    - Target state (Phase 4): Mode A with external PostgreSQL using `nomad-jobs/platform-services/postgresql.nomad.hcl` + a Mode A PowerDNS job file (presently `powerdns.nomad.hcl` uses MySQL; either update job or clarify the interim step).
  - Replace any “MySQL now” claims with “SQLite prototype now; PostgreSQL Mode A planned” or clarify the interim if MySQL is still intended.
  - Resolve internal Ops doc contradiction (API accessible vs not) by consolidating to the latest verified test result.

- **Fix path references in PM docs**:

  - Use `nomad-jobs/…` (not `jobs/…`).
  - Use `playbooks/infrastructure/consul/phase1-consul-dns.yml` (not `playbooks/infrastructure/phase1-consul-dns.yml`).
  - Remove references to `.testing` paths that do not exist; replace with existing files in `nomad-jobs/platform-services/`.

- **Phase labeling**:

  - Ensure all PM docs consistently refer to Multi-Site as Phase 5 (as per `phases/README.md`).

- **Completion vs rollback**:

  - Update PM to reflect Phase 2 status as “prototype completed (SQLite), MariaDB attempt not adopted; pivot to PostgreSQL Mode A in Phase 4”.
  - Move any rollback notes into “Known Issues / Next Steps” rather than Completed.

- **Add a “Run This Next” checklist in PM** so devs can proceed unblocked:
  - 1. Verify current PowerDNS (SQLite) is healthy: dig on 53 and API health on dynamic port
  - 2. Provision PostgreSQL via `nomad-jobs/platform-services/postgresql.nomad.hcl`
  - 3. Create Vault/Consul entries for PDNS (playbooks under `playbooks/infrastructure/powerdns/` and `playbooks/infrastructure/vault/`)
  - 4. Deploy Mode A PowerDNS job targeting PostgreSQL (align job file to repo reality)
  - 5. NetBox → PowerDNS sync playbooks or script once API is reachable

---

## Specific discrepancies to correct (by file)

- `docs/project-management/current-sprint.md`: Clarify PowerDNS status vs rollback note to match the consolidated PowerDNS narrative above.
- `docs/project-management/completed/2025-08.md`: Mark PowerDNS Phase 2 as “prototype complete (SQLite)”; remove/assert MariaDB only if actually in use; leave clear pointer to Mode A migration.
- `docs/project-management/phases/phase-4-dns-integration.md`: Replace `.testing` paths with existing `nomad-jobs/platform-services/…` files; ensure Mode A steps reference the actual PostgreSQL job file present.
- `docs/project-management/task-list.md`: Fix Multi-Site labeling (Phase 5, not Phase 4), and any path references to `jobs/` → `nomad-jobs/`.
- `docs/project-management/imported-infrastructure.md`: Fix `phase1-consul-dns.yml` path to include `consul/` subdir.

---

## Confidence notes

- Evidence is drawn from current repository files and directories. Where runtime claims exist (e.g., API accessible), we relied on the most recent/explicit operations doc (`powerdns-deployment-final.md`). Where multiple operations docs conflict, we recommend selecting one “current state” and removing/archiving obsolete status to avoid confusion.

---

## Ready-to-execute references (no changes made)

- Traefik job: `nomad-jobs/core-infrastructure/traefik.nomad.hcl`
- PowerDNS jobs: `nomad-jobs/platform-services/powerdns-sqlite.nomad.hcl`, `nomad-jobs/platform-services/powerdns.nomad.hcl`
- PostgreSQL job: `nomad-jobs/platform-services/postgresql.nomad.hcl`
- Consul Phase 1: `playbooks/infrastructure/consul/phase1-consul-dns.yml`
- NetBox inventory: `inventory/netbox.yml`
- PowerDNS playbooks: `playbooks/infrastructure/powerdns/`
- Vault ops: `docs/operations/vault-access.md`

---

## Quick acceptance criteria after PM alignment

- A single PowerDNS status (current and target) appears across PM and Ops docs.
- All paths in PM docs are executable against the repo as-is (no `.testing`, no `jobs/`).
- Phase names/numbers match `docs/project-management/phases/README.md`.
- “Completed” sections do not conflict with “Current Sprint” or Ops status.
