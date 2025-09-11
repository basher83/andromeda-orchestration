# Troubleshooting Guides

Common issues and solutions for infrastructure components.

## Ansible & Deployment

### Ansible-Nomad Playbooks

- **[Ansible-Nomad Playbook Troubleshooting](ansible-nomad-playbooks.md)** - Complete guide for deployment issues ⭐ **NEW**
  - Missing Python dependencies (`python-nomad`, `infisicalsdk`)
  - Privilege escalation problems (`sudo` prompts for localhost)
  - Variable recursion errors in Jinja2 templates
  - API response structure issues
  - Environment and file path problems

### Domain Migration

- **[Domain Migration Troubleshooting](domain-migration.md)** - `.local` → `spaceships.work` migration issues ⭐ **NEW**
  - HCL2 variable syntax errors
  - Services not registering in Consul after migration
  - Environment configuration problems
  - DNS resolution failures
  - Migration validation procedures

## HashiCorp Stack

### Consul

- **[Consul KV Templating Issues](consul-kv-templating-issues.md)** - Nomad job template permission errors ⚠️ **CRITICAL**
  - Template failed: Permission denied errors
  - Missing KV access in ACL policies
  - Quick fix with infrastructure playbooks

### Nomad

- [Service Identity Issues](service-identity-issues.md) - Consul service identity token problems

### Netdata

- [Netdata Streaming Guide](netdata-streaming-guide.md) - Parent-child streaming troubleshooting

## Quick Reference

## Infrastructure

### DNS Resolution

- **[DNS Resolution Loops](dns-resolution-loops.md)** - "It's Always DNS" troubleshooting 🔥 **CRITICAL**
  - systemd-resolved and Consul DNS conflicts
  - Docker image pull failures ("server misbehaving" errors)
  - Services not registering due to container startup failures
  - Comprehensive fix playbook included

### Most Common Issues (2025)

1. **DNS Resolution Loops** - `server misbehaving` from `127.0.0.53:53` → Run DNS fix playbook
2. **Missing Python Dependencies** - `Failed to import python-nomad` → Run `uv sync`
3. **Privilege Escalation** - `sudo: a password is required` → Add `-e ansible_become=false`
4. **Variable Recursion** - `Recursive loop detected` → Use `hostvars[inventory_hostname]`
5. **Consul KV Access** - Jobs can't read from KV store → Use ACL update playbook
6. **Service Identity** - Workload tokens not derived → Check auth method config
7. **Domain Migration** - Services not in Consul after migration → Check job service blocks
8. **Netdata Streaming** - Child nodes not connecting → Verify API keys and firewalls

## Issue Investigation Framework

For **new issues requiring research**, use the standardized investigation framework.

### 📊 [Investigation Tracking Index](investigations/INDEX.md)

Track all active, resolved, and archived investigations in the centralized index.

### Quick Links

- **[Investigation Index](investigations/INDEX.md)** - Current status of all investigations
- **[Template](investigations/template.md)** - Standard investigation template
- **[Workflow Guide](investigations/workflow.md)** - How to conduct investigations
- **[Example](investigations/2025-09-09-postgresql-service-registration.md)** - Completed investigation

### Starting a New Investigation

```bash
# Create new investigation from template
cp investigations/template.md investigations/$(date +%Y-%m-%d)-issue-name.md

# Update the tracking index
vim investigations/INDEX.md
```

### Quick Reference Commands

- Check logs: `journalctl -u <service> -f`
- Verify service status: `systemctl status <service>`
- Test connectivity: `curl -I http://service.consul:port/health`
