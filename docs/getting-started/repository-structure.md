# Repository Structure Overview

This document provides a detailed explanation of the repository organization and the purpose of each directory and key file.

## Directory Structure

```text
andromeda-orchestration/
├── bin/                        # (Archived - see docs/archive/bin/)
├── docs/                       # Documentation
│   ├── archive/               # Archived documentation files
│   ├── diagrams/              # Architecture and flow diagrams
│   ├── infrastructure/        # Infrastructure documentation
│   ├── ai-docs/               # AI assistant documentation
│   └── resources/             # Useful resources and references
├── inventory/                  # Ansible inventories
│   ├── og-homelab/           # Original homelab cluster
│   └── doggos-homelab/       # Doggos cluster (3-node)
├── jobs/                       # Nomad job specifications
├── playbooks/                  # Ansible playbooks
│   ├── assessment/           # Infrastructure assessment
│   ├── consul/               # Consul service management
│   ├── examples/             # Example/reference playbooks
│   ├── infrastructure/       # Infrastructure management
│   │   ├── consul-nomad/    # Integration playbooks
│   │   └── user-management/ # User/SSH management
│   └── nomad/                # Nomad cluster management
├── plugins/                    # Custom Ansible plugins
│   ├── lookup/              # Custom lookup plugins
│   ├── modules/             # Custom Ansible modules
│   └── module_utils/        # Module helper utilities
├── reports/                    # Assessment reports
│   ├── assessment/          # Phase 0 assessments
│   ├── consul/              # Consul health reports
│   ├── dns-ipam/            # DNS/IPAM audits
│   ├── infrastructure/      # Readiness reports
│   └── nomad/               # Nomad assessments
├── roles/                      # Ansible roles
│   ├── consul/              # Consul deployment
│   ├── consul_dns/          # Consul DNS setup
│   ├── nomad/               # Nomad deployment
│   ├── nfs/                 # NFS client setup
│   └── system_base/         # Base system config
├── scripts/                    # Support scripts
└── tests/                      # Test playbooks
```

## Key Files

### Root Directory

- **README.md** - Main project documentation with quick start guide
- **ansible.cfg** - Ansible configuration with project defaults
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

- **lookup/** - Legacy lookup plugins (use Infisical instead)
- **modules/** - Custom Ansible modules for Consul and Nomad
  - `consul_acl_*` - Consul ACL management
  - `nomad_job*` - Nomad job deployment
  - `consul_get_service_detail` - Service discovery
- **module_utils/** - Shared module utilities
  - `consul.py` - Consul API client
  - `nomad.py` - Nomad API client
  - `utils.py` - Common helpers

### `/roles/`

- **consul/** - HashiCorp Consul deployment and configuration
- **consul_dns/** - Consul DNS resolution setup (Phase 1)
- **nomad/** - HashiCorp Nomad deployment and configuration
- **nfs/** - NFS client configuration for shared storage
- **system_base/** - Base system configuration (firewall, Docker, SSH)

### `/scripts/`

- **setup.sh** - Quick setup script for new users
- **test-assessment-playbooks.sh** - Test assessment playbook execution
- **scan-secrets.sh** - Infisical secret scanning
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

## Recent Updates (2025-07-30)

- **Imported Roles**: Brought in consul, nomad, nfs, and system_base roles from terraform-homelab
- **Custom Modules**: Added Consul and Nomad management modules with utilities
- **New Role**: Created consul_dns role for Phase 1 DNS implementation
- **Phase 1 Playbooks**: Added infrastructure playbooks for Consul DNS foundation

## Future Enhancements

- Add NetBox dynamic inventory alongside Proxmox
- Create PowerDNS deployment role (Phase 2)
- Add NetBox integration role (Phase 3)
- Implement automated testing with Molecule
