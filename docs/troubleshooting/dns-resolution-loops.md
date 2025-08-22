# DNS Resolution Loops - "It's Always DNS"

## Problem Summary

**Symptom**: Nomad jobs fail with Docker image pull errors showing "server misbehaving" from `127.0.0.53:53`

**Real Cause**: DNS resolution loops between systemd-resolved stub resolver and Consul DNS configuration

**Classic Misdirection**: This appears as service registration failure, network connectivity issues, or Nomad-Consul integration problems when the actual issue is DNS configuration.

## Error Examples

```text
Driver Failure: Failed to pull `traefik:v3.0`: Error response from daemon:
Get "https://registry-1.docker.io/v2/": dial tcp: lookup registry-1.docker.io
on 127.0.0.53:53: server misbehaving
```

## Root Cause Analysis

### The DNS Loop Problem

1. **systemd-resolved** runs a stub resolver on `127.0.0.53:53`
2. **Consul DNS** runs on `127.0.0.1:8600` for `.consul` domains
3. **Conflicting configurations** cause DNS queries to loop between resolvers
4. **External DNS resolution fails**, preventing Docker registry access
5. **Containers can't start**, so services never register (misleading symptom!)

### Configuration Conflicts

Multiple DNS configurations fighting each other:

- `/etc/systemd/resolved.conf` - Main systemd-resolved config
- `/etc/systemd/resolved.conf.d/consul.conf` - Consul-specific DNS settings
- `/etc/netplan/50-cloud-init.yaml` - Network interface DNS settings
- `/etc/resolv.conf` - System resolver configuration

## Solution: DNS Hierarchy Fix

We created `playbooks/fix/fix-dns-resolution-loop.yml` to systematically resolve this:

### What the Fix Does

1. **Disables DNS stub listener** - Prevents the loop at `127.0.0.53`
2. **Configures external DNS servers** - Google DNS (8.8.8.8) and Cloudflare (1.1.1.1) as primary
3. **Cleans up conflicting configs** - Removes duplicate/conflicting DNS settings
4. **Updates network configuration** - Points interfaces directly to external DNS
5. **Preserves Consul DNS** - Keeps `127.0.0.1:8600` available for `.consul` domains

### How to Apply the Fix

```bash
# Run the DNS fix playbook across all Nomad nodes
uv run ansible-playbook playbooks/fix/fix-dns-resolution-loop.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Verification

After applying the fix, verify DNS resolution works:

```bash
# Test external DNS resolution
nslookup registry-1.docker.io 8.8.8.8

# Test Consul DNS (if running)
nslookup consul.service.consul 127.0.0.1

# Check systemd-resolved status
resolvectl status
```

## What We Initially Thought Was Wrong (But Wasn't!)

During troubleshooting, we investigated all of these - they were **all working correctly**:

- ✅ **Service Identity Configuration** - `auto = true` was properly set
- ✅ **Nomad-Consul Integration** - Tokens were being generated successfully
- ✅ **ACL Permissions** - Policies allowed service registration
- ✅ **Network Configuration** - `network { mode = "host" }` was correct
- ✅ **Service Registration Logic** - Services registered when containers actually started
- ✅ **Health Check Configuration** - Health checks were properly disabled/configured

## Debugging Process (For Future Reference)

### 1. Check the Real Error

Don't trust the high-level symptom. Dig into the allocation logs:

```bash
# Get the failing allocation ID
nomad job status <job-name>

# Check detailed allocation status
nomad alloc status <allocation-id>

# Look for the actual Docker error
nomad alloc logs <allocation-id>
```

### 2. Test DNS Resolution Directly

```bash
# Test from the affected node
ssh <nomad-node>
nslookup registry-1.docker.io
dig registry-1.docker.io

# Check what DNS servers are actually being used
resolvectl status
cat /etc/resolv.conf
```

### 3. Verify Consul Services (When Working)

```bash
# List all registered services
consul catalog services

# Check if tokens are being generated
consul acl token list | grep -i nomad

# Verify specific service registration
consul catalog nodes -service=<service-name>
```

## Lesson Learned

When you see:

- Container startup failures
- "Server misbehaving" DNS errors
- Services not appearing in Consul
- Network connectivity issues

**Check DNS first!** The classic "It's always DNS" rule applies heavily in containerized environments where DNS resolution is critical for:

- Image registry access
- Service discovery
- Inter-service communication

## Prevention

### Ansible Role Configuration

Ensure your Consul and systemd-resolved configurations don't conflict:

```yaml
# In your Consul/Nomad role configuration
# Use external DNS as primary, Consul DNS for .consul domains only
dns_servers:
  - "8.8.8.8"
  - "8.8.4.4"
  - "1.1.1.1"
  - "1.0.0.1"

# Disable systemd-resolved stub listener
systemd_resolved_stub_listener: false
```

### Monitoring

Add DNS resolution monitoring to catch this early:

```bash
# Add to your health checks
nslookup registry-1.docker.io > /dev/null || echo "DNS_FAILURE"
```

## Files Created/Modified

- `playbooks/fix/fix-dns-resolution-loop.yml` - The fix playbook
- `playbooks/fix/templates/resolv.conf.j2` - Clean resolv.conf template
- This documentation file

---

**Remember**: When troubleshooting infrastructure issues, always check DNS configuration early in the process. It's almost always DNS! 🕵️‍♂️
