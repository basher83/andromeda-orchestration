# Troubleshooting Guide

This guide covers common issues and their solutions when working with this Ansible project.

## Table of Contents

1. [macOS Sequoia Local Network Permissions](#macos-sequoia-local-network-permissions)
2. [1Password Connection Issues](#1password-connection-issues)
3. [Ansible Inventory Errors](#ansible-inventory-errors)
4. [Python Environment Issues](#python-environment-issues)
5. [Network Connectivity](#network-connectivity)
6. [Ansible Playbook Common Issues](#ansible-playbook-common-issues)

## macOS Sequoia Local Network Permissions

### Problem

```text
OSError: [Errno 65] No route to host
```

When trying to connect to local network addresses (192.168.x.x) on macOS 15 (Sequoia) or later.

### Cause

macOS Sequoia introduced Local Network Privacy permissions that block applications from accessing local network devices
without explicit permission.

### Solution

1. **Grant permissions in System Settings:**

   ```text
   System Settings > Privacy & Security > Local Network
   ```

   Enable permissions for:

   - Terminal
   - Python / Python3
   - Your code editor (VS Code, etc.)

2. **Restart Terminal** after granting permissions

3. **Test the connection:**

   ```bash
   python3 -c "import socket; s = socket.socket(); print(s.connect_ex(('192.168.x.x', 8006)))"
   # Should return 0 if successful
   ```

### Prevention

- Always grant Local Network permissions before running Ansible on macOS Sequoia
- Consider adding a pre-flight check to your scripts

## Python Environment Issues

### Problem: "objc[pid]: ... may have been in progress in another thread when fork() was called"

#### Fork Solution

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

This is automatically set in the wrapper script.

### Problem: Module import errors

#### Ensure Ansible's Python has required modules

```bash
# Find Ansible's Python
ansible --version | grep "python"

# Install modules for that Python
uv pip install requests proxmoxer
```

## Network Connectivity

### Problem: Proxmox API unreachable

#### Diagnostic steps

1. **Test DNS resolution:**

   ```bash
   nslookup proxmox.example.com
   ```

2. **Test port connectivity:**

   ```bash
   nc -zv proxmox.example.com 8006
   ```

3. **Test with curl:**

   ```bash
   curl -k https://proxmox.example.com:8006
   ```

4. **Check for VPN interference:**
   - Disconnect VPN and test again
   - Check routing table: `netstat -rn`

### Problem: SSL certificate errors

#### For self-signed certificates

```yaml
# In inventory file
validate_certs: false
```

## Debugging Tips

### Enable Ansible debugging

```bash
ANSIBLE_DEBUG=1 ansible-playbook -vvvv playbook.yml
```

### Test individual components

1. **Test Infisical lookup:**

   ```bash
   ansible localhost -m debug -a "msg={{ lookup('infisical', 'Test Item') }}"
   ```

2. **Test inventory plugin:**

   ```bash
   ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --list
   ```

3. **Test connectivity:**

   ```bash
   ansible all -i inventory/og-homelab/infisical.proxmox.yml -m ping
   ```

### Common log locations

- Ansible: `~/.ansible/ansible.log` (if configured)
- Infisical CLI: `~/.config/infisical/logs/`
- System logs: `/var/log/system.log` (macOS)

## Getting Help

If you're still experiencing issues:

1. Check the [Ansible documentation](https://docs.ansible.com)
2. Review [Infisical developer docs](https://infisical.com/docs)
3. Search existing issues in the repository
4. Create a new issue with:
   - Error messages
   - Steps to reproduce
   - Environment details (OS, versions)
   - Debug output

## Ansible Playbook Common Issues

### Problem: Jinja2 filter errors with empty results

When using filters like `first` with `default()`, you may encounter errors if the result is empty.

#### Solution

Use conditional logic instead of chaining filters:

```yaml
# INCORRECT:
search_domains: >-
  {{ content | regex_findall('search\s+(.*)') | first | default('') | split }}

# CORRECT:
search_domains: >-
  {% set search_line = content | regex_findall('search\s+(.*)') %}
  {% if search_line | length > 0 %}
  {{ search_line[0] | split }}
  {% else %}
  []
  {% endif %}
```

### Problem: Accessing attributes on undefined variables

Attempting to access `.stdout` or other attributes on skipped/failed task results causes errors.

#### Solution

Always check if variables and attributes are defined:

```yaml
# INCORRECT:
consul_integrated: "{{ 'consul' in consul_nomad_integration.stdout | lower }}"

# CORRECT:
consul_integrated: >-
  {% if consul_nomad_integration is defined and consul_nomad_integration.stdout is defined %}
  {{ 'consul' in consul_nomad_integration.stdout | lower }}
  {% else %}
  false
  {% endif %}
```

### Problem: DNS resolution failures during assessment

VM names may not resolve, causing connectivity tests to fail.

#### Solutions

1. **Use IP addresses directly (recommended for assessments):**

```yaml
- name: Test connectivity
  ansible.builtin.command:
    cmd: "ping -c 2 {{ hostvars[item]['ansible_default_ipv4']['address'] }}"
  when:
    - hostvars[item]['ansible_default_ipv4'] is defined
    - hostvars[item]['ansible_default_ipv4']['address'] is defined
```

2. **Add temporary hosts entries:**

```yaml
- name: Add temporary hosts entries
  ansible.builtin.lineinfile:
    path: /etc/hosts
    line: "{{ hostvars[item]['ansible_default_ipv4']['address'] }} {{ item }}"
  loop: "{{ groups['all'] }}"
  when: item != inventory_hostname
  become: true
```

### Best Practices for Robust Playbooks

1. **Use `failed_when: false` for discovery tasks:**

```yaml
- name: Check service status
  ansible.builtin.command:
    cmd: systemctl status service
  register: result
  changed_when: false
  failed_when: false
```

1. **Implement error handling blocks:**

```yaml
- name: Task with fallback
  block:
    - name: Primary method
      ansible.builtin.command: primary-tool
  rescue:
    - name: Fallback method
      ansible.builtin.command: fallback-tool
  always:
    - name: Cleanup
      ansible.builtin.file:
        path: /tmp/temp-file
        state: absent
```

1. **Validate connectivity before tests:**

```yaml
- name: Ensure target is reachable
  ansible.builtin.wait_for:
    host: "{{ target_host }}"
    port: 22
    timeout: 5
  register: host_reachable
  failed_when: false
```

## 1Password Connection Issues

- Ensure 1Password CLI is installed and authenticated: `op --version` and `op account list`
- If using 1Password Connect, verify environment variables are set:

```bash
export OP_CONNECT_HOST=https://connect.local
export OP_CONNECT_TOKEN=...redacted...
```

- Validate connectivity from the Ansible control host:

```bash
curl -sSf "$OP_CONNECT_HOST/v1/health" | jq .
```

- For local CLI usage with Ansible, ensure `op run -- ansible-playbook ...` is used when referencing `op://` secrets.

## Ansible Inventory Errors

Common symptoms:

- Hosts not found or wrong groups
- Authentication or SSH failures targeted at incorrect IPs

Quick checks:

```bash
# Validate inventory plugins
ansible-inventory -i inventory/og-homelab/netbox.yml --list > /dev/null

# View host vars resolution for a host
ansible-inventory -i inventory/og-homelab/netbox.yml --host some-hostname
```

If using NetBox inventory:

- Confirm NetBox URL and token in `inventory/netbox.yml`
- Test API accessibility from control host
- Ensure device roles and tags in NetBox match inventory filters

## Related Documentation

- [Infisical Setup and Migration](infisical-setup-and-migration.md) - Complete secret management guide
- [NetBox Integration](netbox.md) - NetBox connectivity troubleshooting
- [DNS & IPAM Implementation Plan](dns-ipam-implementation-plan.md) - Infrastructure assessment procedures
- [Pre-commit Setup](pre-commit-setup.md) - Development environment configuration
