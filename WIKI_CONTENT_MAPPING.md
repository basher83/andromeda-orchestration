# Wiki Content Mapping Guide

This document maps existing repository documentation to the proposed wiki structure, providing specific guidance on content organization and migration priorities.

## Content Migration Mapping

### 🏠 Home / Landing Page

**Source Documents:**
- `README.md` - Project overview and quick start
- `CLAUDE.md` - Architecture overview and current status
- `ROADMAP.md` - Implementation phases and timeline

**Content to Extract:**
- Project description and value proposition
- Current infrastructure status (Phase 3 of DNS & IPAM)
- Key features and capabilities
- Quick navigation to role-based entry points

### 🚀 Getting Started Section

#### Quick Start Guide
**Source:** `README.md` + `docs/getting-started/`
- Setup script usage (`./scripts/setup.sh`, `task setup`)
- uv and Python environment configuration
- Infisical environment variables setup
- First inventory test command

#### Development Environment
**Source:** `docs/getting-started/pre-commit-setup.md` + `Taskfile.yml`
- Pre-commit hooks configuration
- Code quality tools (ansible-lint, yamllint, ruff, mypy)
- Task runner usage (`task lint`, `task fix`, `task test`)
- Security scanning setup

#### Troubleshooting
**Source:** `docs/getting-started/troubleshooting.md` + `docs/troubleshooting/`
- macOS Local Network permissions
- Infisical integration issues
- Common environment setup problems
- Virtual environment troubleshooting

### 📚 Implementation Guides

#### DNS & IPAM Overhaul (Priority 1)
**Source:** `docs/implementation/dns-ipam/`
- **Main Guide:** `implementation-plan.md` - Complete 5-phase roadmap
- **Phase Guides:** `phase1-guide.md`, `phase3-netbox-deployment.md`, etc.
- **Patterns:** `netbox-integration-patterns.md` - Dynamic inventory, state management
- **PowerDNS:** `docs/implementation/powerdns/` - Architecture and deployment

#### Secrets Management
**Source:** `docs/implementation/infisical/` (formerly 1Password)
- **Setup Guide:** `infisical-setup.md` - Project configuration
- **Migration:** `docs/archive/1password-integration.md` - Legacy patterns
- **Comparison:** `comparison.md` - Feature comparison and migration rationale

#### HashiCorp Stack
**Source:** `docs/implementation/consul/`, `docs/implementation/vault/`, `docs/implementation/nomad/`
- **Consul:** Service discovery, ACL integration, telemetry
- **Vault:** Deployment strategy, dynamic credentials, PKI
- **Nomad:** Job management, storage patterns, port allocation

### 🎮 Operations Section

#### Playbook Library
**Source:** `playbooks/` directory structure
- **Assessment:** `playbooks/assessment/` - Infrastructure health checks
- **Infrastructure:** `playbooks/infrastructure/` - Deployment and management
- **Examples:** `playbooks/examples/` - Learning and testing

#### Cluster Operations
**Source:** `docs/operations/` + `CLAUDE.md`
- **og-homelab:** Original cluster (proxmoxt430, pve1)
- **doggos-homelab:** Nomad cluster (lloyd, holly, mable)
- **Service Status:** Consul, Nomad, Vault current states
- **Network Configuration:** Port strategy, firewall rules

#### Monitoring & Observability
**Source:** `docs/operations/netdata/` + roles
- **Netdata Architecture:** Current monitoring setup
- **Consul Integration:** Service health monitoring
- **Configuration Reference:** Daemon settings and streaming

### 🔧 Reference Documentation

#### Standards & Best Practices
**Source:** `docs/standards/`
- **Ansible Standards:** `ansible-standards.md` - Playbook structure, role development
- **Infrastructure Standards:** `infrastructure-standards.md` - Naming, tagging
- **Security Standards:** `security-standards.md` - Access control, encryption
- **Testing Standards:** `testing-standards.md` - Validation procedures

