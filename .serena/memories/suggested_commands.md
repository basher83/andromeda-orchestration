# Suggested Commands for NetBox Ansible Development

## Environment Setup
```bash
# Source 1Password environment variables (REQUIRED before running any commands)
source ./scripts/set-1password-env.sh

# Activate Python virtual environment
source .venv/bin/activate
```

## Common Ansible Commands
```bash
# Test inventory connectivity
./bin/ansible-connect inventory -i inventory/og-homelab/proxmox.yml --list
./bin/ansible-connect inventory -i inventory/doggos-homelab/proxmox.yml --list

# Run playbooks
./bin/ansible-connect playbook playbooks/assessment/consul-health-check.yml
./bin/ansible-connect playbook playbooks/site.yml

# Ad-hoc commands
./bin/ansible-connect all -i inventory/doggos-homelab/proxmox.yml -m ping
```

## Development Commands
```bash
# Run all linters
task lint

# Auto-fix linting issues
task fix

# Run tests
task test

# Run security scans
task security

# Run pre-commit hooks manually
task hooks

# Clean up generated files
task clean
```

## System Utilities (Darwin/macOS)
```bash
# Enhanced tools recommended in CLAUDE.md
rg <pattern>         # ripgrep for fast searching
fd <pattern>         # fd for finding files
eza                  # modern ls replacement

# Standard tools
git status/add/commit/push
ls -la              # List files with details
grep -r "pattern" . # Recursive search
find . -name "*.yml" # Find files by pattern
```

## Quick Testing
```bash
# Check playbook syntax
ansible-playbook playbooks/examples/*.yml --syntax-check

# Validate inventory
ansible-inventory -i inventory/doggos-homelab/proxmox.yml --list

# Test specific hosts
./bin/ansible-connect nomad-server-1-lloyd -i inventory/doggos-homelab/proxmox.yml -m setup
```