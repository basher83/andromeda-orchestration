# Mise Setup and Environment Management Guide

This guide covers the mise (formerly rtx) integration in the netbox-ansible project, focusing on initial setup and environment switching between local and remote development.

## Quick Start

```bash
# Clone and enter the repository
git clone <repository-url>
cd netbox-ansible

# Run complete setup (installs tools, Python deps, Ansible collections)
mise run setup

# Check your environment status
mise run env:status
```

## Initial Project Setup

### Automated Setup Tasks

The project includes comprehensive setup tasks that handle all dependencies:

#### Full Setup (`mise run setup`)

Performs complete project initialization:

1. Installs all mise-managed tools (Python, uv, Nomad, Consul, Vault, etc.)
2. Creates Python virtual environment
3. Installs Python dependencies with `uv sync --extra dev`
4. Installs Ansible Galaxy collections
5. Sets up pre-commit hooks
6. Verifies Infisical credentials
7. Provides next steps guidance

#### Quick Setup (`mise run setup:quick`)

Minimal setup for getting started fast:

- Creates virtual environment
- Installs Python dependencies
- Installs Ansible collections
- Skips pre-commit hooks

### Manual Setup Steps

If you prefer manual control:

```bash
# Install mise tools
mise install

# Create virtual environment
uv venv

# Install Python dependencies
uv sync --extra dev

# Install Ansible collections
uv run ansible-galaxy collection install -r requirements.yml --force

# (Optional) Setup pre-commit
uv run pre-commit install
```

## Environment Switching

The project supports two environments for accessing your infrastructure:

- **Remote/Tailscale** (default): Access via Tailscale VPN (100.108.219.48)
- **Local/LAN**: Direct LAN access (192.168.11.11)

### Environment Commands

#### Check Current Environment

```bash
mise run env:status
```

Shows:

- Active environment (LOCAL or REMOTE)
- Current service URLs
- Live connectivity status for Nomad, Consul, and Vault

#### Switch to Remote Environment (Tailscale)

```bash
mise run env:remote
eval "$(mise env)"  # Apply to current shell
```

- Uses IPs: 100.108.219.48
- Required: Active Tailscale connection
- This is the default environment

#### Switch to Local Environment (LAN)

```bash
mise run env:local
eval "$(mise env)"  # Apply to current shell
```

- Uses IPs: 192.168.11.11
- Required: Be on the local network
- Modifies `.mise.local.toml` to override defaults

### How Environment Switching Works

1. **Default Configuration** (`.mise.toml`):
   - Contains Tailscale IPs as defaults
   - Always present, never modified by env commands

2. **Local Override** (`.mise.local.toml`):
   - When `[env]` section is active → Local environment
   - When `[env]` section is commented → Remote environment
   - Automatically managed by env commands

3. **Persistence**:
   - Environment choice persists across shell sessions
   - New shells automatically use the selected environment

### Environment Variables Set

Each environment configures:

- `NOMAD_ADDR` - Nomad cluster API endpoint
- `CONSUL_HTTP_ADDR` - Consul API endpoint
- `VAULT_ADDR` - Vault API endpoint
- `NOMAD_REGION` - Set to "global"

## Tool Management

Mise manages both system tools and Python environment:

### Managed Tools

- **Python 3.13.7** - Base Python interpreter
- **uv 0.8.13** - Fast Python package manager
- **ansible-core 2.19.0** - Ansible automation
- **nomad 1.10.4** - Container orchestration CLI
- **consul 1.21.4** - Service mesh CLI
- **vault 1.20.2** - Secrets management CLI
- Plus: ruff, pre-commit, markdownlint, and more

### Python/Ansible Environment

- Python packages managed by uv in `.venv/`
- Always use `uv run` prefix for Ansible commands:

  ```bash
  uv run ansible-playbook playbooks/site.yml
  uv run ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --list
  ```

## Available Task Categories

Mise provides organized tasks for common operations:

### Setup & Configuration

- `mise run setup` - Complete project setup
- `mise run setup:quick` - Quick setup (deps only)
- `mise run setup:mcp` - MCP configuration setup

### Environment Management

- `mise run env:status` - Show current environment
- `mise run env:local` - Switch to local LAN
- `mise run env:remote` - Switch to Tailscale
- `mise run env:test` - Test connectivity

### Nomad Operations

- `mise run status:nomad` - Cluster status
- `mise run deploy:traefik` - Deploy load balancer
- `mise run deploy:powerdns` - Deploy DNS server
- `mise run logs:nomad -- <alloc-id>` - View logs
- `mise run validate:nomad` - Validate job files

### Consul Operations

- `mise run status:consul` - Cluster status
- `mise run services:consul` - List services
- `mise run health:consul` - Health checks
- `mise run kv:list` - List KV store keys
- `mise run dns:consul -- <service>` - Test DNS

### Vault Operations

- `mise run status:vault` - Show status
- `mise run secrets:list` - List secrets
- `mise run secret:get -- <path>` - Get secret
- `mise run health:vault` - Health check

### Development Tools

- `mise run lint:python` - Python linting
- `mise run lint:ansible` - Ansible linting
- `mise run lint:nomad` - Nomad file linting
- `mise run fix:markdown` - Fix markdown issues

View all available tasks with: `mise tasks`

## Directory Hooks

When you enter the project directory, mise automatically:

1. Installs/updates tools if needed
2. Shows current environment (LOCAL or REMOTE)
3. Checks if Python/Ansible setup is complete
4. Displays available environment commands

## Troubleshooting

### Environment Not Switching

After running `env:local` or `env:remote`:

```bash
# Apply to current shell
eval "$(mise env)"

# Or start new shell session
exec $SHELL
```

### Python Dependencies Failed

If `infisical-python` fails (Windows-only package):

```bash
# Use quick setup to skip problematic extras
mise run setup:quick
```

### Verify Tool Versions

```bash
mise list          # Show installed tools
mise doctor        # Check mise configuration
mise env           # Show all environment variables
```

### Reset Environment

```bash
# Reset to remote/default
rm .mise.local.toml
mise run env:remote

# Force reinstall everything
rm -rf .venv
mise run setup
```

## Next Steps

1. Run `mise run setup` to initialize the project
2. Use `mise run env:status` to verify connectivity
3. Explore available tasks with `mise tasks`
4. Run playbooks with `uv run ansible-playbook`

For more details on specific components:

- See [UV and Ansible Notes](./uv-ansible-notes.md) for Python environment details
- See [Repository Structure](./repository-structure.md) for project organization
- See main [README](../../README.md) for Ansible usage examples