#### Architecture Diagrams
**Source:** `docs/diagrams/`
- **System Overview:** `architecture-overview.md`
- **DNS Migration:** `dns-ipam-migration-flow.md`
- **HashiCorp Integration:** `hashicorp-stack-integration.md`
- **Network Design:** `network-port-architecture.md`

### 📊 Project Management

#### Current Status Tracking
**Source:** `docs/project-management/`
- **Current Sprint:** `current-sprint.md` - Active tasks
- **Task Management:** `task-list.md` - Comprehensive task tracking
- **Progress Reports:** `completed/` - Monthly completion summaries
- **Phase Planning:** `phases/` - Detailed phase breakdowns

#### Historical Context
**Source:** `docs/project-management/archive/`
- **Assessment Reports:** Previous infrastructure assessments
- **Completed Initiatives:** Historical project completion
- **Lessons Learned:** Implementation insights and improvements

### 🤖 AI Integration

#### Development Assistants
**Source:** `docs/resources/ai-assistants/`
- **Agent Configuration:** `all_agents.md` - Specialized agent descriptions
- **Tool Integration:** `all_tools.md` - Available automation tools
- **Workflow Patterns:** Custom slash commands and automation
- **Meta-Development:** `meta-example-factory.md` - AI-assisted development

## Migration Priority Matrix

### Phase 1: Essential Navigation (Week 1)
1. **Home Page** - Core project overview and status
2. **Quick Start** - Getting new users productive quickly  
3. **DNS & IPAM Guide** - Current implementation focus
4. **Operations Overview** - Daily operational procedures

### Phase 2: Deep Technical Content (Week 2)
1. **Complete Implementation Guides** - All technical documentation
2. **Standards Reference** - Development and operational standards
3. **Architecture Documentation** - System design and patterns
4. **Troubleshooting Guides** - Comprehensive problem-solving

### Phase 3: Community & Enhancement (Week 3)
1. **Project Management** - Planning and tracking content
2. **AI Integration** - Development automation and tooling
3. **Learning Resources** - Tutorials and educational content
4. **Community Guidelines** - Contribution and collaboration

## Content Organization Best Practices

### Wiki Page Structure
Each wiki page should follow this template:
```markdown
# Page Title

**Quick Navigation:** [Related Page 1] | [Related Page 2] | [Parent Section]

## Overview
Brief description and scope

## Prerequisites  
What users need before following this guide

## Content Sections
Organized by complexity (basic → advanced)

## Related Resources
Links to related wiki pages, external docs, code examples

## Last Updated
Version and date information
```

### Cross-Reference Strategy
- **Bidirectional Links:** Related pages link to each other
- **Context Breadcrumbs:** Clear navigation hierarchy
- **Tag System:** Consistent tagging for search and discovery
- **Version Alignment:** Wiki content versioned with repository

### Maintenance Procedures
- **Weekly Reviews:** Check for outdated content and broken links
- **Monthly Updates:** Align with repository changes and new features
- **Quarterly Assessment:** Review structure and user feedback
- **Community Contributions:** Guidelines for external contributions

## Content Quality Guidelines

### Technical Accuracy
- **Code Examples:** Tested and current with repository state
- **Command References:** Verified against current tool versions
- **Configuration Samples:** Match actual project configurations
- **Status Information:** Current implementation phases and states

### User Experience
- **Clear Navigation:** Multiple paths to find relevant information
- **Progressive Disclosure:** Basic → intermediate → advanced content flow
- **Visual Aids:** Diagrams, code blocks, status indicators
- **Search Optimization:** Proper tagging and keyword usage

### Consistency
- **Terminology:** Consistent technical terms and concepts
- **Formatting:** Standardized markdown structure and styling
- **Voice:** Professional but accessible technical writing
- **Updates:** Regular content freshness and accuracy maintenance

---

This mapping provides a concrete migration path from the existing comprehensive documentation to a well-structured wiki that serves multiple user types while maintaining the technical depth that makes this project valuable for serious infrastructure automation.