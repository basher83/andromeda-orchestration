# Netdata Streaming Role

This role configures Netdata streaming between parent and child nodes, enabling centralized metrics collection.

## Features

- Child node streaming to parent(s)
- Parent node accepting child connections
- Proxy node configuration (both parent and child)
- Multi-parent redundancy support
- SSL/TLS encryption for streaming
- Infisical integration for API keys

## Architecture

```
┌─────────────┐     Stream      ┌─────────────┐
│ Child Node  │ ──────────────> │ Parent Node │
│  (Collector)│                  │  (Storage)  │
└─────────────┘                  └─────────────┘

┌─────────────┐     Stream      ┌─────────────┐     Stream      ┌─────────────┐
│ Child Node  │ ──────────────> │ Proxy Node  │ ──────────────> │ Parent Node │
└─────────────┘                  └─────────────┘                  └─────────────┘
```

## Requirements

- Netdata installed and configured on all nodes
- Network connectivity between nodes (port 19999)
- Matching API keys between parent and child
- Ansible 2.9+

## Role Variables

### Node Type Configuration

```yaml
netdata_node_type: "standalone"  # Options: standalone, child, parent, proxy
```

### Child Node Settings

```yaml
# Basic streaming
netdata_streaming_enabled: false
netdata_streaming_destination: "parent.example.com:19999"
netdata_streaming_api_key: "unique-api-key"

# Advanced settings
netdata_streaming_buffer_size_bytes: 10485760
netdata_streaming_reconnect_delay: 5
netdata_streaming_compression: true
netdata_streaming_send_charts_matching: "*"

# Multiple parents (for redundancy)
netdata_streaming_parents:
  - destination: "parent1.example.com:19999"
    api_key: "api-key-1"
  - destination: "parent2.example.com:19999"
    api_key: "api-key-2"
```

### Parent Node Settings

```yaml
netdata_parent_enabled: false
netdata_parent_api_key: "parent-api-key"
netdata_parent_allow_from: "*"
netdata_parent_default_history: 3600
netdata_parent_default_memory_mode: "dbengine"
netdata_parent_health_enabled: "auto"
netdata_parent_postpone_alarms_on_connect: 60

# Multiple children with different settings
netdata_parent_children:
  - name: "web-servers"
    api_key: "web-api-key"
    allow_from: "192.168.1.0/24"
  - name: "database-servers"
    api_key: "db-api-key"
    allow_from: "192.168.2.0/24"
    default_history: 7200
```

### SSL/TLS Configuration

```yaml
netdata_streaming_ssl_enabled: false
netdata_streaming_ssl_ca_path: "/etc/ssl/certs/"
netdata_streaming_ssl_ca_file: ""
netdata_streaming_ssl_cert: ""
netdata_streaming_ssl_key: ""
```

### Infisical Integration

```yaml
netdata_use_infisical: false
netdata_infisical_path: "/apollo-13/services/netdata"
```

## Dependencies

- `netdata_install` role
- `netdata_configure` role

## Example Playbooks

### Simple Parent-Child Setup

```yaml
# Deploy child nodes
- hosts: netdata_children
  roles:
    - role: netdata_streaming
      vars:
        netdata_node_type: "child"
        netdata_streaming_destination: "metrics.example.com:19999"
        netdata_streaming_api_key: "11111111-2222-3333-4444-555555555555"

# Deploy parent node
- hosts: netdata_parents
  roles:
    - role: netdata_streaming
      vars:
        netdata_node_type: "parent"
        netdata_parent_api_key: "11111111-2222-3333-4444-555555555555"
        netdata_parent_allow_from: "*"
```

### High Availability with Multiple Parents

```yaml
- hosts: netdata_children
  roles:
    - role: netdata_streaming
      vars:
        netdata_node_type: "child"
        netdata_streaming_parents:
          - destination: "parent1.example.com:19999"
            api_key: "api-key-parent1"
          - destination: "parent2.example.com:19999"
            api_key: "api-key-parent2"
```

### Proxy Node Configuration

```yaml
- hosts: netdata_proxies
  roles:
    - role: netdata_streaming
      vars:
        netdata_node_type: "proxy"
        # Acts as child to upstream parent
        netdata_streaming_destination: "central.example.com:19999"
        netdata_streaming_api_key: "upstream-api-key"
        # Acts as parent to downstream children
        netdata_parent_api_key: "downstream-api-key"
        netdata_parent_allow_from: "192.168.0.0/16"
```

### Secure Streaming with SSL/TLS

```yaml
- hosts: all
  roles:
    - role: netdata_streaming
      vars:
        netdata_streaming_ssl_enabled: true
        netdata_streaming_ssl_ca_file: "{{ ssl_ca_cert }}"
        netdata_streaming_ssl_cert: "{{ ssl_cert }}"
        netdata_streaming_ssl_key: "{{ ssl_key }}"
```

### Using Infisical for API Keys

```yaml
- hosts: all
  roles:
    - role: netdata_streaming
      vars:
        netdata_use_infisical: true
        netdata_infisical_path: "/apollo-13/services/netdata"
        netdata_node_type: "{{ 'parent' if inventory_hostname in groups['parents'] else 'child' }}"
```

## Files Generated

- `/etc/netdata/stream.conf` - Streaming configuration

## Handlers

- `restart netdata` - Restarts Netdata service

## Tags

- `netdata` - All Netdata tasks
- `netdata-streaming` - Streaming configuration
- `netdata-child` - Child node configuration
- `netdata-parent` - Parent node configuration
- `netdata-proxy` - Proxy node configuration
- `netdata-ssl` - SSL/TLS configuration
- `netdata-secrets` - Secret retrieval tasks

## Streaming Topologies

### Star Topology
All children stream to one parent:
```
Child1 ─┐
Child2 ──┼──> Parent
Child3 ─┘
```

### Redundant Parents
Children stream to multiple parents:
```
Child1 ──┬──> Parent1
         └──> Parent2
```

### Hierarchical
Multi-tier with proxy nodes:
```
Edge ──> Regional Proxy ──> Central Parent
```

## Troubleshooting

### Child Not Connecting

1. Check API key matches between child and parent
2. Verify network connectivity: `telnet parent-host 19999`
3. Check parent allows child's IP in `allow from`
4. Review logs: `journalctl -u netdata -f`

### Missing Metrics on Parent

1. Verify `send charts matching` pattern
2. Check streaming is enabled in child's stream.conf
3. Ensure parent has sufficient history/memory configured

### SSL/TLS Issues

1. Verify certificate paths and permissions
2. Check certificate validity and chain
3. Ensure CA certificate is trusted
4. Test with `netdata_streaming_ssl_skip_verify: true` (not for production)

## Performance Tuning

### For Children
```yaml
netdata_streaming_buffer_size_bytes: 10485760  # 10MB buffer
netdata_streaming_compression: true             # Reduce bandwidth
```

### For Parents
```yaml
netdata_parent_default_memory_mode: "dbengine"
netdata_parent_default_history: 86400  # 24 hours
netdata_parent_postpone_alarms_on_connect: 60  # Avoid alarm floods
```

## License

MIT

## Author Information

Andromeda Orchestration Infrastructure Team
