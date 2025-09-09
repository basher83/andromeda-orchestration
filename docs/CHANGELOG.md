# Documentation Changelog

All notable changes to the documentation in `docs/` will be documented in this file.

> How to use this file: Review latest entries at the top to understand recent documentation changes. When updating docs, add a concise entry under today's date with Added/Changed/Removed subsections.

## 2025-08-31

### Changed

- **Migrated task runner references to mise**: Updated all documentation to use `mise run` commands instead of `task` commands
  - `task security` → `mise run security`
  - `task security:secrets` → `mise run security:secrets`
  - `task security:kics` → `mise run security:kics`
  - `task hooks` → `uv run pre-commit run --all-files`
  - `task setup` → `mise run setup`
  - `task todos` → `./scripts/find-todos.sh`
- **Fixed markdownlint command references**: Updated documentation to use correct `markdownlint-cli2` commands
  - `uv run markdownlint docs/**/*.md` → `markdownlint-cli2 "**/*.md" "#.venv"`
  - `markdownlint "**/*.md" --fix` → `markdownlint-cli2 "**/*.md" "#.venv" --fix`
- **Updated files**: `docs/standards/security-standards.md`, `docs/operations/security-scanning.md`, `docs/operations/testing-strategy.md`, `docs/getting-started/pre-commit-setup.md`, `docs/INDEX.md`, `docs/standards/linting-standards.md`

### Added

- New comprehensive `docs/INDEX.md` file for detailed documentation navigation:
  - Complete directory structure overview with descriptions for all 15+ documentation areas
  - Key documents listings for each major section (standards, implementation, operations, etc.)
  - Essential quick links organized by use case (Implementation, Operations, Development)
  - Updated documentation coverage table including all current areas
  - Cross-links to `README.md` for project status and quick start information

### Changed

- Refactored `docs/README.md` to focus on project overview and status:
  - Reduced from 206 lines to ~35 lines for better focus
  - Removed detailed directory navigation (moved to INDEX.md)
  - Simplified quick start guide with essential steps only
  - Maintained current project status and active implementation details
  - Added prominent cross-link to INDEX.md for comprehensive navigation

### Improved

- **Documentation navigation structure**: Created clear separation between project status (README.md) and detailed navigation (INDEX.md)
- **Cross-linking system**: Bidirectional navigation between overview and comprehensive index
- **User experience**: Users can now quickly access project status or dive into detailed documentation as needed
- **Maintainability**: Each file has a focused purpose, making updates easier and more targeted

---

## 2025-08-21

### Added

- New `docs/implementation/nomad/consul-health-checks.md` - Comprehensive guide for Consul service registration and health checks in Nomad jobs
  - Identity blocks for ACL integration
  - Health check patterns (HTTP, TCP, Script, gRPC)
  - Timing best practices and port specification guidelines
  - Complete examples for web apps, databases, and multi-protocol services
  - Common pitfalls and troubleshooting
- Populated `docs/operations/README.md` with comprehensive index:
  - Directory structure with all operational guides
  - Quick start sections for incident response and routine operations
  - Operational checklists (daily, weekly, monthly)
  - Common tasks with example commands
  - Service status matrix
  - Emergency procedures and maintenance windows

### Changed

- Updated `docs/implementation/nomad/README.md` to integrate consul-health-checks.md:
  - Added to "How these docs are organized" section
  - Created new "Service Registration & Health Checks" documentation section
  - Enhanced Consul integration references throughout
  - Updated implementation status to reflect completed health check documentation
- Improved formatting of `docs/implementation/nomad/consul-health-checks.md`:
  - Added hierarchical section structure with clear headings
  - Created timing table for visual reference
  - Added visual indicators (✅ ❌ ⚠️) for best practices
  - Included Quick Reference table and Common Pitfalls section
- Updated `docs/README.md`:
  - Changed Nomad Configuration reference to properly link to nomad/ directory
  - Added Nomad Configuration to Documentation Coverage table

### Fixed

- Corrected incorrect `ai-docs/` directory reference in `docs/README.md` to `resources/ai-assistants/`
- Fixed empty `docs/operations/README.md` by adding comprehensive index and operational guidance
- Updated `docs/standards/ansible-standards.md` to include all collections from requirements.yml:
  - Added missing collections (Proxmox, PostgreSQL, Vault, Infisical)
  - Created Collection Management section with installation instructions
  - Added version pinning strategy guidance
  - Expanded module documentation to cover all infrastructure tools
- Refactored `docs/standards/nomad-job-standards.md` to eliminate duplication:
  - Replaced duplicated content with references to implementation/nomad/ docs
  - Added links to all 8 Nomad implementation guides
  - Maintained standards focus while pointing to detailed implementation docs
  - Improved cross-referencing between standards and implementation

## 2025-08-18

### Added

- New `docs/getting-started/ci-testing-with-act.md` guide for testing GitHub Actions workflows locally before pushing
- Act installation, configuration, and VS Code integration documentation
- CI workflow testing best practices and troubleshooting

### Changed

- Updated `docs/README.md` to include CI Testing with Act guide under "For Development" section
- Updated `docs/getting-started/README.md` to list the new CI testing guide under "Setup and Configuration"

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
