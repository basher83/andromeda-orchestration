# Andromeda Orchestration

---

![GitHub last commit](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration?path=README.md&display_timestamp=author&style=plastic&logo=github)
[![CI](https://github.com/basher83/andromeda-orchestration/actions/workflows/ci.yml/badge.svg)](https://github.com/basher83/andromeda-orchestration/actions/workflows/ci.yml)
[![MegaLinter](https://github.com/basher83/andromeda-orchestration/workflows/MegaLinter/badge.svg?branch=main)](https://github.com/basher83/andromeda-orchestration/actions?query=workflow%3AMegaLinter+branch%3Amain)

![Ansible](https://img.shields.io/badge/Ansible-000000?style=plastic&logo=ansible&logoColor=)

![Proxmox](https://img.shields.io/badge/Proxmox-000000?style=plastic&logo=proxmox&logoColor=)

![Vault](https://img.shields.io/badge/Vault-000000?style=plastic&logo=vault&logoColor=)
![Nomad](https://img.shields.io/badge/Nomad-000000?style=plastic&logo=nomad&logoColor=)
![Consul](https://img.shields.io/badge/Consul-000000?style=plastic&logo=consul&logoColor=)

![Tailscale](https://img.shields.io/badge/Tailscale-000000?style=plastic&logo=tailscale&logoColor=)

![NetBox](https://img.shields.io/badge/NetBox-000000?style=plastic&logo=netbox&logoColor=)
![Infisical](https://img.shields.io/badge/Infisical-000000?style=plastic&logo=infisical&logoColor=)

<p align="center">
  <img src="https://raw.githubusercontent.com/basher83/assets/refs/heads/main/space-gifs/undraw_space-exploration_dhu1.svg" alt="Space Exploration" width="400">
</p>

An Ansible automation project for comprehensive homelab infrastructure management, with NetBox integration for network
source-of-truth and secure credential management through Infisical.

## Overview

This project provides a framework for managing network infrastructure using Ansible with:

- Multiple dynamic inventory sources (Proxmox, NetBox, Tailscale)
- Secure credential management via Infisical
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
   # Or use mise for complete setup with dev tools
   mise run setup
   ```

3. **Configure secrets and authentication**

## SECURITY: Never commit .mise.local.toml; it is gitignored and must stay local

```bash
# Copy the template and add your secrets
cp .mise.local.toml.example .mise.local.toml

# Edit with your actual tokens and credentials
# The file is gitignored and won't be committed
$EDITOR .mise.local.toml

# Mise will automatically load these environment variables
```

1. **Test the setup**

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
mise tasks

# Run all linters
mise run lint

# Ultra-fast MegaLinter testing (no Node.js required)
mise run act-fast
# Or: ./scripts/mega-linter-runner.sh

# Streamlined local testing with GHCR registry (recommended)
mise run megalinter-local
# Or: ./scripts/run-megalinter-local.sh

# Run tests
mise run test

# Run security scans (Infisical + KICS)
mise run security

# Run individual security scans
mise run security:secrets  # Infisical secrets detection
mise run security:kics     # Infrastructure security scan

# Check cluster health
mise run status

# Setup development environment
mise run setup
```

See [docs/implementation/dns-ipam/testing-strategy.md](docs/implementation/dns-ipam/testing-strategy.md) for detailed testing information.

**MegaLinter Status**: The badge above shows the status of our automated code quality checks. Green means all linters pass! For fast local testing without Node.js dependencies, use `mise run act-fast`.

**Configuration Organization**: Linter configuration files (`.ansible-lint`, `.yamllint`, `.markdownlint.json`) in the repository root are symbolic links pointing to organized configurations in `.github/linters/` for better maintainability while maintaining backward compatibility.

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

![GitHub License](https://img.shields.io/github/license/basher83/andromeda-orchestration?style=plastic)
