# Troubleshooting Guide

This guide covers common issues and their solutions when working with this Ansible project.

## Table of Contents

1. [macOS Sequoia Local Network Permissions](#macos-sequoia-local-network-permissions)
2. [1Password Connection Issues](#1password-connection-issues)
3. [Ansible Inventory Errors](#ansible-inventory-errors)
4. [Python Environment Issues](#python-environment-issues)
5. [Network Connectivity](#network-connectivity)

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

## Related Documentation

- [Infisical Setup and Migration](infisical-setup-and-migration.md) - Complete secret management guide
- [NetBox Integration](netbox.md) - NetBox connectivity troubleshooting
- [DNS & IPAM Implementation Plan](dns-ipam-implementation-plan.md) - Infrastructure assessment procedures
- [Pre-commit Setup](pre-commit-setup.md) - Development environment configuration
- [Assessment Playbook Fixes](assessment-playbook-fixes.md) - Specific assessment playbook issues
