# Documentation Index

This directory contains comprehensive documentation for the NetBox-focused Ansible automation project. Documentation is now organized into logical categories for easier navigation.

## 📂 Directory Structure

### 📏 [standards/](standards/)

**START HERE** - Standards and operating procedures that govern this repository: documentation organization, Ansible development patterns, mandatory smoke testing, infrastructure architecture decisions, Nomad job standards, security procedures, and technical rationale.

### 🚀 [getting-started/](getting-started/)

Essential documentation for new users and developers: repository structure overview, development environment setup (pre-commit, uv), troubleshooting guides, and quick start procedures.

### 🛠️ [implementation/](implementation/)

Detailed implementation guides organized by component: DNS & IPAM overhaul, PowerDNS deployment architecture, Consul configuration, Infisical secrets management, Nomad configuration with health checks and storage, and NetBox automation patterns.

### 📋 [project-management/](project-management/)

Project tracking and infrastructure inventory: task lists, progress tracking, imported infrastructure documentation, and decision history with rationale.

### 🔧 [operations/](operations/)

Operational guides for deployed services: Netdata monitoring architecture, troubleshooting procedures, performance optimization, and service management.

### 📊 [diagrams/](diagrams/)

Visual representations of architecture and workflows: system architecture overview, DNS/IPAM migration flow, secrets management patterns, and network topology diagrams.

### 📦 [archive/](archive/)

Deprecated documentation preserved for reference: legacy 1Password integration, historical setup procedures, and previous implementation attempts.

### ⚙️ [playbooks/](playbooks/)

Ansible playbooks for infrastructure automation: assessment procedures, infrastructure deployment, fix scripts for common issues, and testing validation procedures.

### 🎭 [roles/](roles/)

Ansible roles for service configuration: Consul service mesh setup, Netdata monitoring configuration, Nomad job scheduler, Vault secrets management, and system base configuration.

### 🔌 [nomad-jobs/](nomad-jobs/)

Nomad job specifications and configurations: core infrastructure job definitions, platform service deployments, and application workload specifications.

### 📊 [reports/](reports/)

Assessment and operational reports: security scanning results, infrastructure readiness assessments, and performance monitoring reports.

### 📋 [inventory/](inventory/)

Ansible inventory files for different environments: environment-specific host configurations, dynamic inventory scripts, and group variable definitions.

### 🧩 [plugins/](plugins/)

Custom Ansible plugins and modules: Consul integration modules, Nomad job management plugins, and utility functions with helpers.

### 🔧 [scripts/](scripts/)

Utility and setup scripts: repository maintenance tools, Nomad job management scripts, security scanning utilities, and development environment setup.

### 🧪 [tests/](tests/)

Test files and configurations: localhost testing procedures, integration test scenarios, and validation smoke tests.

### 📦 [configs/](configs/)

Service configuration files: Netdata collector configurations, health check definitions, and service-specific settings.

### 🔍 [kics-results/](kics-results/)

Security scanning results and reports: Infrastructure as Code security findings, compliance check results, and vulnerability assessment outputs.

### 🤖 [resources/](resources/)

Additional project resources: AI assistant configurations, community resources, tool utilities, and reference documentation.

### 🏗️ Core Configuration Files

Essential project configuration and tooling: Ansible configuration, Python project settings, role dependencies, automated updates, dependency locks, and security scanning configuration.

### 🤖 AI Assistant Configuration

AI-powered development assistance: Claude AI assistant configurations and commands, plus security scanning rules and patterns.

### 🚀 Development Environment

Containerized development setup: VS Code development container configuration and Ansible role testing framework.

### 🔄 CI/CD Pipeline

Automated workflows and quality assurance: GitHub Actions workflows, CI/CD configuration, and Ansible code quality linting rules.

### 📚 Project Documentation

Essential project files: change history and releases, AI assistant integration guide, licensing information, main project documentation, development roadmap, security policies, and project acceleration documentation.

### 📦 Package Metadata

Python package distribution files: main orchestration package metadata and NetBox Ansible package metadata.

## 🎯 Quick Start Path

1. **New to the project?** → Start with [`standards/`](standards/) then [`getting-started/`](getting-started/)
2. **Want to understand our decisions?** → Read [`standards/`](standards/)
3. **Implementing features?** → Check [`implementation/`](implementation/)
4. **Managing services?** → See [`operations/`](operations/)
5. **Tracking progress?** → Visit [`project-management/`](project-management/)

## 📍 Current Project Status

### Active Implementation

- **Phase**: Phase 1 - Consul DNS Foundation (In Progress)
- **Focus**: Enabling Consul DNS across clusters
- **Next**: Phase 3 - NetBox Integration

### Recent Completions

- ✅ Phase 0: Infrastructure Assessment
- ✅ Phase 2: PowerDNS Playbooks Ready
- ✅ Documentation Reorganization

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
uv run markdownlint docs/**/*.md

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

---

### Last reorganization

2025-08-01 - Improved navigation and categorization
