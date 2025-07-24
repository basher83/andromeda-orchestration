# Code Style and Conventions

## Ansible Style Guide
- Follow ansible-lint rules (configured in `.ansible-lint`)
- Use YAML files with `.yml` extension (not `.yaml`)
- Indent with 2 spaces
- Use explicit task names that describe the action
- Group related tasks using blocks
- Use handlers for service restarts

## Python Code Style
- Follow PEP 8 with ruff configuration
- Use type hints for function signatures
- Maximum line length: 88 characters (Black default)
- Import ordering: standard library, third-party, local
- Docstrings for all public functions/classes

## File Organization
```
playbooks/
├── assessment/         # Infrastructure assessment playbooks
├── consul/            # Consul-related playbooks
├── powerdns/          # PowerDNS deployment playbooks
├── netbox/            # NetBox deployment playbooks
├── examples/          # Example playbooks for reference
└── infrastructure/    # General infrastructure management

roles/
└── consul_service/    # Reusable Ansible roles

inventory/
├── og-homelab/        # Original homelab cluster
└── doggos-homelab/    # New 3-node cluster
```

## Naming Conventions
- Playbooks: descriptive-action.yml (e.g., `consul-health-check.yml`)
- Variables: snake_case (e.g., `proxmox_token_secret`)
- Inventory groups: lowercase with underscores (e.g., `proxmox_all_qemu`)
- Tags: lowercase, hyphenated (e.g., `nomad`, `staging`, `terraform`)

## Secret Management
- NEVER hardcode credentials
- Use 1Password lookups for all secrets
- Environment variables for API tokens
- Vault parameter required for 1Password Connect lookups

## Documentation
- Markdown format for all docs
- Include examples in playbooks
- Document prerequisites and usage
- Keep CLAUDE.md updated with current focus