# Documentation Index

This directory contains comprehensive documentation for the NetBox-focused Ansible automation project. Documentation is now organized into logical categories for easier navigation.

## 📂 Directory Structure

### 📏 [standards/](standards/)
**START HERE** - Standards and operating procedures that govern this repository:
- Documentation organization and philosophy
- Ansible development patterns and why we use them
- Infrastructure architecture decisions
- Nomad job development standards
- The "why" behind our technical choices

### 🚀 [getting-started/](getting-started/)
Essential documentation for new users and developers:
- Repository structure overview
- Development environment setup (pre-commit, uv)
- Troubleshooting common issues
- Quick start guides

### 🛠️ [implementation/](implementation/)
Detailed implementation guides organized by component:
- **[dns-ipam/](implementation/dns-ipam/)** - DNS & IPAM overhaul documentation
- **[consul/](implementation/consul/)** - Consul configuration and integration
- **[infisical/](implementation/infisical/)** - Infisical secrets management
- **Nomad Configuration** - Storage, patterns, and port allocation guides
- **[netbox-integration.md](implementation/netbox-integration.md)** - NetBox automation patterns

### 📋 [project-management/](project-management/)
Project tracking and infrastructure inventory:
- Task lists and progress tracking
- Imported infrastructure documentation
- Decision history and rationale

### 🔧 [operations/](operations/)
Operational guides for deployed services:
- Netdata monitoring architecture
- Troubleshooting procedures
- Performance optimization
- Service management

### 📊 [diagrams/](diagrams/)
Visual representations of architecture and workflows:
- System architecture overview
- DNS/IPAM migration flow
- Secrets management patterns
- Network topology diagrams

### 🤖 [ai-docs/](ai-docs/)
AI assistant integration documentation:
- Sub-agent configurations
- Tool documentation
- Integration patterns

### 📦 [archive/](archive/)
Deprecated documentation preserved for reference:
- Legacy 1Password integration
- Historical setup procedures
- Previous implementation attempts

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
- [Testing Strategy](implementation/dns-ipam/testing-strategy.md)
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

## 🤝 Contributing

When adding or updating documentation:
1. Place in appropriate category directory
2. Update category README if needed
3. Add to this index for major documents
4. Include "Related Documentation" sections
5. Follow the documentation standards above

## 📊 Documentation Coverage

| Area | Status | Location |
|------|--------|----------|
| Getting Started | ✅ Complete | `getting-started/` |
| DNS/IPAM Implementation | ✅ Complete | `implementation/dns-ipam/` |
| Consul Integration | ✅ Complete | `implementation/consul/` |
| Secrets Management | ✅ Complete | `implementation/infisical/` |
| NetBox Patterns | ✅ Complete | `implementation/netbox-integration.md` |
| Operational Guides | 🚧 Growing | `operations/` |
| Architecture Diagrams | ✅ Complete | `diagrams/` |

---

*Last reorganization: 2025-08-01 - Improved navigation and categorization*