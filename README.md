# Andromeda Orchestration

[![CI](https://github.com/basher83/andromeda-orchestration/actions/workflows/ci.yml/badge.svg)](https://github.com/basher83/andromeda-orchestration/actions/workflows/ci.yml)

An Ansible automation project for comprehensive homelab infrastructure management, with NetBox integration for network
source-of-truth and secure credential management through Infisical.

## Overview

This project provides a framework for managing network infrastructure using Ansible with:

- Dynamic inventory from Proxmox (current) and NetBox (planned)
- Secure credential management via Infisical
- Containerized execution environments
- Best practices for Ansible project organization

**Infrastructure Foundation**: The underlying infrastructure (Proxmox clusters, VMs, networking) is provisioned and managed via [terraform-homelab](https://github.com/basher83/terraform-homelab) using Terraform/OpenTofu with Scalr.

## Prerequisites

- **Ansible** 2.15+ with ansible-core
- **Python** 3.9+
- **Infisical** account and machine identity
- **macOS** users: Local Network permissions for Python (see [Troubleshooting](docs/getting-started/troubleshooting.md))
- Docker (optional, for execution environments)

## Quick Start

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd andromeda-orchestration
   ```

2. **Run the setup script**

   ```bash
   ./scripts/setup.sh
   # Or use task for complete setup with dev tools
   task setup
   ```

3. **Configure Infisical integration**

   ```bash
   # Set up Infisical machine identity environment variables
   export INFISICAL_TOKEN="your-machine-identity-token"
   export INFISICAL_PROJECT_ID="your-project-id"
   export INFISICAL_ENV="prod"  # or dev/staging
   ```

4. **Test the setup**

   ```bash
   uv run ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --list
   ```

## Development

### Code Quality Tools

This project uses comprehensive linting and testing:

- **ansible-lint** - Ansible best practices and style guide
- **yamllint** - YAML file formatting
- **ruff** - Python linting and formatting
- **mypy** - Python type checking
- **pre-commit** - Git hooks for automated checks (see [docs/pre-commit-setup.md](docs/pre-commit-setup.md))

### Security Tools

Integrated security scanning:

- **Infisical** - Secrets detection and management
- **KICS** - Infrastructure-as-Code security scanning
- **Pre-commit hooks** - Automated security checks on commit

### Quick Commands

```bash
# Show all available tasks
task

# Run all linters
task lint

# Auto-fix issues
task fix

# Run tests
task test

# Run security scans (Infisical + KICS)
task security

# Run individual security scans
task security:secrets  # Infisical secrets detection
task security:kics     # Infrastructure security scan

# Run pre-commit hooks manually
task hooks
```

See [docs/implementation/dns-ipam/testing-strategy.md](docs/implementation/dns-ipam/testing-strategy.md) for detailed testing information.

**Note on uv and Ansible**: This project uses `uv pip install` in a virtual environment rather than `uv tool install` to ensure all Ansible executables are available. See [docs/getting-started/uv-ansible-notes.md](docs/getting-started/uv-ansible-notes.md) for details.

## Directory Structure

```text
├── bin/                    # Executable wrapper scripts
│   └── ansible-connect     # Legacy 1Password wrapper (deprecated)
├── docs/                   # Documentation
│   ├── infisical-setup-and-migration.md
│   ├── dns-ipam-implementation-plan.md
│   └── troubleshooting.md
├── inventory/              # Dynamic inventory configurations
│   ├── og-homelab/        # Original homelab cluster inventories
│   └── doggos-homelab/    # Doggos cluster inventories
├── playbooks/              # Ansible playbooks
│   ├── assessment/        # Infrastructure assessment playbooks
│   ├── examples/          # Example playbooks
│   └── infrastructure/    # Infrastructure management
├── plugins/               # Custom Ansible plugins
│   └── lookup/           # Custom lookup plugins
├── roles/                 # Ansible roles (future)
├── scripts/              # Support scripts
└── tests/                # Test playbooks

```

## Usage

### Running Commands with Infisical

Use `uv run` to execute Ansible commands with Infisical secret management:

```bash
# List inventory
uv run ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --list

# Run a playbook
uv run ansible-playbook playbooks/site.yml -i inventory/og-homelab/infisical.proxmox.yml

# Ad-hoc command
uv run ansible all -i inventory/og-homelab/infisical.proxmox.yml -m ping
```

### Managing Secrets

See [docs/implementation/secrets-management/infisical-setup.md](docs/implementation/secrets-management/infisical-setup.md) for detailed instructions on:

- Setting up Infisical machine identity
- Organizing secrets in projects and environments
- Using secrets in playbooks and inventories

## Configuration

### Ansible Configuration (`ansible.cfg`)

- Configured for local plugin directories
- Inventory path set to `./inventory`
- Host key checking disabled for development

## Contributing

1. Follow the existing directory structure
2. Use Infisical for all credential management
3. Document any new patterns or integrations
4. Test changes using `uv run` commands

## Troubleshooting

### General Issues
See [docs/getting-started/troubleshooting.md](docs/getting-started/troubleshooting.md) for common issues and solutions.

### Ansible-Nomad Playbooks
For issues with Nomad job deployment and management:
- [Ansible-Nomad Playbook Troubleshooting](docs/troubleshooting/ansible-nomad-playbooks.md)
- [Domain Migration Troubleshooting](docs/troubleshooting/domain-migration.md)

## License

[Your License Here]
