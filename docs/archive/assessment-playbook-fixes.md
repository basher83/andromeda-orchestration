# Assessment Playbook Fixes

This document addresses the issues with the assessment playbooks and provides solutions for making them more robust.

## Issues Identified

### 1. DNS/IPAM Audit Playbook - Jinja2 Filter Errors

**Problem**: The `first` filter was being used incorrectly with `default()`.
```yaml
# INCORRECT:
search_domains: >-
  {{ resolv_conf.content | b64decode | regex_findall('search\s+(.*)') |
     first | default('') | split }}
```

**Solution**: Use proper conditional logic to handle empty results.
```yaml
# CORRECT:
search_domains: >-
  {% set search_line = resolv_conf.content | b64decode | regex_findall('search\s+(.*)') %}
  {% if search_line %}
  {{ search_line[0] | split }}
  {% else %}
  []
  {% endif %}
```

### 2. Infrastructure Readiness Playbook - Accessing Undefined Variables

**Problem**: Trying to access `.stdout` on a skipped task result.
```yaml
# INCORRECT:
consul_integrated: "{{ 'consul' in consul_nomad_integration.stdout | lower }}"
```

**Solution**: Check if the variable is defined before accessing attributes.
```yaml
# CORRECT:
consul_integrated: >-
  {% if consul_nomad_integration is defined and consul_nomad_integration.stdout is defined %}
  {{ 'consul' in consul_nomad_integration.stdout | lower }}
  {% else %}
  false
  {% endif %}
```

### 3. DNS Resolution Issues

**Problem**: VM names like "nomad-server-1-lloyd" don't resolve, causing connectivity tests to fail.

**Solutions**:

#### Option 1: Use IP Addresses Directly (Recommended for Assessment Phase)
Modify the inventory to always use IP addresses:
```yaml
compose:
  ansible_host: >-
    {{ proxmox_ipconfig0.ip | default(proxmox_net0.ip) |
       regex_replace('/\d+$', '') }}
```

#### Option 2: Add Local DNS Resolution
For hosts that need name resolution during assessment:
```yaml
- name: Add temporary hosts entries for assessment
  ansible.builtin.lineinfile:
    path: /etc/hosts
    line: "{{ hostvars[item]['ansible_default_ipv4']['address'] }} {{ item }}"
    state: present
  loop: "{{ groups['all'] }}"
  when: item != inventory_hostname
  become: true
```

#### Option 3: Skip Failed DNS Lookups
Make DNS-dependent tasks more resilient:
```yaml
- name: Test connectivity between nodes
  ansible.builtin.command:
    cmd: "ping -c 2 -W 2 {{ hostvars[item]['ansible_default_ipv4']['address'] | default(item) }}"
  loop: "{{ groups['all'] }}"
  when:
    - item != inventory_hostname
    - hostvars[item]['ansible_default_ipv4'] is defined
  register: ping_tests
  changed_when: false
  failed_when: false
```

## Best Practices for Robust Assessment Playbooks

### 1. Always Use Defensive Coding

```yaml
# Check if variables exist before using them
- name: Safe variable access
  ansible.builtin.set_fact:
    my_value: >-
      {% if some_var is defined and some_var.attribute is defined %}
      {{ some_var.attribute }}
      {% else %}
      {{ default_value }}
      {% endif %}
```

### 2. Handle Empty Lists and Filters

```yaml
# Handle empty regex results
{% set matches = content | regex_findall('pattern') %}
{% if matches | length > 0 %}
  {{ matches[0] }}
{% else %}
  {{ default_value }}
{% endif %}
```

### 3. Use failed_when: false for Discovery Tasks

```yaml
- name: Check service status
  ansible.builtin.command:
    cmd: systemctl status some-service
  register: service_check
  changed_when: false
  failed_when: false  # Don't fail if service doesn't exist
```

### 4. Validate Network Connectivity

```yaml
- name: Ensure target is reachable before tests
  ansible.builtin.wait_for:
    host: "{{ target_host }}"
    port: 22
    timeout: 5
  register: host_reachable
  failed_when: false

- name: Run tests only on reachable hosts
  when: host_reachable is succeeded
  # ... your tests here
```

### 5. Use ignore_errors for Non-Critical Assessments

```yaml
- name: Optional assessment task
  ansible.builtin.command:
    cmd: some-optional-check
  register: optional_result
  ignore_errors: true

- name: Process results if available
  when: optional_result is succeeded
  ansible.builtin.set_fact:
    assessment_data: "{{ optional_result.stdout }}"
```

### 6. Implement Proper Error Handling Blocks

```yaml
- name: Assessment with error handling
  block:
    - name: Primary assessment method
      ansible.builtin.command:
        cmd: primary-assessment-tool
      register: primary_result

  rescue:
    - name: Fallback assessment method
      ansible.builtin.command:
        cmd: fallback-assessment-tool
      register: fallback_result

    - name: Use fallback data
      ansible.builtin.set_fact:
        assessment_result: "{{ fallback_result }}"

  always:
    - name: Ensure cleanup
      ansible.builtin.file:
        path: /tmp/assessment-temp
        state: absent
```

## Network Architecture Considerations

Given your network setup:
- **192.168.11.x**: 10G high-speed network (servers)
- **192.168.10.x**: 2.5G network (some clients)

### Recommendations:

1. **Use IP addresses directly** for critical infrastructure assessments
2. **Document network segments** in inventory vars:
   ```yaml
   vars:
     network_10g: "192.168.11.0/24"
     network_2_5g: "192.168.10.0/24"
   ```

3. **Group hosts by network** for targeted assessments:
   ```yaml
   groups:
     high_speed_network:
       hosts:
         - host1
         - host2
     standard_network:
       hosts:
         - host3
         - host4
   ```

## Testing the Fixed Playbooks

Run the playbooks with increased verbosity to catch issues:

```bash
# Test DNS/IPAM audit
uv run ansible-playbook playbooks/assessment/dns-ipam-audit.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml -vv

# Test infrastructure readiness
uv run ansible-playbook playbooks/assessment/infrastructure-readiness.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml -vv

# Run with specific tags for debugging
uv run ansible-playbook playbooks/assessment/infrastructure-readiness.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  --tags network -vv
```

## Summary

The main issues were:
1. Incorrect Jinja2 filter usage (fixed)
2. Accessing attributes on undefined/skipped task results (fixed)
3. DNS resolution failures (multiple solutions provided)

The playbooks have been updated to be more defensive and handle edge cases gracefully. For the DNS resolution issue, using IP addresses directly is recommended during the assessment phase until proper DNS infrastructure is in place.
