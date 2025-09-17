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

- **Python** 3.9+ with **uv** package manager
- **Ansible** 2.15+ with ansible-core
- **Ansible Galaxy Collections** (see `requirements.yml`):
  - `infisical.vault` - Secrets management
  - `community.general` - General purpose modules
  - `community.hashi_vault` - HashiCorp Vault modules
  - `ansible.utils` - Utility modules and filters
- **Python Packages** (required for Ansible collections):
  - `netaddr` (python3-netaddr) - Required for `ansible.utils.ipaddr` filter
- **Infisical** account and machine identity
- **macOS** users: Local Network permissions for Python (see [Troubleshooting](docs/getting-started/troubleshooting.md))
- Docker (optional, for execution environments)

### Python Dependencies

The project uses **uv** for dependency management. Available dependency groups:

- **Core dependencies**: Basic runtime requirements
  - `netaddr` - Required for IP address validation and `ansible.utils.ipaddr` filter
- **Dev dependencies**: Development tools (`ansible-lint`, `pytest`, `ruff`, `mypy`, etc.)
- **Secrets dependencies**: Infisical SDK for secrets management

## Quick Start

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd andromeda-orchestration
   ```

1. **Install Python dependencies**

   ```bash
   # Install core Python dependencies
   uv sync

   # For development (optional - includes ansible-lint, pytest, ruff, etc.)
   uv sync --extra dev

   # For secrets management (optional - includes infisical SDK)
   uv sync --extra secrets

   # For both development and secrets (combine extras)
   uv sync --extra dev --extra secrets
   ```

1. **Install Ansible Galaxy collections**

   ```bash
   # Install required Ansible collections (community.general, infisical.vault, etc.)
   uv run ansible-galaxy collection install -r requirements.yml

   # Note: This command is idempotent and uses local caching.
   # Re-running will skip already-installed collections and only download missing/updated ones.
   # Use --force to re-download all collections if needed.
   ```

1. **Run the setup script**

   ```bash
   ./scripts/setup.sh
   # Or use mise for complete setup with dev tools
   mise run setup
   ```

   The setup script will:
   - Verify prerequisites (Ansible, Python)
   - Install Ansible Galaxy collections (if not already done)
   - Set up Python virtual environment with uv
   - Create necessary directory structure

1. **Configure secrets and authentication**

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

### Service Endpoints (`inventory/environments/all/service-endpoints.yml`)

Centralized service endpoint configuration to avoid hardcoded IPs:

- **Consul**: `{{ service_endpoints.consul.addr }}`
- **Nomad**: `{{ service_endpoints.nomad.addr }}`
- **Vault**: `{{ service_endpoints.vault.addr }}`

#### Mandatory IP Validation

All playbooks must include the pre_tasks validator to enforce no hardcoded IPv4/IPv6 literals:

pre_tasks:
  - name: Enforce dynamic-inventory pattern (no hardcoded IPs)
    ansible.builtin.import_tasks: "{{ playbook_dir }}/../../../tasks/validate-no-hardcoded-ips.yml"
    vars:
      validate_allowlist:
        - '127.0.0.1'
        - '::1'
    tags: ['validate']

Override via environment variables:

```bash
# Export examples (add to ~/.bashrc or run before ansible commands)
export CONSUL_HTTP_ADDR="http://consul.service.consul:8500"
export NOMAD_ADDR="http://nomad.service.consul:4646"
export VAULT_ADDR="https://vault.service.consul:8200"

# One-off command example (sets VAULT_ADDR for single command)
VAULT_ADDR="https://vault.service.consul:8200" uv run ansible-playbook playbook.yml
```

Defaults to service discovery addresses with direct IP fallbacks.

Note: To comply with the no-hardcoded-IP policy, avoid committing private IP
defaults in shared inventory. If direct access is required, provide values via
environment variables or in environment-specific inventory only, and update the
IP-validation allowlist accordingly.
