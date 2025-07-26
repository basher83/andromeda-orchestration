# NetBox Ansible Automation

[![CI](https://github.com/YOUR_USERNAME/netbox-ansible/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/netbox-ansible/actions/workflows/ci.yml)

An Ansible automation project that integrates NetBox as a source of truth for network infrastructure management, with
secure credential management through 1Password.

## Overview

This project provides a framework for managing network infrastructure using Ansible with:

- Dynamic inventory from Proxmox (current) and NetBox (planned)
- Secure credential management via 1Password (CLI and Connect)
- Containerized execution environments
- Best practices for Ansible project organization

## Prerequisites

- **Ansible** 2.15+ with ansible-core
- **Python** 3.9+
- **1Password CLI** or **1Password Connect** server
- **macOS** users: Local Network permissions for Python (see Troubleshooting)
- Docker (optional, for execution environments)

## Quick Start

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd netbox-ansible
   ```

2. **Run the setup script**

   ```bash
   ./scripts/setup.sh
   # Or use task for complete setup with dev tools
   task setup
   ```

3. **Configure 1Password integration**

   ```bash
   # Edit the environment file created by setup
   vi scripts/set-1password-env.sh
   ```

4. **Test the setup**

   ```bash
   ./bin/ansible-connect inventory -i inventory/og-homelab/proxmox.yml --list
   ```

## Development

### Code Quality Tools

This project uses comprehensive linting and testing:

- **ansible-lint** - Ansible best practices and style guide
- **yamllint** - YAML file formatting
- **ruff** - Python linting and formatting
- **mypy** - Python type checking
- **pre-commit** - Git hooks for automated checks (see [docs/pre-commit-setup.md](docs/pre-commit-setup.md))

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

# Run security scans
task security

# Run pre-commit hooks manually
task hooks
```

See [docs/testing-strategy.md](docs/testing-strategy.md) for detailed testing information.

**Note on uv and Ansible**: This project uses `uv pip install` in a virtual environment rather than `uv tool install` to ensure all Ansible executables are available. See [docs/uv-ansible-notes.md](docs/uv-ansible-notes.md) for details.

## Directory Structure

```text
├── bin/                    # Executable wrapper scripts
│   └── ansible-connect     # Main wrapper for 1Password integration
├── docs/                   # Documentation
│   ├── 1password-integration.md
│   └── troubleshooting.md
├── inventory/              # Dynamic inventory configurations
│   └── og-homelab/        # Environment-specific inventories
├── playbooks/              # Ansible playbooks
│   ├── examples/          # Example playbooks
│   └── infrastructure/    # Infrastructure management
├── plugins/               # Custom Ansible plugins
│   └── lookup/           # Custom lookup plugins
├── roles/                 # Ansible roles (future)
├── scripts/              # Support scripts
└── tests/                # Test playbooks

```

## Usage

### Running Commands with 1Password Integration

Use the `ansible-connect` wrapper to automatically handle credential retrieval:

```bash
# List inventory
./bin/ansible-connect inventory -i inventory/og-homelab/proxmox.yml --list

# Run a playbook
./bin/ansible-connect playbook playbooks/site.yml

# Ad-hoc command
./bin/ansible-connect all -i inventory/og-homelab/proxmox.yml -m ping
```

### Managing Secrets

See [docs/1password-integration.md](docs/1password-integration.md) for detailed instructions on:

- Setting up 1Password CLI or Connect
- Storing credentials securely
- Using credentials in playbooks and inventories

## Configuration

### Ansible Configuration (`ansible.cfg`)

- Configured for local plugin directories
- Inventory path set to `./inventory`
- Host key checking disabled for development

### Execution Environment

- Uses `community-ee-minimal` container
- Configuration in `execution-environment.yml`
- Includes required collections and dependencies

## Contributing

1. Follow the existing directory structure
2. Use the 1Password integration for all credentials
3. Document any new patterns or integrations
4. Test changes with the provided wrapper scripts

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for common issues and solutions.

## License

[Your License Here]
