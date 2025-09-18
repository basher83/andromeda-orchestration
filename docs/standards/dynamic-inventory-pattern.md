# Dynamic Inventory Pattern Standard

## Core Principle

Infrastructure details (IPs, hostnames, ports) **MUST** come from Ansible inventory as the single source of truth. Hardcoding IPs in playbooks is strictly prohibited.

## Enforcement Mechanism

All playbooks must include `tasks/validate-no-hardcoded-ips.yml` in pre_tasks **before setting any host-like variables**, which uses the `ansible.utils.ipaddr` filter to detect and prevent hardcoded IP addresses. This ensures validation runs first to catch hardcoded values before they get masked by dynamic variable definitions.

## Requirements

### Collections and Libraries

For reproducible installs, add collections to `requirements.yml` and install using `ansible-galaxy collection install -r requirements.yml`:

```yaml
# requirements.yml
collections:
  - name: ansible.utils
    version: "2.10.0"
```

```bash
# Install collections from requirements file
ansible-galaxy collection install -r requirements.yml

# Install Python dependency (choose method based on your setup)
# With uv (recommended for this project):
uv pip install netaddr==0.9.0

# With standard pip:
pip install netaddr==0.9.0
```

## Implementation Pattern

### ❌ VIOLATION: Hardcoded IPs

```yaml
# This WILL FAIL validation - hardcoded IPs in vars
- name: Configure service
  hosts: localhost
  vars:
    # ALL of these are violations:
    database_host: "192.168.1.50" # IPv4 literal
    api_endpoint: "10.0.0.10:8080" # IPv4 with port
    backup_server: "172.16.0.100" # Private range
    ipv6_host: "2001:db8::1" # IPv6 literal
    service_url: "https://192.168.1.10" # IP in URL
    ipv6_url: "https://[2001:db8::1]:8200" # IPv6 in brackets with port - FAILS validation
```

### ❌ VIOLATION: Validation After Variable Definition

```yaml
# This is DANGEROUS - validation runs too late and can miss hardcoded IPs
- name: Configure service
  hosts: localhost
  vars:
    database_host: "192.168.1.50" # Hardcoded IP - will be missed!
  pre_tasks:
    # BAD: Setting variables before validation
    - name: Set API endpoint
      ansible.builtin.set_fact:
        api_endpoint: "10.0.0.10:8080" # Hardcoded IP - will be missed!

    # TOO LATE: Validation runs after variables are already set
    - name: Validate no hardcoded IPs
      ansible.builtin.include_tasks: "{{ playbook_dir }}/../../../tasks/validate-no-hardcoded-ips.yml"
      vars:
        validate_hostlike_vars:
          database_host: "{{ database_host | default('') }}" # Now contains hardcoded IP
          api_endpoint: "{{ api_endpoint | default('') }}" # Now contains hardcoded IP
```

### ✅ CORRECT: Dynamic Discovery from Inventory

```yaml
- name: Configure service
  hosts: localhost
  any_errors_fatal: true
  pre_tasks:
    # CRITICAL: Run validation BEFORE setting any host-like vars to catch hardcoded values
    - name: Validate no hardcoded IPs
      ansible.builtin.include_tasks: "{{ playbook_dir }}/../../../tasks/validate-no-hardcoded-ips.yml"
      vars:
        validate_hostlike_vars:
          # Check any vars that might contain IPs - these should be empty/undefined at this point
          database_host: "{{ database_host | default('') }}"
          api_endpoint: "{{ api_endpoint | default('') }}"
          backup_server: "{{ backup_server | default('') }}"
        validate_allowlist: []

    # After validation passes, discover from inventory
    - name: Set database host from inventory
      ansible.builtin.set_fact:
        database_host: "{{ hostvars[(groups.get('databases', []) + [inventory_hostname])[0]]['ansible_host'] }}"

    - name: Set API endpoint from inventory
      ansible.builtin.set_fact:
        api_endpoint: "{{ hostvars[(groups.get('api_servers', []) + [inventory_hostname])[0]]['ansible_host'] }}:8080"

    - name: Build service list from group
      ansible.builtin.set_fact:
        service_nodes: "{{ groups['services'] | map('extract', hostvars, 'ansible_host') | list }}"
```

## Common Patterns

### Single Host Discovery

```yaml
# Get IP of first host in group (safe with fallback to current host)
leader_ip: "{{ hostvars[(groups.get('leaders', []) + [inventory_hostname])[0]]['ansible_host'] }}"

# Get IP with port (safe with fallback to current host)
service_url: "https://{{ hostvars[(groups.get('services', []) + [inventory_hostname])[0]]['ansible_host'] }}:{{ hostvars[(groups.get('services', []) + [inventory_hostname])[0]].get('service_port', '8443') }}"
```

