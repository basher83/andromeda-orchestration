# Netdata Role

This role installs and configures Netdata monitoring agents with support for:

- Standalone or parent-child streaming configurations
- Parent-to-parent mesh replication for multi-cluster environments
- Consul service registration and health checks
- Telemetry export (Prometheus format)
- Custom alarm notifications
- Machine learning anomaly detection

## Requirements

- Ansible 2.15 or higher
- Supported OS: Debian/Ubuntu, RHEL/CentOS

## Role Variables

### Basic Configuration

```yaml
# Installation method: 'package' or 'script'
netdata_install_method: "package"
netdata_version: "latest"

# Web interface
netdata_bind_to: "0.0.0.0"
netdata_port: 19999
netdata_web_enabled: true

# Memory and history
netdata_memory_mode: "dbengine"
netdata_history: 3600 # seconds
```

### Streaming Configuration

```yaml
# Enable streaming to a parent node
netdata_streaming_enabled: false
netdata_streaming_destination: "parent-node.example.com:19999"
netdata_streaming_api_key: "your-api-key"

# Enable as a parent node
netdata_parent_enabled: false
netdata_parent_api_key: "parent-api-key"
```

### Consul Integration

```yaml
netdata_consul_enabled: true
netdata_consul_service_name: "netdata"
netdata_consul_service_tags:
  - "monitoring"
  - "metrics"
```

## Dependencies

None

## Example Playbook

```yaml
---
- name: Deploy Netdata monitoring
  hosts: all
  become: true
  roles:
    - role: netdata
      vars:
        netdata_consul_enabled: true
        netdata_streaming_enabled: true
        netdata_streaming_destination: "netdata-parent.service.consul:19999"
        netdata_streaming_api_key: "{{ vault_netdata_streaming_api_key }}"
```

## Parent-Child Setup Example

Deploy a parent node:

```yaml
- name: Deploy Netdata parent
  hosts: monitoring-server
  become: true
  roles:
    - role: netdata
      vars:
        netdata_parent_enabled: true
        netdata_parent_api_key: "{{ vault_netdata_parent_api_key }}"
        netdata_consul_enabled: true
        netdata_consul_service_name: "netdata-parent"
```

Deploy child nodes:

```yaml
- name: Deploy Netdata children
  hosts: all:!monitoring-server
  become: true
  roles:
    - role: netdata
      vars:
        netdata_streaming_enabled: true
        netdata_streaming_destination: "netdata-parent.service.consul:19999"
        netdata_streaming_api_key: "{{ vault_netdata_parent_api_key }}"
        netdata_web_enabled: false # Optional: disable web on children
```

## Consul Template Integration

This role supports using Consul Template to dynamically manage Netdata configurations through Consul's KV store:

```yaml
- name: Deploy with Consul Template
  hosts: monitoring
  become: true
  roles:
    - role: netdata
      vars:
        netdata_consul_template_enabled: true
        netdata_consul_template_cpu_alarms: true
        netdata_consul_template_populate_kv: true
```

This allows you to:

- Change alarm thresholds without redeploying
- Manage configurations centrally in Consul
- Update multiple nodes simultaneously
- Use different thresholds per environment

### Updating Thresholds via Consul

```bash
# Update CPU warning threshold
consul kv put netdata/alarms/cpu/10min_usage_warning_low 80

# Update IO wait threshold
consul kv put netdata/alarms/cpu/10min_iowait_warning_high 50
```

## Dual-Network Architecture Support

This role supports streaming over separate networks (e.g., management and application networks):

```yaml
# Host variables
netdata_10g_ip: "192.168.11.2" # Application network IP
netdata_bind_to: "{{ netdata_10g_ip }}"

# Parent replication over application network
netdata_streaming_destination: "192.168.11.3:19999 192.168.11.4:19999"
```

## Parent Mesh Topology

For multi-cluster deployments, parent nodes can form a mesh topology for complete infrastructure visibility:

### Architecture

```
Cluster A (3 parents)              Cluster B (1 parent)
=====================              ====================
  Parent-A1 <----+----+--------->  Parent-B1
      ^          |    |               ^
      |          |    |               |
      v          |    |               |
  Parent-A2 <----+    +---------------+
      ^                               |
      |                               |
      v                               |
  Parent-A3 <-------------------------+

Full mesh: Each parent replicates to all others
```

### Benefits

- **Unified View**: Access all metrics from any parent node
- **High Availability**: If one parent fails, data is available from others
- **Cross-Cluster Visibility**: View metrics across different locations/networks
- **Load Distribution**: Query any parent to distribute load

### Configuration Example

Parent nodes configuration:

```yaml
# Enable mesh streaming
netdata_streaming_enabled: true
netdata_streaming_destination: "parent2:19999 parent3:19999 parent4:19999"
netdata_streaming_api_key: "{{ vault_netdata_mesh_api_key }}"

# Accept streams from other parents
netdata_parent_children:
  - api_key: "{{ vault_netdata_mesh_api_key }}"
    allow_from: "192.168.10.0/24"
    multiple_connections: "allow"
  - api_key: "{{ vault_netdata_mesh_api_key }}"
    allow_from: "192.168.30.0/24"
    multiple_connections: "allow"
```

### Deployment

```yaml
# Deploy mesh topology
- name: Configure parent mesh
  hosts: netdata_parents
  roles:
    - role: netdata
      vars:
        netdata_parent_enabled: true
        netdata_streaming_enabled: true
        netdata_streaming_destination: "{{ groups['netdata_parents'] | difference([inventory_hostname]) | join(':19999 ') }}:19999"
```

### Configuration file locations

- /etc/netdata/claim.conf (Needs sudo)
- /etc/netdata/stream.conf
- /etc/netdata/netdata.conf
- /etc/netdata/go.d/consul.conf (Monitoring Prometheus metrics, managed via cloud console. DO NOT EDIT THIS FILE.)

## License

MIT

## Author Information

Created for the NetBox Ansible Automation project
