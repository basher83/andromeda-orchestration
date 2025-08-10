# Netdata Role Migration Guide

## Overview

The monolithic `netdata` role has been refactored into smaller, focused roles for better maintainability and flexibility.

## New Role Structure

### Core Roles

1. **netdata_install** - Handles Netdata installation
2. **netdata_configure** - Basic Netdata configuration
3. **netdata_streaming** - Parent/child streaming setup
4. **netdata_cloud** - Cloud claiming functionality
5. **netdata_consul** - Consul integration
6. **netdata_consul_template** - Consul template integration (optional)

## Migration Steps

### 1. Update Your Playbooks

#### Old Way (Monolithic Role)

```yaml
- name: Deploy Netdata
  hosts: all
  roles:
    - role: netdata
      vars:
        netdata_streaming_enabled: true
        netdata_consul_enabled: true
        netdata_claim_token: "xxx"
```

#### New Way (Modular Roles)

```yaml
- name: Deploy Netdata
  hosts: all
  tasks:
    - name: Install Netdata
      ansible.builtin.include_role:
        name: netdata_install

    - name: Configure Netdata
      ansible.builtin.include_role:
        name: netdata_configure

    - name: Setup streaming
      ansible.builtin.include_role:
        name: netdata_streaming
      vars:
        netdata_node_type: "child"
      when: streaming_enabled | default(false)
```

### 2. Update Group Variables

#### Old Structure

```yaml
# group_vars/all/netdata.yml
netdata_install_method: "package"
netdata_streaming_enabled: true
netdata_consul_enabled: true
# ... 200+ lines of variables
```

#### New Structure

```yaml
# group_vars/all/netdata_install.yml
netdata_install_method: "repository"
netdata_repository_channel: "stable"

# group_vars/netdata_children/streaming.yml
netdata_node_type: "child"
netdata_streaming_destination: "parent.example.com:19999"

# group_vars/all/netdata_consul.yml (optional)
netdata_consul_enabled: true
netdata_consul_service_name: "netdata"
```

### 3. Variable Mapping

| Old Variable | New Role | New Variable |
|-------------|----------|--------------|
| `netdata_install_method` | netdata_install | Same |
| `netdata_streaming_enabled` | netdata_streaming | `netdata_node_type` (child/parent) |
| `netdata_consul_enabled` | netdata_consul | Same |
| `netdata_claim_token` | netdata_cloud | Same |
| `netdata_memory_mode` | netdata_configure | Same |
| `netdata_bind_to` | netdata_configure | Same |

### 4. Conditional Inclusion

Use role inclusion based on your needs:

```yaml
- name: Full Netdata deployment
  hosts: all
  tasks:
    # Always install and configure
    - ansible.builtin.import_role:
        name: netdata_install
    - ansible.builtin.import_role:
        name: netdata_configure

    # Only for streaming nodes
    - ansible.builtin.import_role:
        name: netdata_streaming
      when: netdata_node_type is defined

    # Only if using Consul
    - ansible.builtin.import_role:
        name: netdata_consul
      when: consul_available | default(false)

    # Only for cloud claiming
    - ansible.builtin.import_role:
        name: netdata_cloud
      when: netdata_claim_token is defined
```

## Benefits of Migration

1. **Reduced Complexity** - Each role has a focused purpose
2. **Better Testing** - Easier to test individual components
3. **Selective Deployment** - Only use the roles you need
4. **Cleaner Dependencies** - No unnecessary features loaded
5. **Improved Performance** - Faster playbook execution

## Backward Compatibility

To maintain backward compatibility during migration:

1. Keep the old role available but deprecated
2. Create a wrapper playbook that maps old variables to new roles
3. Gradually migrate playbooks to use new roles directly

## Testing Migration

1. Test in development environment first
2. Verify all features work as expected
3. Check streaming connections
4. Verify Consul registration
5. Confirm cloud claiming status

## Rollback Plan

If issues arise:

1. Revert to using the monolithic role
2. File issues for any problems encountered
3. Wait for fixes before attempting migration again

## Support

For questions or issues during migration:

- Check role documentation in each role's README.md
- Review example playbooks in `playbooks/infrastructure/monitoring/`
- Open issues in the repository for bugs or feature requests
