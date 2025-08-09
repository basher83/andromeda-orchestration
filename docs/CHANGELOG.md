# Documentation Changelog

All notable changes to the documentation in `docs/` will be documented in this file.

> How to use this file: Review latest entries at the top to understand recent documentation changes. When updating docs, add a concise entry under today's date with Added/Changed/Removed subsections.

## 2025-08-09

### Added

- New `docs/implementation/nomad/dynamic-volumes.md` consolidating dynamic volume guidance (prerequisites, installer link, client template, validation checklist).
- Mermaid diagrams replacing ASCII in:
  - `docs/implementation/nomad/README.md` (architecture, job organization)
  - `docs/implementation/nomad/storage-configuration.md` (selection guide)
- `docs/project-management/phases/README.md` — phases index with one-line descriptions.
- Phases and status icon legends to `docs/project-management/README.md`.
- Detailed PowerDNS/NetBox checklists added under "Detailed Checklist" in `docs/project-management/phases/phase-4-dns-integration.md`.
- Phase 4 "Implementation Plan Update" section referencing PowerDNS Mode A docs.

### Changed

- `docs/implementation/nomad/README.md`: Added Prerequisites, How docs are organized; updated links.
- `docs/implementation/nomad/port-allocation.md`: Added policy statement, prerequisites, mermaid decision tree, validation notes per pattern.
- `docs/implementation/nomad/storage-configuration.md`: Linked to role unit `roles/nomad/files/nomad-dynvol@.service` and new guide.
- `docs/implementation/nomad/storage-strategy.md` and `storage-patterns.md`: Updated cross-links to new dynamic volumes guide.
- `playbooks/infrastructure/nomad/volumes/README.md`: Updated reference to dynamic volumes guide.
- Project management docs:
  - Normalized phase titles/numbering and navigation across phase docs (Phase 3–6).
  - Trimmed `docs/project-management/current-sprint.md` to a concise overview; active work updated to "PowerDNS Mode A Adoption".
  - Updated `docs/project-management/task-summary.md` phase table and current focus to reflect the Mode A pivot.
  - Moved detailed PowerDNS/NetBox subtasks from current sprint into Phase 4 doc.
  - Fixed links and removed duplicate numbered headings in `docs/project-management/archive/full-task-list-2025-08-05.md`.
  - Updated Phase 4 to pivot from MariaDB prototype to PowerDNS Auth with PostgreSQL (Mode A) and added concrete steps.

### Removed

- Deleted `docs/implementation/nomad/dynamic-volumes/` directory (content moved to role or consolidated in new guide):
  - `README.md`, `client.nomad.hcl`, `ext4-volume.sh`, `install-dynvol-plugin.yml`, `nomad-dynvol@.service`.

---

## 2025-08-01

- Documentation reorganization and index improvements (see `docs/README.md`).

## 2025-08-02

### Added

- Expanded `docs/ai-docs/` with assistant tooling docs and integration workflows.

## 2025-07-29

### Added

- Netdata operations docs: `docs/operations/netdata-architecture.md` and Consul integration notes.

## 2025-07-27

### Added

- Nomad implementation docs initial drop:
  - `docs/implementation/nomad/storage-configuration.md`
  - `docs/implementation/nomad/storage-patterns.md`
  - `docs/implementation/nomad/storage-strategy.md`

## 2025-07-24

### Added

- Nomad networking guidance: `docs/implementation/nomad/port-allocation.md` with patterns and best practices.
