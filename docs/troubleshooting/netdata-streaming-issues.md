# Netdata Streaming Authentication Issues

[TODO]: Cross referance with operations/netdata-streaming-troubleshooting.md and combine the two documents.

This document tracks the Netdata streaming authentication failures between child and parent nodes.

---

**2025-08-02** The following issues have been resovled. Multiple misconfigurations across all nodes were causing the issues. The issue was resolved by:

- Ensuring the correct API key is used in the stream.conf file on all nodes. I created actual PARENT and CHILD API keys.
- Simplified the stream.conf file on all nodes. Previous versions were using improper syntax.
- Ensuring the correct destination IP in the stream.conf file on all nodes. Some nodes points to 10.xx vs 11.xx.
- Resolved ACL issues with Consul, netdata-child-health is now healthy. _TODO_: netdata-parent-health was mentioned in docs but Consul is not running on parent nodes, they are proxmox hosts. Should we install Consul on parent nodes?
- Enabled web server on all nodes. Example:

```bash
# /etc/netdata/netdata.conf
[web]
    mode = static-threaded
    enable gzip compression = True
    gzip compression level = 3
```

## Current Configuration

Child Nodes in nomad cluster (doggos-homelab):

```bash
# /etc/netdata/stream.conf
# Streaming configuration for sending metrics to parent
[stream]
    enabled = yes
    destination = 192.168.11.2 192.168.11.3 192.168.11.4
    api key = child_api_key
```

Parent Nodes in nomad cluster (doggos-homelab):

```bash
# /etc/netdata/stream.conf
# Netdata streaming configuration
# This file controls streaming and replication
# This example is from Holly (192.168.11.3)

[stream]
    enabled = yes
    destination = 192.168.11.2
    api key = parent_api_key

# Accept metrics from Children
[child_api_key]
    enabled = yes
    db = dbengine
    allow from = *

# Accept metric from Parents
[parent_api_key]
    enabled = yes
    db = dbengine
    allow from = 192.168.11.2 192.168.11.4 192.168.30.50
```

Current Netdata configuration on all nodes is as follows:

### Parents

```bash
lloyd: 192.168.11.2
holly: 192.168.11.3
mable: 192.168.11.4
pve1: 192.168.30.50
```

### Children

```bash
nomad-client-1-lloyd: 192.168.11.20
nomad-client-2-holly: 192.168.11.21
nomad-client-3-mable: 192.168.11.22
nomad-server-1-lloyd: 192.168.11.11
nomad-server-2-holly: 192.168.11.12
nomad-server-3-mable: 192.168.11.13
proxmoxt430: 192.168.30.30
pbs: 192.168.30.200
```

### Still need to add:

- TrueNAS: 192.168.30.6 (WIP)

## Issues:

When running playbook that edits netdata.conf, it creates a backup filename similar to: `netdata.conf.3052946.2025-08-03@08:59:29~` This filename is not very clean.

## Previous issues are below this line

---

## Issue Summary

Netdata child nodes on the Nomad clients are failing to connect to parent nodes due to API key authentication failures.

## Error Messages

```
time=2025-08-02T06:49:18.255Z comm=netdata source=daemon level=error
msg_id=6e2e3839067648968b646045dbf28d66 node=nomad-client-1 code=403
msg="STREAM CONNECT 'nomad-client-1' [to 192.168.11.4:19999]:
remote server denied access, probably we don't have the right API key?
- will retry in 60 secs"
```

## Current Configuration

### Child Nodes (Nomad Clients)

Location: `/etc/netdata/stream.conf`

```ini
[stream]
    enabled = yes
    destination = 192.168.11.2:19999 192.168.11.3:19999 192.168.11.4:19999
    api key = nomad-cluster-api-key
    timeout seconds = 60
    default port = 19999
    send charts matching = *
    buffer size bytes = 1048576
    reconnect delay seconds = 5
```

### Parent Nodes

The parent nodes (192.168.11.2/3/4) appear to be rejecting the "nomad-cluster-api-key".

## Impact

- Consul health check "netdata-child-health" is critical
- No metrics streaming from Nomad clients to parent nodes
- Monitoring visibility reduced for the Nomad cluster

## Root Cause

The parent Netdata nodes are not configured to accept the "nomad-cluster-api-key" from child nodes, or the key is incorrect.

## Resolution Steps

1. Check parent node configuration at `/etc/netdata/stream.conf`
2. Verify the API key configuration matches between parents and children
3. Ensure parent nodes have the streaming receiver enabled
4. Check firewall rules for port 19999
5. Restart Netdata services after configuration changes

## Temporary Impact

This issue does not affect the core infrastructure deployment but reduces monitoring capabilities. Can be addressed after resolving the service identity issues.

## References

- [Netdata Streaming Documentation](https://learn.netdata.cloud/docs/streaming)
- [Netdata Parent-Child Configuration](https://learn.netdata.cloud/docs/streaming/streaming-configuration-reference)