### Multiple Host Discovery

```yaml
# Get all IPs from a group
all_nodes: "{{ groups['cluster'] | map('extract', hostvars, 'ansible_host') | list }}"

# Build complex structure
- name: Build node list with metadata
  ansible.builtin.set_fact:
    cluster_nodes: |-
      {%- set nodes = [] -%}
      {%- for host in groups.get('cluster', []) -%}
        {%- set node = {
          'name': host,
          'ip': hostvars[host]['ansible_host'],
          'port': hostvars[host].get('service_port', '8080'),
          'role': hostvars[host].get('node_role', 'worker')
        } -%}
        {%- set _ = nodes.append(node) -%}
      {%- endfor -%}
      {{ nodes }}
```

### Using DNS Instead of IPs

```yaml
# Preferred when possible - use DNS names
vars:
  database_host: "db.example.com" # DNS name - passes validation
  api_endpoint: "api.service.consul" # Service discovery - passes validation
```

## Validation Task Usage

### Basic Usage

```yaml
pre_tasks:
  # FIRST TASK: Validate before setting any host-like vars
  - name: Validate no hardcoded IPs
    ansible.builtin.include_tasks: "{{ playbook_dir }}/../../../tasks/validate-no-hardcoded-ips.yml"
    vars:
      validate_hostlike_vars:
        my_host: "{{ my_host | default('') }}" # Should be empty at this point
        my_endpoint: "{{ my_endpoint | default('') }}" # Should be empty at this point

  # AFTER validation: Set variables from inventory
  - name: Set my_host from inventory
    ansible.builtin.set_fact:
      my_host: "{{ hostvars[groups['my_group'][0]]['ansible_host'] }}"
```

### With Allowlist (Use Sparingly)

```yaml
pre_tasks:
  - name: Validate no hardcoded IPs
    ansible.builtin.include_tasks: "{{ playbook_dir }}/../../../tasks/validate-no-hardcoded-ips.yml"
    vars:
      validate_hostlike_vars:
        my_host: "{{ my_host | default('') }}"
        monitoring_ip: "{{ monitoring_ip | default('') }}"
      validate_allowlist:
        - monitoring_ip # Exception: External monitoring service
```

### Verbose Mode for Debugging

```yaml
pre_tasks:
  - name: Validate no hardcoded IPs
    ansible.builtin.include_tasks: "{{ playbook_dir }}/../../../tasks/validate-no-hardcoded-ips.yml"
    vars:
      validate_hostlike_vars:
        my_host: "{{ my_host | default('') }}"
      validate_verbose: true # Show detailed validation info
```

## Error Messages and Remediation

When a hardcoded IP is detected, the validation provides clear guidance:

```text
❌ HARDCODED IP DETECTED: Variable 'database_host' = '192.168.1.50'

This violates the dynamic inventory pattern!

REQUIRED FIXES:
1. Remove the hardcoded IP from vars section
2. Ensure validation runs FIRST in pre_tasks (before any set_fact tasks)
3. Use pre_tasks to discover from inventory:
   - For single host: hostvars[hostname]['ansible_host']
   - For group: groups['groupname'] | map('extract', hostvars, 'ansible_host')
4. Or use DNS names instead of IP literals

Example fix:
pre_tasks:
  # FIRST: Validate before setting any variables
  - name: Validate no hardcoded IPs
    ansible.builtin.include_tasks: "{{ playbook_dir }}/../../../tasks/validate-no-hardcoded-ips.yml"
    vars:
      validate_hostlike_vars:
        database_host: "{{ database_host | default('') }}"

  # THEN: Discover from inventory
  - name: Discover database_host from inventory
    ansible.builtin.set_fact:
      database_host: "{{ hostvars[groups['databases'][0]]['ansible_host'] }}"
```

## Benefits

1. **Single Source of Truth**: Inventory defines all infrastructure
2. **Environment Agnostic**: Same playbook works across dev/staging/prod
3. **Maintainable**: Update only inventory when infrastructure changes
4. **Testable**: Use different inventories for different scenarios
5. **Auditable**: All infrastructure references are traceable
6. **CI/CD Ready**: Fails fast in pipelines before deployment

## Migration Guide

For existing playbooks with hardcoded IPs:

1. **Identify all hardcoded IPs**: Run the validation to find violations
2. **Move IPs to inventory**: Add hosts with ansible_host in appropriate groups
3. **Add validation**: Include validate-no-hardcoded-ips.yml in pre_tasks
4. **Replace hardcoded values**: Use dynamic discovery patterns
5. **Test thoroughly**: Verify with different inventories

## References

- [Ansible inventory documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)
- [ansible.utils.ipaddr filter](https://docs.ansible.com/ansible/latest/collections/ansible/utils/ipaddr_filter.html)
- [Ansible best practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
