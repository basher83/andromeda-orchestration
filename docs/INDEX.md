# 📚 Documentation Index

This is a comprehensive guide to all documentation in this repository.

**📖 For project status and quick start guide, see [README.md](README.md)**

## 📂 Directory Structure

### 📏 [standards/](standards/)

**START HERE** - Standards and operating procedures that govern this repository: documentation organization, Ansible development patterns, mandatory smoke testing, infrastructure architecture decisions, Nomad job standards, security procedures, and technical rationale.

**Key Documents:**

- [documentation-standards.md](standards/documentation-standards.md) - Documentation organization and standards
- [infrastructure-standards.md](standards/infrastructure-standards.md) - Infrastructure architecture decisions
- [ansible-standards.md](standards/ansible-standards.md) - Ansible development patterns
- [security-standards.md](standards/security-standards.md) - Security procedures
- [testing-standards.md](standards/testing-standards.md) - Testing requirements

### 🚀 [getting-started/](getting-started/)

Essential documentation for new users and developers: repository structure overview, development environment setup (pre-commit, uv), troubleshooting guides, and quick start procedures.

**Key Documents:**

- [repository-structure.md](getting-started/repository-structure.md) - Complete project overview
- [pre-commit-setup.md](getting-started/pre-commit-setup.md) - Development environment setup
- [smoke-testing-quickstart.md](getting-started/smoke-testing-quickstart.md) 🔥 **MANDATORY** - Pre-deployment validation
- [troubleshooting.md](getting-started/troubleshooting.md) - Common setup issues

### 🛠️ [implementation/](implementation/)

Detailed implementation guides organized by component: DNS & IPAM overhaul, PowerDNS deployment architecture, Consul configuration, Infisical secrets management, Nomad configuration with health checks and storage, and NetBox automation patterns.

#### [dns-ipam/](implementation/dns-ipam/)

- [implementation-plan.md](implementation/dns-ipam/implementation-plan.md) - Master plan for DNS & IPAM overhaul
- [domain-migration-master-plan.md](implementation/dns-ipam/domain-migration-master-plan.md) - Critical .local to spaceships.work migration
- [phase1-guide.md](implementation/dns-ipam/phase1-guide.md) - Phase 1: Consul DNS Foundation
- [phase3-netbox-deployment.md](implementation/dns-ipam/phase3-netbox-deployment.md) - Phase 3: NetBox IPAM deployment

#### [powerdns/](implementation/powerdns/)

- [deployment-architecture.md](implementation/powerdns/deployment-architecture.md) - Architecture decisions and implementation
- Complete deployment steps with PostgreSQL backend

#### [consul/](implementation/consul/)

- [acl-integration.md](implementation/consul/acl-integration.md) - ACL setup and integration patterns
- [telemetry-setup.md](implementation/consul/telemetry-setup.md) - Telemetry configuration

#### [vault/](implementation/vault/)

- [deployment-strategy.md](implementation/vault/deployment-strategy.md) - Complete deployment strategy
- [enhanced-deployment-strategy.md](implementation/vault/enhanced-deployment-strategy.md) - Production patterns

#### [nomad/](implementation/nomad/)

- [storage-configuration.md](implementation/nomad/storage-configuration.md) - Storage configuration guide
- [storage-strategy.md](implementation/nomad/storage-strategy.md) - Strategic storage approach
- [port-allocation.md](implementation/nomad/port-allocation.md) - Port allocation best practices

#### [infisical/](implementation/infisical/)

- [infisical-setup.md](implementation/infisical/infisical-setup.md) - Configuration and migration guide
- [comparison.md](implementation/infisical/comparison.md) - 1Password vs Infisical comparison

### 🛠️ [configuration/](configuration/)

Homelab domain configuration and settings.

- [homelab-domain.md](configuration/homelab-domain.md) - Homelab domain configuration

### 📋 [project-management/](project-management/)

Project tracking and infrastructure inventory: task lists, progress tracking, imported infrastructure documentation, and decision history with rationale.

**Key Areas:**

- [decisions/](project-management/decisions/) - Architectural decision records (ADR files)
- [phases/](project-management/phases/) - Implementation phase documentation
- [current-sprint.md](project-management/current-sprint.md) - Current sprint status
- [smoke-testing-implementation-tracker.md](project-management/smoke-testing-implementation-tracker.md) - Testing implementation progress

### 🔧 [operations/](operations/)

Operational guides for deployed services: Netdata monitoring architecture, troubleshooting procedures, performance optimization, and service management.

**Key Documents:**

- [netdata-architecture.md](operations/netdata-architecture.md) - Netdata monitoring architecture
- [smoke-testing-procedures.md](operations/smoke-testing-procedures.md) - Operational testing procedures
- [deployment-log.md](operations/deployment-log.md) - Deployment history and procedures
- [dns-deployment-status.md](operations/dns-deployment-status.md) - DNS deployment status

### 📊 [diagrams/](diagrams/)

Visual representations of architecture and workflows: system architecture overview, DNS/IPAM migration flow, secrets management patterns, and network topology diagrams.

**Key Diagrams:**

- [architecture-overview.md](diagrams/architecture-overview.md) - System architecture overview
- [dns-ipam-migration-flow.md](diagrams/dns-ipam-migration-flow.md) - DNS/IPAM migration workflow
- [secrets-management-flow.md](diagrams/secrets-management-flow.md) - Secrets management patterns
- [network-port-architecture.md](diagrams/network-port-architecture.md) - Network port architecture

