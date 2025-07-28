# Repository Structure Overview

This document provides a detailed explanation of the repository organization and the purpose of each directory and key file.

## Directory Structure

```text
netbox-ansible/
├── bin/                        # (Archived - see docs/archive/bin/)
├── docs/                       # Documentation
│   └── archive/               # Original documentation files
├── inventory/                  # Ansible inventories
│   └── og-homelab/           # Environment-specific inventory
├── playbooks/                  # Ansible playbooks
│   ├── examples/             # Example/reference playbooks
│   └── infrastructure/       # Production playbooks
├── plugins/                    # Custom Ansible plugins
│   └── lookup/              # Custom lookup plugins
├── roles/                      # Ansible roles (future)
├── scripts/                    # Support scripts
└── tests/                      # Test playbooks
```

## Key Files

### Root Directory

- **README.md** - Main project documentation with quick start guide
- **ansible.cfg** - Ansible configuration with project defaults
- **execution-environment.yml** - Container environment specification
- **CLAUDE.md** - AI assistant guidance for code changes
- **.gitignore** - Git ignore patterns for secrets and temp files

### `/bin/` (Archived)

This directory has been archived to `docs/archive/bin/` as it contained only deprecated scripts:
- **ansible-connect** - Legacy 1Password wrapper replaced by direct `uv run` commands with Infisical

### `/docs/`

- **infisical-setup-and-migration.md** - Primary secrets management guide (Infisical)
- **1password-integration.md** - Legacy 1Password setup (deprecated)
- **secrets-management-comparison.md** - Comparison of 1Password vs Infisical
- **troubleshooting.md** - Common issues and solutions
- **repository-structure.md** - This file
- **archive/** - Original documentation preserved for reference

### `/inventory/`

Organized by environment:

- **og-homelab/**
  - `infisical.proxmox.yml` - Proxmox dynamic inventory with Infisical (recommended)
  - `1password.proxmox.yml` - Proxmox dynamic inventory with 1Password (deprecated)
- **doggos-homelab/**
  - `infisical.proxmox.yml` - Proxmox dynamic inventory with Infisical (recommended)
  - `1password.proxmox.yml` - Proxmox dynamic inventory with 1Password (deprecated)

### `/playbooks/`

- **examples/** - Reference implementations
  - `create-proxmox-secret.yml` - How to store secrets in 1Password
  - `1password-connect-example.yml` - Direct API usage examples
- **infrastructure/** - Production playbooks (to be added)

### `/plugins/`

- **lookup/onepassword_connect.py** - Custom lookup plugin for 1Password Connect

### `/scripts/`

- **setup.sh** - Quick setup script for new users
- **get-secret-from-connect.py** - Legacy 1Password Connect script (deprecated)
- **set-1password-env.sh** - Legacy 1Password environment config (deprecated)
- **set-1password-env.sh.example** - Legacy template (deprecated)

### `/tests/`

- **test_localhost.yml** - Basic connectivity test playbook

## Usage Patterns

### Standard Workflow

1. Set up environment:

   ```bash
   # Install uv and set up Python environment
   ./scripts/setup.sh
   
   # Configure Infisical machine identity
   export INFISICAL_MACHINE_IDENTITY_CLIENT_ID="your-client-id"
   export INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET="your-client-secret"
   ```

2. Run commands with uv:

   ```bash
   # Use Infisical inventory files (recommended)
   uv run ansible-playbook playbooks/site.yml -i inventory/og-homelab/infisical.proxmox.yml
   uv run ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --list
   
   # Legacy 1Password method (deprecated - script archived)
   # ./bin/ansible-connect playbook playbooks/site.yml
   ```

### Direct Ansible Usage

For direct ansible commands without uv:

```bash
# Set up Infisical credentials
export INFISICAL_MACHINE_IDENTITY_CLIENT_ID="your-client-id"
export INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET="your-client-secret"

# Run ansible directly
ansible-playbook playbooks/site.yml -i inventory/og-homelab/infisical.proxmox.yml
```

## Security Considerations

- Never commit Infisical machine identity credentials
- All secrets should be stored in Infisical
- Use environment variables for authentication
- Review `.gitignore` regularly
- Legacy 1Password files should not be used for new implementations

## Future Enhancements

- Add NetBox dynamic inventory alongside Proxmox
- Create reusable roles for common tasks
- Add CI/CD integration examples
- Implement automated testing
