# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NetBox-focused Ansible automation project that integrates NetBox as a source of truth for network infrastructure management. The project uses containerized Ansible execution environments, dynamic inventory management, and secure credential management through 1Password.

## Commands

### Running Playbooks with 1Password Integration
```bash
# Using the wrapper script (recommended - handles credential retrieval)
./bin/ansible-connect playbook playbooks/site.yml

# Direct ansible-navigator usage
ansible-navigator run <playbook.yml> --execution-environment-image ghcr.io/ansible-community/community-ee-minimal:latest --mode stdout
```

### Working with Dynamic Inventory
```bash
# Test Proxmox inventory with 1Password integration
./bin/ansible-connect inventory -i inventory/og-homelab/proxmox.yml --list

# Graph inventory structure
./bin/ansible-connect inventory -i inventory/og-homelab/proxmox.yml --graph
```

## Architecture

### Inventory Management
- **Directory**: `inventory/` contains all dynamic inventory configurations
- **Current Implementation**: Proxmox dynamic inventory using `community.general.proxmox` plugin
- **Planned**: NetBox dynamic inventory integration (see `docs/netbox.md` for patterns)
- **Authentication**: Uses API tokens stored in environment variables

### Execution Environment
- Based on `community-ee-minimal` container image
- Includes `ansible-core`, `ansible-runner`, and `community.general` collection
- Configured in `execution-environment.yml`

### Documentation Structure
- `docs/netbox.md`: Comprehensive NetBox integration patterns including:
  - Dynamic inventory configuration
  - State management with NetBox modules
  - Runtime data queries with `netbox.netbox.nb_lookup`
  - Event-driven automation patterns
  
- `docs/1pass.md`: 1Password Connect integration for secrets management:
  - Vault item lookups using `community.general.onepassword_raw`
  - Secret injection patterns
  - Error handling strategies

### Key Integration Patterns

1. **NetBox as Source of Truth**
   - All network device information should be queried from NetBox
   - Device configurations should be generated based on NetBox data
   - State changes should be reflected back in NetBox

2. **Dynamic Inventory Grouping**
   - Devices grouped by NetBox attributes (site, role, platform, tags)
   - Custom grouping via `keyed_groups` and `compose` directives
   - Ansible variables composed from NetBox custom fields

3. **Secret Management**
   - Never hardcode credentials
   - Use 1Password Connect for secret retrieval
   - Environment variables for API tokens

## Important Considerations

- The project is in early development with minimal implementation
- Follow the patterns established in the documentation when implementing new features
- Use the execution environment for consistency across different systems
- Always test inventory plugins with `ansible-inventory` before running playbooks
- NetBox integration should follow the patterns in `docs/netbox.md`

## Recommended Tools

- For enhanced searching via bash commands use eza, fd, and rg