### 📦 [archive/](archive/)

Deprecated documentation preserved for reference: legacy 1Password integration, historical setup procedures, and previous implementation attempts.

### 📦 [migration/](migration/)

Migration guides and documentation for transitioning between systems and tools.

- [mise-to-ansible-migration.md](migration/mise-to-ansible-migration.md) - Mise to Ansible migration
- [netdata-role-migration.md](migration/netdata-role-migration.md) - Netdata role migration

### 📦 [proposals/](proposals/)

Technical proposals and improvement suggestions.

- [linting-workflow-improvements.md](proposals/linting-workflow-improvements.md) - Linting workflow improvements
- [powerdns-schema-ansible-implementation.md](proposals/powerdns-schema-ansible-implementation.md) - PowerDNS schema implementation

### 📦 [resources/](resources/)

Additional project resources: AI assistant configurations, community resources, tool utilities, and reference documentation.

**Key Resources:**

- [ai-assistants/](resources/ai-assistants/) - AI assistant configurations
- [references.md](resources/references.md) - Reference documentation
- [tools-utilities.md](resources/tools-utilities.md) - Tool utilities

### 🐛 [troubleshooting/](troubleshooting/)

Problem resolution guides and common issue solutions.

**Key Guides:**

- [dns-resolution-loops.md](troubleshooting/dns-resolution-loops.md) - DNS resolution loop issues
- [service-identity-issues.md](troubleshooting/service-identity-issues.md) - Service identity problems
- [ansible-nomad-playbooks.md](troubleshooting/ansible-nomad-playbooks.md) - Ansible/Nomad integration issues

### 📊 [wiki/](wiki/)

Wiki implementation guides and content mapping.

- [WIKI_CONTENT_MAPPING.md](wiki/WIKI_CONTENT_MAPPING.md) - Content mapping guide
- [WIKI_IMPLEMENTATION_GUIDE.md](wiki/WIKI_IMPLEMENTATION_GUIDE.md) - Implementation guide
- [WIKI_OUTLINE.md](wiki/WIKI_OUTLINE.md) - Wiki outline

## 🔗 Essential Quick Links

### For Implementation

- [DNS & IPAM Master Plan](implementation/dns-ipam/implementation-plan.md)
- [Phase 1 Implementation Guide](implementation/dns-ipam/phase1-guide.md)
- [Infisical Setup](implementation/infisical/infisical-setup.md)

### For Operations

- [Troubleshooting Guide](getting-started/troubleshooting.md)
- [Netdata Architecture](operations/netdata-architecture.md)
- [Repository Structure](getting-started/repository-structure.md)

### For Development

- [Pre-commit Setup](getting-started/pre-commit-setup.md)
- [CI Testing with Act](getting-started/ci-testing-with-act.md)
- [Testing Strategy](implementation/dns-ipam/testing-strategy.md)
- [Documentation Changelog](CHANGELOG.md)
- [uv with Ansible](getting-started/uv-ansible-notes.md)

## 📝 Documentation Standards

All documentation follows these standards:

- **Markdown**: CommonMark specification
- **Structure**: Single H1, logical heading hierarchy
- **Code**: Fenced blocks with language identifiers
- **Links**: Descriptive text, relative paths preferred
- **Voice**: Active voice, present tense
- **Examples**: Practical, tested, and relevant

## 🔧 Maintenance

### Quality Checks

```bash
# Lint markdown files
markdownlint-cli2 "**/*.md" "#.venv"

# Check for broken links
# (tool to be implemented)
```

### Update Guidelines

1. Update relevant docs immediately after changes
2. Maintain cross-references between related docs
3. Archive deprecated content properly
4. Test all command examples
5. Record notable changes in [`CHANGELOG.md`](CHANGELOG.md)

## 🤝 Contributing

When adding or updating documentation:

1. Place in appropriate category directory
2. Update category README if needed
3. Add to this index for major documents
4. Include "Related Documentation" sections
5. Follow the documentation standards above

## 📊 Documentation Coverage

| Area                    | Status      | Location                               |
| ----------------------- | ----------- | -------------------------------------- |
| Getting Started         | ✅ Complete | `getting-started/`                     |
| DNS/IPAM Implementation | ✅ Complete | `implementation/dns-ipam/`             |
| Consul Integration      | ✅ Complete | `implementation/consul/`               |
| Nomad Configuration     | ✅ Complete | `implementation/nomad/`                |
| Secrets Management      | ✅ Complete | `implementation/infisical/`            |
| NetBox Patterns         | ✅ Complete | `implementation/netbox-integration.md` |
| Operational Guides      | 🚧 Growing  | `operations/`                          |
| Architecture Diagrams   | ✅ Complete | `diagrams/`                            |
| Troubleshooting         | ✅ Complete | `troubleshooting/`                     |
| Project Management      | ✅ Complete | `project-management/`                  |
| Migration Guides        | ✅ Complete | `migration/`                           |
| Resources & References  | ✅ Complete | `resources/`                           |
| Proposals               | ✅ Complete | `proposals/`                           |
| Configuration           | ✅ Complete | `configuration/`                       |
| Wiki                    | ✅ Complete | `wiki/`                                |

---

**📖 For project status and quick start path, see [README.md](README.md)**

### Last updated

2025-08-01 - Comprehensive documentation index created
