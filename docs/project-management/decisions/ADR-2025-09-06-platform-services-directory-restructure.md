# ADR-2025-09-06: Platform Services Directory Restructure

![Status](https://img.shields.io/badge/Status-Accepted-green)
![Date](https://img.shields.io/badge/Date-2025--09--06-lightgrey)
![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration?path=docs%2Fproject-management%2Fdecisions%2FADR-2025-09-06-platform-services-directory-restructure.md&display_timestamp=author&style=plastic&logo=github)

## Status

Accepted

## Context

The current `nomad-jobs/platform-services/` directory contains a flat structure with files from multiple services mixed together:

```text
platform-services/
├── POSTGRESQL-DEPLOYMENT.md
├── postgresql.nomad.hcl
├── postgresql.variables.hcl
├── postgresql.variables.example.hcl
├── powerdns-auth.nomad.hcl
├── powerdns-infisical.nomad.hcl
├── vault-pki-exporter.nomad.hcl
├── vault-pki-monitor.nomad.hcl
└── README.md
```

This structure violates our own documentation standards established in `docs/standards/documentation-standards.md`, which recommends organizing services into separate directories with each service containing its own README and configuration files.

The current flat structure makes it difficult to:

- Navigate service-specific files
- Maintain service boundaries
- Scale as more services are added
- Follow consistent organizational patterns

## Decision

We will restructure the `nomad-jobs/platform-services/` directory to use service-specific subdirectories, creating a cleaner separation between services while maintaining the existing functionality.

### New Structure

```text
platform-services/
├── postgresql/
│   ├── postgresql.nomad.hcl
│   ├── postgresql.variables.hcl
│   ├── postgresql.variables.example.hcl
│   ├── POSTGRESQL-DEPLOYMENT.md
│   └── README.md
├── powerdns/
│   ├── powerdns-auth.nomad.hcl
│   ├── powerdns-infisical.nomad.hcl
│   └── README.md
├── vault-pki/
│   ├── vault-pki-exporter.nomad.hcl
│   ├── vault-pki-monitor.nomad.hcl
│   └── README.md
└── README.md (main platform-services README)
```

## Consequences

### Positive

- **Better Organization**: Each service is self-contained with clear boundaries
- **Improved Navigation**: Service-specific files are grouped together
- **Standards Compliance**: Aligns with our documented organizational policies
- **Scalability**: Easier to add new services without directory clutter
- **Maintainability**: Service-specific documentation and configuration are co-located

### Negative

- **Path Changes**: All references to platform-services files need updating (27+ files identified)
- **Migration Effort**: Requires systematic updates across documentation and scripts
- **Breaking Changes**: Existing deployment scripts and documentation will need updates

### Risks

- **Deployment Script Failures**: Ansible playbooks and deployment scripts may fail if paths aren't updated correctly
- **Documentation Inconsistencies**: Some references may be missed during migration
- **Time Investment**: Significant effort required to update all references across the codebase

## Alternatives Considered

### Alternative 1: Keep Current Flat Structure

- **Description**: Maintain the existing flat directory structure
- **Why we didn't choose it**: Violates our own documentation standards and creates organizational problems as more services are added

### Alternative 2: Create Separate Top-Level Directories

- **Description**: Move services to separate directories at the `nomad-jobs/` level (e.g., `nomad-jobs/postgresql/`, `nomad-jobs/powerdns/`)
- **Why we didn't choose it**: Would break the existing categorization system (core-infrastructure, platform-services, applications) and create inconsistency

### Alternative 3: Minimal Restructure

- **Description**: Only create subdirectories for services with multiple files (PostgreSQL), keep others flat
- **Why we didn't choose it**: Creates inconsistent patterns and doesn't fully solve the organizational problem

## Implementation

Key steps to implement this decision:

1. **Create service directories**:

   ```bash
   mkdir -p nomad-jobs/platform-services/{postgresql,powerdns,vault-pki}
   ```

2. **Move files to service directories**:

   ```bash
   # PostgreSQL files
   mv nomad-jobs/platform-services/postgresql.* nomad-jobs/platform-services/POSTGRESQL-DEPLOYMENT.md nomad-jobs/platform-services/postgresql/

   # PowerDNS files
   mv nomad-jobs/platform-services/powerdns-* nomad-jobs/platform-services/powerdns/

   # Vault PKI files
   mv nomad-jobs/platform-services/vault-pki-* nomad-jobs/platform-services/vault-pki/
   ```

3. **Create service-specific READMEs** for each service directory

4. **Update path references** in:

   - `nomad-jobs/README.md` (deployment examples)
   - `nomad-jobs/platform-services/README.md`
   - `playbooks/infrastructure/nomad/deploy-job.yml`
   - `playbooks/infrastructure/vault/deploy-pki-exporter.yml`
   - All documentation files (23+ files identified)

5. **Test deployment scripts** with new paths

6. **Update main platform-services README** to reflect new structure

## References

- [Documentation Standards](../standards/documentation-standards.md)
- [Nomad Jobs README](../../nomad-jobs/README.md)
- [Current Platform Services Structure](../../nomad-jobs/platform-services/)
- [ADR Template](ADR-TEMPLATE.md)
