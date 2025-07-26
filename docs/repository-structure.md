# Repository Structure Overview

This document provides a detailed explanation of the repository organization and the purpose of each directory and key file.

## Directory Structure

```text
netbox-ansible/
├── bin/                        # Executable wrapper scripts
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

### `/bin/`

- **ansible-connect** - Universal wrapper script that:
  - Fetches credentials from 1Password Connect
  - Sets up environment variables
  - Handles all ansible commands (playbook, inventory, etc.)
  - Works around macOS-specific issues

### `/docs/`

- **1password-integration.md** - Complete guide for 1Password setup
- **troubleshooting.md** - Common issues and solutions
- **repository-structure.md** - This file
- **archive/** - Original documentation preserved for reference

### `/inventory/`

Organized by environment:

- **og-homelab/proxmox.yml** - Proxmox dynamic inventory configuration

### `/playbooks/`

- **examples/** - Reference implementations
  - `create-proxmox-secret.yml` - How to store secrets in 1Password
  - `1password-connect-example.yml` - Direct API usage examples
- **infrastructure/** - Production playbooks (to be added)

### `/plugins/`

- **lookup/onepassword_connect.py** - Custom lookup plugin for 1Password Connect

### `/scripts/`

- **get-secret-from-connect.py** - Python script to fetch secrets from Connect
- **set-1password-env.sh** - Environment configuration (gitignored)
- **set-1password-env.sh.example** - Template for environment setup

### `/tests/`

- **test_localhost.yml** - Basic connectivity test playbook

## Usage Patterns

### Standard Workflow

1. Set up environment:

   ```bash
   cp scripts/set-1password-env.sh.example scripts/set-1password-env.sh
   # Edit with your values
   ```

2. Run commands through wrapper:

   ```bash
   ./bin/ansible-connect playbook playbooks/site.yml
   ./bin/ansible-connect inventory -i inventory/og-homelab/proxmox.yml --list
   ```

### Direct Ansible Usage

If you prefer not to use the wrapper:

```bash
source scripts/set-1password-env.sh
export PROXMOX_TOKEN_SECRET=$(scripts/get-secret-from-connect.py "Item Name" "field")
ansible-playbook playbooks/site.yml
```

## Security Considerations

- Never commit `scripts/set-1password-env.sh`
- All secrets should be in 1Password
- Use the wrapper script to avoid credential exposure
- Review `.gitignore` regularly

## Future Enhancements

- Add NetBox dynamic inventory alongside Proxmox
- Create reusable roles for common tasks
- Add CI/CD integration examples
- Implement automated testing
