# Netdata Streaming Authentication Issues

This document tracks the Netdata streaming authentication failures between child and parent nodes.

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