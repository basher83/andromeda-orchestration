# Troubleshooting Guides

Common issues and solutions for infrastructure components.

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

### Most Common Issues (2025)

1. **Consul KV Access** - Jobs can't read from KV store → Use ACL update playbook
2. **Service Identity** - Workload tokens not derived → Check auth method config
3. **Netdata Streaming** - Child nodes not connecting → Verify API keys and firewalls

### Getting Help

- Check logs: `journalctl -u <service> -f`
- Verify service status: `systemctl status <service>`
- Test connectivity: `curl -I http://service.consul:port/health`
