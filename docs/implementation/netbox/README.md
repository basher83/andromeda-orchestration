# NetBox Implementation Documentation

NetBox as the source of truth for network infrastructure automation.

## 📚 Documentation

### Core Integration
- **[integration.md](integration.md)** - Comprehensive NetBox automation with Ansible
  - Dynamic inventory configuration
  - State management with NetBox modules
  - Runtime data queries with nb_lookup
  - Event-driven automation patterns
  - Best practices and troubleshooting

### Planned Documentation
- **ipam-migration.md** - Migration from ad-hoc IPAM to NetBox (planned)
- **device-onboarding.md** - Automated device discovery and onboarding (planned)
- **custom-fields.md** - Custom field patterns for automation (planned)

## 🚀 Quick Start

### Dynamic Inventory Setup
```yaml
# netbox_inv.yml
---
plugin: netbox.netbox.nb_inventory
validate_certs: False
group_by:
  - device_roles
  - sites
  - platforms

# Environment variables
export NETBOX_API="https://netbox.example.com"
export NETBOX_TOKEN="your-api-token-here"

# Test inventory
ansible-inventory -i netbox_inv.yml --list
```

### Basic NetBox Operations
```bash
# Install NetBox collection
ansible-galaxy collection install netbox.netbox

# Run NetBox playbook
uv run ansible-playbook playbooks/infrastructure/netbox/populate-ipam.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

## 📋 Implementation Status

### ✅ Completed
- Comprehensive integration patterns documentation
- Dynamic inventory configuration examples
- State management patterns
- Event-driven automation patterns

### 🚧 In Progress
- Phase 3 NetBox deployment planning

### ⏳ Planned
- NetBox deployment in Nomad
- IPAM data migration
- Device discovery integration
- Custom field standardization

## 🏗️ Architecture Overview

### NetBox as Source of Truth
```
┌─────────────────────────────────────────┐
│            NetBox Database              │
├─────────────────────────────────────────┤
│  DCIM        │  IPAM       │  Extras    │
│  • Devices   │  • Prefixes │  • Config  │
│  • Cables    │  • IPs      │  • Tags    │
│  • Racks     │  • VLANs    │  • Webhooks│
└─────────────────────────────────────────┘
          │            │            │
    ┌─────▼────────────▼────────────▼─────┐
    │        NetBox REST API              │
    └─────────────────┬────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼────┐     ┌──────▼──────┐   ┌─────▼────┐
│ Ansible │     │   Diode     │   │   orb    │
│Inventory│     │   Import    │   │Discovery │
└─────────┘     └─────────────┘   └──────────┘
```

### Integration Points
- **Ansible**: Dynamic inventory, modules, lookups
- **Consul**: Service registration from NetBox data
- **Nomad**: Job generation based on NetBox devices
- **PowerDNS**: DNS records from IPAM data
- **Monitoring**: Icinga configuration from devices

## 📁 Related Resources

### Playbooks
- `playbooks/infrastructure/netbox/` (to be created)
  - `populate-ipam.yml`
  - `device-discovery.yml`
  - `sync-dns.yml`

### Inventory
- Dynamic inventory plugin configuration
- Group variables for NetBox integration

### Phase 3 Planning
- Part of DNS & IPAM overhaul
- See [DNS & IPAM Implementation Plan](../dns-ipam/implementation-plan.md)

## 🔑 Key Decisions

### Why NetBox?
- Single source of truth for network data
- Comprehensive API for automation
- Extensible with custom fields
- Built-in change tracking
- Webhook support for event-driven automation

### Integration Approach
- **Dynamic Inventory**: Real-time device data
- **State Management**: NetBox modules for CRUD operations
- **Data Queries**: Runtime lookups for configuration
- **Event-Driven**: Webhooks trigger Ansible workflows

### Data Model Strategy
- Standard NetBox models for common data
- Custom fields for organization-specific needs
- Config contexts for hierarchical configuration
- Tags for flexible grouping

## 📊 Implementation Phases

| Phase | Focus | Duration | Status |
|-------|-------|----------|--------|
| 1 | NetBox Deployment | 1 week | ⏳ Planned |
| 2 | IPAM Migration | 2 weeks | ⏳ Planned |
| 3 | Device Onboarding | 1 week | ⏳ Planned |
| 4 | DNS Integration | 1 week | ⏳ Planned |
| 5 | Automation Workflows | 2 weeks | ⏳ Planned |

## 🔧 Common Patterns

### Dynamic Inventory Groups
```yaml
# Groups created automatically:
@device_roles_router
@device_roles_switch
@sites_datacenter
@platforms_ios
@manufacturers_cisco
```

### State Management
```yaml
# IPAM object creation
- netbox.netbox.netbox_prefix:
    data:
      prefix: "10.0.0.0/24"
      site: "Main Office"
      role: "Management"
    state: present

# Device creation
- netbox.netbox.netbox_device:
    data:
      name: "sw-core-01"
      device_type: "Catalyst 9300"
      site: "Main Office"
    state: present
```

### Data Queries
```yaml
# Runtime lookups
- set_fact:
    site_devices: "{{ query('netbox.netbox.nb_lookup', 'devices',
      api_filter='site=main-office') }}"
```

## 🛠️ Troubleshooting

### Common Issues
- **Empty inventory**: Check API URL and token
- **Module not found**: Install netbox.netbox collection
- **API errors**: Verify user permissions in NetBox
- **SSL errors**: Set `validate_certs: False` for self-signed certs

### Debug Commands
```bash
# Test NetBox connectivity
curl -H "Authorization: Token ${NETBOX_TOKEN}" "${NETBOX_API}/api/status/"

# Verify inventory
ansible-inventory -i netbox_inv.yml --graph

# Debug playbook
ansible-playbook playbook.yml -vvv
```

## 📚 Further Reading

- [NetBox Documentation](https://docs.netbox.dev/)
- [NetBox Ansible Collection](https://docs.ansible.com/ansible/latest/collections/netbox/netbox/)
- [NetBox Learning Repository](https://github.com/netboxlabs/netbox-learning)
