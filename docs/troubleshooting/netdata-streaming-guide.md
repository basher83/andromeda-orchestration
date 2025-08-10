# Netdata Streaming Troubleshooting Guide

## Overview

This guide consolidates troubleshooting information for Netdata parent-child streaming and mesh replication across the homelab infrastructure.

## Current Infrastructure

### Parent Nodes (Metrics Aggregators)

```bash
# doggos-homelab cluster
lloyd: 192.168.11.2 (Management: 192.168.10.2)
holly: 192.168.11.3 (Management: 192.168.10.3)
mable: 192.168.11.4 (Management: 192.168.10.4)

# og-homelab cluster
pve1: 192.168.30.50
```

### Child Nodes (Metrics Collectors)

```bash
# doggos-homelab Nomad nodes
nomad-server-1-lloyd: 192.168.11.11
nomad-server-2-holly: 192.168.11.12
nomad-server-3-mable: 192.168.11.13
nomad-client-1-lloyd: 192.168.11.20
nomad-client-2-holly: 192.168.11.21
nomad-client-3-mable: 192.168.11.22

# og-homelab nodes
proxmoxt430: 192.168.30.30
pbs: 192.168.30.200

# To be added
TrueNAS: 192.168.30.6
```

## Common Issues and Solutions

### 1. API Key Authentication Failures

#### Problem

```text
STREAM RCV 'hostname' [from [IP]:PORT]: rejecting streaming connection; API key is not allowed from this IP (DENIED)
```

#### Root Cause

The stream.conf API key configuration is incorrectly formatted or too restrictive.

#### Solution

**Correct stream.conf format for parents:**

```ini
# Parent stream.conf accepting children and mesh replication
[stream]
    enabled = yes
    destination = 192.168.11.2 192.168.11.3 192.168.30.50  # Other parents
    api key = parent_api_key  # Key this parent uses to stream to others

# Accept metrics from children
[child_api_key]  # Use actual API key as section name, NOT [API_KEY]
    enabled = yes
    default history = 3600
    default memory mode = dbengine
    health enabled by default = auto
    allow from = *  # Critical: Use * for flexibility
    default postpone alarms on connect seconds = 60
    multiple connections = allow

# Accept metrics from other parents (mesh)
[parent_api_key]
    enabled = yes
    default memory mode = dbengine
    allow from = 192.168.11.2 192.168.11.3 192.168.11.4 192.168.30.50
```

**Common mistakes to avoid:**

```ini
# WRONG - Don't use [API_KEY] as section name
[API_KEY]
    type = api  # This directive doesn't exist
    enabled = yes

# WRONG - Too restrictive IP filtering
[my-api-key]
    allow from = 192.168.30.0/24  # May not work correctly
```

### 2. Child Not Streaming to Parent

#### Debugging Steps

1. **Verify configuration on child:**

```bash
# Check if streaming is enabled
grep "enabled.*=.*yes" /etc/netdata/stream.conf

# Verify destination IPs are correct
grep "destination" /etc/netdata/stream.conf
```

1. **Test connectivity:**

```bash
# From child to parent
nc -zv 192.168.11.2 19999
ping -c 3 192.168.11.2

# Check for firewall blocks
sudo iptables -L -n | grep 19999
sudo nft list ruleset | grep 19999
```

1. **Monitor connection attempts:**

```bash
# On child
tcpdump -i any -n host 192.168.11.2 and port 19999

# Check Netdata logs
journalctl -u netdata -f | grep -E "(STREAM|connect|api.key)"
```

1. **Verify on parent:**

```bash
# Watch for incoming connections
journalctl -u netdata -f | grep "STREAM"

# Check active connections
ss -tn | grep ":19999" | grep -v "LISTEN"

# Verify child metrics are received
curl -s http://localhost:19999/api/v1/allmetrics?format=json | grep -i "nomad-client"
```

### 3. Parent Mesh Not Replicating


#### Issue
Parents aren't sharing data with each other in the mesh topology.

#### Debugging Steps

1. **Verify outbound streaming:**

```bash
# Check [stream] section on each parent
grep -A 10 "^\[stream\]" /etc/netdata/stream.conf
```

1. **Check cross-cluster connectivity:**

```bash
# From doggos parent to og parent
ping -c 3 192.168.30.50
nc -zv 192.168.30.50 19999

# From og parent to doggos parents
ping -c 3 192.168.11.2
nc -zv 192.168.11.2 19999
```

1. **Verify mesh connections:**

```bash
# Should show connections to other parents
ss -tan | grep :19999 | grep ESTAB | wc -l
```

### 4. Web Interface Issues

#### Problem

Netdata web interface not accessible after configuration changes.

#### Solution

Ensure web server is enabled in `/etc/netdata/netdata.conf`:

