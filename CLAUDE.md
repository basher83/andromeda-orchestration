# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Andromeda Orchestration - Ansible automation project for comprehensive homelab infrastructure management using NetBox as network source-of-truth and Infisical for secure credential management.

### Tech Stack

- **Languages**: Python 3.10+, HCL (Nomad), YAML (Ansible)
- **Frameworks**: Ansible Core 2.15+, Nomad, Consul, Vault
- **Tools**: uv (package manager), MegaLinter, pre-commit hooks
- **Infrastructure**: Proxmox, NetBox, PowerDNS, Tailscale

### Code Style & Conventions

- **Ansible**: FQCN usage, dynamic inventory patterns, no hardcoded IPs
- **Security**: Infisical lookups for secrets, TLS validation, PKI certificates
- **Domains**: Configurable domains only (no .local due to macOS conflicts)
- **Linting**: MegaLinter with ansible-lint, yamllint, ruff, mypy, markdownlint-cli2, shellcheck, and more.

### Development Workflow

- **Commands**: Always use `uv run` prefix for Ansible operations
- **Commits**:
  - Use conventional commit format:
  - Group related changes atomically
  - Test playbooks before committing
  - Include playbook name and purpose in commit message
  - Reference issue numbers when applicable

Example commit messages:

```text
feat(infra/vault): enhance vault playbooks with enterprise patterns
fix(ansible): add safety guards for PKI role list validation
refactor(inventory/vault-cluster): add group variables and domain configuration
docs(roles/vault): enhance README with implementation lessons and examples
fix(tasks): improve domain assertions and validation tasks
```

- **Testing**: Smoke tests mandatory, multi-layer validation (infra/platform/app)
- **PR Requirements**: All linters pass, secrets scanned, documentation updated

### Testing Strategy

- **Infrastructure**: Dynamic inventory validation, service connectivity tests
- **Platform**: Consul DNS resolution, Vault unsealing, Nomad job deployment
- **Application**: End-to-end service communication, certificate validation
- **Security**: Infisical secrets scanning, KICS IaC security, pre-commit hooks

### Environment Setup

- **Python**: uv sync (core), uv sync --extra dev (linting), uv sync --extra secrets (Infisical)
- **Collections**: uv run ansible-galaxy collection install -r requirements.yml
- **Secrets**: ansible - infisical integration (see `docs/getting-started/infisical-complete-guide.md`)
- **Validation**: uv run ansible-inventory --list (test inventory connectivity)

### Key References

- **Architecture**: `docs/project-management/decisions/` (ADRs for design decisions)
- **Setup**: `docs/getting-started/` (environment and development setup)
- **Standards**: `docs/standards/` (Ansible, infrastructure, and code quality rules)
- **Operations**: `docs/operations/` (deployment and maintenance procedures)

### Review Process

Before submitting code:

1. Run comprehensive linting: `mise run lint` (includes MegaLinter)
2. Execute smoke tests: `mise run test:smoke`
3. Validate security: `mise run security` (Infisical + KICS)
4. Test playbooks: `uv run ansible-playbook --syntax-check --list-tasks`
5. Lint playbooks: `uv run ansible-lint`
6. Update documentation per `docs/standards/documentation-standards.md`
7. Confirm compliance with dynamic inventory and no-hardcoded-IP policies

### Essential References

- **[ROADMAP.md](ROADMAP.md)** - Current phase and project direction
- **[docs/standards/](docs/standards/)** - Code quality and development rules
- **[docs/getting-started/](docs/getting-started/)** - Environment setup guides
- **[docs/troubleshooting/](docs/troubleshooting/)** - Troubleshooting guides
- **[docs/operations/infrastructure-state.md](docs/operations/infrastructure-state.md)** - Current deployment status
- **[.cursor/rules/ansible-rules.mdc](.cursor/rules/ansible-rules.mdc)** - Ansible integration rules

### Working with Specialized Agents

When working on tasks in this project, follow these guidelines:

#### Use Specialized Agents Proactively

Don't wait to be asked - if a task matches an agent's description, use it immediately. The agents are designed to handle specific domains more effectively than general-purpose approaches.

#### Avoid Defaulting to Direct Implementation

Resist the urge to jump straight into implementation. Take a moment to:

- Consider which agent best fits the task
- Use the agent's specialized knowledge and patterns
- Let agents handle their domains of expertise

This approach ensures better quality, consistency, and adherence to project patterns.
