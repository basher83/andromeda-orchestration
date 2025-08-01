# Netdata Streaming Troubleshooting Guide

## API Key Authentication Issues

### Problem: "API key is not allowed from this IP (DENIED)"

This is one of the most common issues when setting up Netdata streaming. The error appears in the parent's journal logs:

```
STREAM RCV 'hostname' [from [IP]:PORT]: rejecting streaming connection; API key is not allowed from this IP (DENIED)
```

### Root Cause

The stream.conf API key configuration on the parent node is incorrectly formatted or too restrictive.

### Solution

1. **Correct Format for stream.conf API Key Sections:**

```ini
# CORRECT - Use the actual API key as the section header
[og-child-key]
    enabled = yes
    default history = 3600
    default memory mode = dbengine
    health enabled by default = auto
    allow from = *
    default postpone alarms on connect seconds = 60
    multiple connections = allow
```

2. **Common Mistakes to Avoid:**

```ini
# WRONG - Don't use [API_KEY] as the section name
[API_KEY]
    type = api  # This directive is not needed
    enabled = yes
    ...

# WRONG - Too restrictive IP filtering
[my-api-key]
    enabled = yes
    allow from = 192.168.30.0/24  # May not work correctly
```

3. **Working Example for Parent with Multiple API Keys:**

```ini
# Parent stream.conf accepting children and mesh replication

[stream]
    enabled = yes
    destination = <other-parent-IPs>
    api key = netdata-parent-mesh-key
    # ... other settings

# Accept children from og-homelab
[og-child-key]
    enabled = yes
    default history = 3600
    default memory mode = dbengine
    health enabled by default = auto
    allow from = *
    default postpone alarms on connect seconds = 60
    multiple connections = allow

# Accept mesh replication from other parents
[netdata-parent-mesh-key]
    enabled = yes
    default history = 3600
    default memory mode = dbengine
    health enabled by default = auto
    allow from = *
    default postpone alarms on connect seconds = 60
    multiple connections = allow
```

## Debugging Connection Issues

### 1. Verify Child is Attempting to Connect

On the child node:
```bash
# Check if streaming is enabled
grep "enabled.*=.*yes" /etc/netdata/stream.conf

# Watch for connection attempts
tcpdump -i any -n host <parent-ip> and port 19999
```

### 2. Check Parent is Receiving Connections

On the parent node:
```bash
# Watch for incoming connections
journalctl -u netdata -f | grep -E "(STREAM|connect|api.key)"

# Check active connections
ss -tn | grep ":19999" | grep -v "LISTEN"
```

### 3. Test Basic Connectivity

```bash
# From child to parent
nc -zv <parent-ip> 19999
ping -c 3 <parent-ip>

# Check firewall isn't blocking
sudo iptables -L -n | grep 19999
sudo nft list ruleset | grep 19999
```

## Mesh Topology Issues

### Problem: Parents Not Replicating to Each Other

When parent nodes aren't sharing data in the mesh topology.

### Debugging Steps:

1. **Check Outbound Streaming Configuration:**
```bash
# On each parent, verify [stream] section
grep -A 10 "^\[stream\]" /etc/netdata/stream.conf
```

2. **Verify Mesh API Key Matches:**
```bash
# The api key in [stream] section must match
# the [api-key-name] section on receiving parents
```

3. **Check Cross-Cluster Connectivity:**
```bash
# From doggos parent to og parent
ping -c 3 192.168.30.50
nc -zv 192.168.30.50 19999

# From og parent to doggos parents
ping -c 3 192.168.10.11
nc -zv 192.168.10.11 19999
```

## PBS and Non-Proxmox Nodes

### Adding Non-Inventory Nodes

For nodes like PBS that aren't in the Proxmox dynamic inventory:

1. **Create a Simple Deployment Playbook:**
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
    # ... configuration tasks
```

2. **Manual Configuration:**
```bash
# SSH to the node
ssh root@192.168.30.200

# Edit stream.conf
nano /etc/netdata/stream.conf

# Add streaming configuration
[stream]
    enabled = yes
    destination = <parent-ip>:19999
    api key = <appropriate-child-key>
    # ... other settings

# Restart Netdata
systemctl restart netdata
```

## Verifying Successful Streaming

### On Parent Node:

1. **Check API for Metrics:**
```bash
# See if child's metrics are present
curl -s http://localhost:19999/api/v1/allmetrics?format=json | grep -i "<child-hostname>"
```

2. **Count Active Connections:**
```bash
# Should match expected number of children + mesh peers
ss -tn | grep ":19999.*ESTABLISHED" | wc -l
```

### On Child Node:

1. **Check Connection Status:**
```bash
# Should show established connection to parent
ss -tn | grep "<parent-ip>:19999"
```

2. **Verify No Local Web Interface:**
```bash
# Children shouldn't listen on 19999
ss -ln | grep :19999  # Should return nothing
```

## Performance Considerations

### Reducing Child Resource Usage

If children are using too much memory:

```ini
[global]
    memory mode = ram
    history = 900  # 15 minutes instead of 1 hour
    update every = 2  # Update every 2 seconds instead of 1

[plugins]
    # Disable unnecessary plugins
    apps = no
    ebpf = no
    tc = no
    # ... etc
```

### Parent Storage Management

If parents are using too much disk:

```ini
[db]
    mode = dbengine
    storage tiers = 1  # Reduce from default 3
    dbengine multihost disk space MB = 1024  # Limit to 1GB
```

## Common Log Messages

### Success Messages:
```
STREAM 'child-hostname' [from [IP]:PORT]: streaming api key accepted
STREAM 'child-hostname' [from [IP]:PORT]: receiving metrics
```

### Error Messages:
```
# API key mismatch
rejecting streaming connection; API key is not allowed

# Network issues  
failed to connect for stream info: connection refused

# Firewall blocking
failed to connect for stream info: no route to host
```

## Quick Fixes Checklist

- [ ] API key in child's stream.conf matches parent's [api-key] section name
- [ ] Parent has `allow from = *` in API key section
- [ ] Firewall allows port 19999 between nodes
- [ ] Network routing exists between clusters (for mesh)
- [ ] Netdata service is running on both nodes
- [ ] No typos in IP addresses or hostnames
- [ ] Stream.conf has proper permissions (640, owned by netdata)