```ini
[web]
    mode = static-threaded
    enable gzip compression = yes
    gzip compression level = 3
```

## Configuration Examples

### Child Node Configuration

```ini
# /etc/netdata/stream.conf on child nodes
[stream]
    enabled = yes
    destination = 192.168.11.2 192.168.11.3 192.168.11.4
    api key = child_api_key
    timeout seconds = 60
    default port = 19999
    send charts matching = *
    buffer size bytes = 1048576
    reconnect delay seconds = 5
```

### Parent Node Configuration

```ini
# /etc/netdata/stream.conf on parent nodes
# Example from holly (192.168.11.3)

[stream]
    enabled = yes
    destination = 192.168.11.2 192.168.11.4 192.168.30.50
    api key = parent_api_key

# Accept metrics from children
[child_api_key]
    enabled = yes
    default memory mode = dbengine
    allow from = *

# Accept metrics from other parents
[parent_api_key]
    enabled = yes
    default memory mode = dbengine
    allow from = 192.168.11.2 192.168.11.4 192.168.30.50
```

## Adding Non-Inventory Nodes

For nodes not in Proxmox dynamic inventory (like PBS):

### Option 1: Manual Configuration

```bash
# SSH to the node
ssh root@192.168.30.200

# Edit stream.conf
nano /etc/netdata/stream.conf

# Add configuration
[stream]
    enabled = yes
    destination = 192.168.30.50:19999
    api key = og-child-key

# Restart Netdata
systemctl restart netdata
```

### Option 2: Ansible Playbook

```yaml
- name: Configure PBS to stream to parent
  hosts: localhost
  tasks:
    - name: Add PBS to inventory
      ansible.builtin.add_host:
        name: pbs
        ansible_host: 192.168.30.200
        ansible_user: root
        ansible_password: "{{ vault_pbs_password }}"

- name: Configure streaming
  hosts: pbs
  tasks:
    - name: Configure stream.conf
      ansible.builtin.template:
        src: stream.conf.j2
        dest: /etc/netdata/stream.conf
      notify: restart netdata
```

## Performance Optimization

### Reducing Child Resource Usage

```ini
# /etc/netdata/netdata.conf on children
[global]
    memory mode = ram
    history = 900  # 15 minutes instead of 1 hour
    update every = 2  # Update every 2 seconds instead of 1

[plugins]
    # Disable unnecessary plugins
    apps = no
    ebpf = no
    tc = no
```

### Parent Storage Management

```ini
# /etc/netdata/netdata.conf on parents
[db]
    mode = dbengine
    storage tiers = 1  # Reduce from default 3
    dbengine multihost disk space MB = 1024  # Limit to 1GB
```

## Verification Commands

### Success Indicators

```bash
# Parent logs showing successful child connection
STREAM 'nomad-client-1' [from [192.168.11.20]:PORT]: streaming api key accepted
STREAM 'nomad-client-1' [from [192.168.11.20]:PORT]: receiving metrics

# Count of established connections should match expected
ss -tn | grep ":19999.*ESTABLISHED" | wc -l

# API should show child metrics
curl -s http://localhost:19999/api/v1/info | jq '.mirrored_hosts'
```

### Quick Diagnostic Commands

```bash
# Check if Netdata is running
systemctl status netdata

# Verify configuration syntax
netdata -W buildinfo | grep -i stream

# Test connectivity to parent
nc -zv <parent-ip> 19999

# Check for configuration errors
grep -i error /var/log/netdata/error.log | tail -20

# Verify API key in use
grep -A5 "^\[stream\]" /etc/netdata/stream.conf | grep "api key"
```

## Troubleshooting Checklist

- [ ] API key in child's `[stream]` section matches parent's `[api-key]` section name
- [ ] Parent has `allow from = *` in API key section
- [ ] Correct destination IPs (11.x for data network, not 10.x management)
- [ ] Firewall allows port 19999 between nodes
- [ ] Network routing exists between clusters (for mesh)
- [ ] Netdata service is running on both nodes
- [ ] No typos in IP addresses or API keys
- [ ] stream.conf has proper permissions (640, owned by netdata)
- [ ] Web server enabled if web interface needed

## Known Issues

1. **Consul Health Checks**: netdata-parent-health checks don't apply to Proxmox parent nodes as they don't run Consul
1. **Backup File Names**: Ansible creates backups with unwieldy names like `netdata.conf.3052946.2025-08-03@08:59:29~`

## References

- [Netdata Streaming Documentation](https://learn.netdata.cloud/docs/streaming)
- [Netdata Parent-Child Configuration](https://learn.netdata.cloud/docs/streaming/streaming-configuration-reference)
- [Internal: Netdata Architecture](../operations/netdata-architecture.md)
