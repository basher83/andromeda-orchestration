# Standards and Operating Procedures

This directory contains the standards, conventions, and operating procedures that govern this repository. These documents explain not just *what* we do, but more importantly *why* we do it this way.

📚 **Note**: These standards complement and extend the central standards defined in [Mission Control](https://github.com/basher83/docs/tree/main/mission-control/README.md). When in doubt, defer to Mission Control for organization-wide standards.

## 📋 Standards Documents

### [documentation-standards.md](documentation-standards.md)
Our documentation philosophy, organization strategy, and writing guidelines.
- Why we prioritize documentation
- Directory structure and file placement rules
- Markdown formatting standards
- README requirements

### [ansible-standards.md](ansible-standards.md)
Ansible development standards and best practices for this repository.
- Playbook organization and naming
- Variable management strategy
- Inventory architecture decisions
- Testing requirements

### [nomad-job-standards.md](nomad-job-standards.md)
Standards for Nomad job development and deployment.
- File organization (.testing/.archive pattern)
- Service identity requirements
- Port allocation strategy
- Volume naming conventions

### [infrastructure-standards.md](infrastructure-standards.md)
Infrastructure architecture decisions and standards.
- Why dynamic Proxmox inventories
- Service discovery patterns
- Network segmentation approach
- Security baseline requirements

### [security-standards.md](security-standards.md)
Comprehensive security practices and procedures.
- Data classification and handling
- Secret management with Infisical
- Security scanning tools (Infisical, KICS, pre-commit)
- Incident response procedures
- Report security

### [git-standards.md](git-standards.md) 
[TODO]: Version control practices and collaboration guidelines.
- Branch naming conventions
- Commit message format
- PR/MR guidelines
- Merge strategies
- Protected branch policies

### [testing-standards.md](testing-standards.md)
[TODO]: Testing strategies and quality assurance.
- When to write tests
- Test naming conventions
- Coverage requirements
- Pre-deployment testing
- CI/CD testing

### [development-workflow.md](development-workflow.md)
[TODO]: End-to-end development processes.
- Local development setup
- Pre-commit workflow
- Code review process
- Deployment procedures
- Rollback strategies

### [monitoring-observability-standards.md](monitoring-observability-standards.md)
[TODO]: Monitoring and observability practices.
- Metrics to expose
- Alerting thresholds
- Dashboard standards
- Log aggregation
- Tool integration

### [linting-standards.md](linting-standards.md)
[TODO]: Code quality and style enforcement.
- Linting rule rationale
- Error handling process
- Ignore directives
- Tool configurations
- Performance optimization

### [project-management-standards.md](project-management-standards.md)
[TODO]: Project tracking and delivery practices.
- Task tracking methods
- Documentation requirements
- Project phases
- Success criteria
- Risk management

## 🎯 Purpose

These standards exist to:

1. **Ensure Consistency** - Everyone follows the same patterns
2. **Preserve Knowledge** - Document the "why" behind decisions
3. **Accelerate Onboarding** - New contributors understand our approach
4. **Prevent Regression** - Avoid repeating past mistakes
5. **Enable Scale** - Patterns that work at any size

## 📝 Creating New Standards

When adding a new standard:

1. **Document the Problem** - What issue does this solve?
2. **Explain the Decision** - Why this approach over alternatives?
3. **Provide Examples** - Show correct implementation
4. **List Exceptions** - When NOT to follow the standard
5. **Include Migration Path** - How to update existing code

## 🔄 Updating Standards

Standards evolve. When updating:

1. Document the change reason
2. Update all affected standards
3. Create migration guides if needed
4. Communicate changes clearly

## 🏗️ Standard Template

```markdown
# [Standard Name]

## Purpose
Why this standard exists and what problem it solves.

## Background
Context and history leading to this decision.

## Standard
The actual standard or procedure.

## Rationale
Why we chose this approach over alternatives.

## Examples
### Good Example
[Show correct implementation]

### Bad Example
[Show what to avoid]

## Exceptions
When this standard doesn't apply.

## Migration
How to update existing code/docs to meet this standard.

## References
Related standards, external documentation, or decisions.
```

## 🔗 Quick Reference

| Standard | Purpose | Key Decision | Status |
|----------|---------|--------------|--------|
| Documentation | Organized knowledge | Everything documented, logically placed | ✅ Complete |
| Ansible | Consistent automation | Dynamic inventory, modular playbooks | ✅ Complete |
| Nomad | Clean job management | Production/testing/archive separation | ✅ Complete |
| Infrastructure | Scalable architecture | Service discovery, dynamic configuration | ✅ Complete |
| Security | Protect sensitive data | Multi-layer scanning, strict gitignore | ✅ Complete |
| Git | Clean version control | Conventional commits, clear branches | 📝 TODO |
| Testing | Quality assurance | Test early, fail fast | 📝 TODO |
| Development | Efficient workflow | Automated checks, clear process | 📝 TODO |
| Monitoring | System visibility | Metrics, logs, alerts | 📝 TODO |
| Linting | Code consistency | Automated enforcement | 📝 TODO |
| Project Mgmt | Delivery tracking | Visible progress, clear accountability | 📝 TODO |

## 🌐 Relationship with Mission Control

This repository's standards are part of a larger ecosystem:

### Hierarchy
1. **[Mission Control](https://github.com/basher83/docs/tree/main/mission-control/README.md)** - Organization-wide standards and policies
2. **Repository Standards** (this directory) - Project-specific implementations
3. **Service Standards** - Individual service requirements

### When to Use Which
- **Mission Control**: For organization-wide patterns, tooling decisions, and overarching policies
- **Repository Standards**: For project-specific implementations of those patterns
- **Service Documentation**: For service-specific configurations and procedures

### Conflict Resolution
If there's a conflict between standards:
1. Mission Control takes precedence for organization-wide decisions
2. Repository standards can extend but not contradict Mission Control
3. Document any necessary deviations with clear rationale