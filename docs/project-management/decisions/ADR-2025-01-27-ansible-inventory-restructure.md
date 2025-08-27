# ADR-2025-01-27: Ansible Inventory Restructure for Multi-Source Management

![Status](https://img.shields.io/badge/Status-Accepted-green)
![Date](https://img.shields.io/badge/Date-2025--01--27-lightgrey)
![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/docs/project-management/decisions/ADR-2025-01-27-ansible-inventory-restructure.md)

## Status

Accepted

## Context

The Ansible inventory structure had become problematic with multiple dynamic inventory sources:
- NetBox warnings appearing when using Proxmox inventory due to all YAML files being scanned
- Mixing static and dynamic inventories caused confusion
- Environment variable conflicts between different inventory plugins
- Token management inconsistencies (some using env vars, others using Infisical)
- No clear separation between environments, dynamic sources, and combined inventories
- The default `ansible.cfg` pointed to entire inventory directory, causing all files to be loaded

## Decision

Implement a structured inventory organization with clear separation of concerns:

### New Directory Structure
```
inventory/
├── environments/        # Environment-specific inventories
│   ├── doggos-homelab/  # Primary environment
│   └── og-homelab/      # Legacy environment
├── dynamic/             # Dynamic inventory sources
│   ├── proxmox.yml      # Proxmox plugin config
│   ├── netbox.yml       # NetBox plugin config (with caching)
│   └── tailscale.yml    # Tailscale plugin config
├── static/              # Static inventory files
│   └── tailscale-static.yml  # Fallback for Tailscale
└── combined/            # Future: Combined inventories
```

### Key Changes

1. **Unified Secret Management via Infisical**
   - All inventory plugins now use Infisical for secrets
   - NetBox API token retrieved via Infisical lookup
   - Proxmox credentials via Infisical
   - Consistent pattern across all plugins

2. **NetBox Caching for Resilience**
   - 24-hour cache timeout (86400 seconds)
   - Reduces API calls and improves performance
   - Provides resilience when NetBox is temporarily unavailable

3. **Environment Variables in mise.toml**
   ```toml
   [env]
   ANSIBLE_INVENTORY = "inventory/environments/doggos-homelab"
   ANSIBLE_HOST_KEY_CHECKING = "False"
   ```

4. **Python Virtual Environment Auto-activation**
   ```toml
   [settings]
   python.uv_venv_auto = true
   ```

## Consequences

### Positive
- Clean separation prevents cross-contamination of inventory sources
- NetBox warnings eliminated when using other inventories
- Consistent secret management across all plugins
- 24-hour caching improves performance and reliability
- Environment-based organization makes multi-site management easier
- Auto-activation of Python venv prevents Infisical collection issues

### Negative
- More directories to navigate (mitigated by clear naming)
- Need to specify inventory path more explicitly
- Initial setup slightly more complex for new users

### Risks
- Cache staleness if infrastructure changes rapidly (24-hour window)
- Infisical dependency for all inventory access
- Breaking change for existing playbooks using old paths

## Alternatives Considered

### Alternative 1: Single Flat Directory
- Keep all inventory files in one directory
- Rejected: Caused NetBox warnings and confusion about which files were active

### Alternative 2: Separate Repos for Each Environment
- Split environments into different repositories
- Rejected: Overhead of multiple repos for a solo developer

### Alternative 3: All Static Inventories
- Convert all dynamic sources to static files
- Rejected: Loses benefits of dynamic discovery and automation

## Implementation

1. ✅ Created new directory structure under `inventory/`
2. ✅ Moved existing inventory files to appropriate subdirectories
3. ✅ Updated NetBox inventory with Infisical integration and caching
4. ✅ Configure mise.toml with default inventory path
5. ✅ Updated documentation in `docs/operations/ansible-inventory.md`
6. Test all playbooks with new structure
7. Update CI/CD pipelines if needed

## References

- [Ansible Inventory Documentation](docs/operations/ansible-inventory.md)
- [Infisical Configuration Guide](docs/implementation/infisical/infisical-complete-guide.md)
- [NetBox Dynamic Inventory Plugin](https://docs.ansible.com/ansible/latest/collections/netbox/netbox/nb_inventory_inventory.html)
- Original discussion in today's working session
