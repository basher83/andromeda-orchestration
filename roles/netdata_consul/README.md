# Netdata Consul Role

This role integrates Netdata with HashiCorp Consul for service discovery and monitoring.

## Features

- Register Netdata as a Consul service
- Configure health checks for Netdata
- Enable Consul metrics collection via go.d plugin
- Support for Consul ACL tokens
- TLS/SSL configuration for secure communication
- Service tags and metadata configuration

## Requirements

- Netdata installed and running
- Consul agent running on the same host or accessible remotely
- Ansible 2.9+
- go.d plugin enabled in Netdata (for metrics collection)

## Role Variables

### Basic Configuration

```yaml
# Enable Consul integration
netdata_consul_enabled: false

# Netdata service details
netdata_port: 19999

# Consul service registration
netdata_consul_service_name: "netdata"
netdata_consul_service_port: "{{ netdata_port }}"
netdata_consul_service_tags:
  - "monitoring"
  - "metrics"
netdata_consul_service_meta:
  version: "latest"
  type: "monitoring"
```

### Health Check Configuration

```yaml
netdata_consul_health_check_enabled: true
netdata_consul_health_check_interval: "10s"
netdata_consul_health_check_timeout: "5s"
netdata_consul_health_check_http: "http://{{ ansible_default_ipv4.address }}:{{ netdata_port }}/api/v1/info"
netdata_consul_enable_tag_override: false
```

### Consul Metrics Collection

```yaml
# Enable Consul collector in Netdata
netdata_consul_collector_enabled: true
netdata_consul_url: "http://127.0.0.1:8500"
netdata_consul_datacenter: ""
netdata_consul_update_every: 1
netdata_consul_timeout: 2

# Metrics to collect
netdata_consul_collect_node_metadata: true
netdata_consul_collect_service_metadata: true
netdata_consul_collect_checks: true
```

### Security Configuration

```yaml
# ACL token for Consul API
netdata_consul_acl_token: ""

# TLS configuration
netdata_consul_tls_enabled: false
netdata_consul_tls_skip_verify: false
netdata_consul_tls_ca: "/path/to/ca.pem"
netdata_consul_tls_cert: "/path/to/cert.pem"
netdata_consul_tls_key: "/path/to/key.pem"
```

## Dependencies

- `netdata_install` - Netdata must be installed
- `netdata_configure` - Basic configuration should be complete
- Consul should be installed and running (not managed by this role)

## Example Playbooks

### Basic Consul Integration

```yaml
- hosts: consul_nodes
  roles:
    - role: netdata_consul
      vars:
        netdata_consul_enabled: true
        netdata_consul_service_name: "netdata"
        netdata_consul_collector_enabled: true
```

### With Custom Service Tags

```yaml
- hosts: monitoring
  roles:
    - role: netdata_consul
      vars:
        netdata_consul_enabled: true
        netdata_consul_service_tags:
          - "monitoring"
          - "metrics"
          - "{{ env_name }}"
          - "{{ datacenter }}"
        netdata_consul_service_meta:
          version: "{{ netdata_version }}"
          environment: "{{ env_name }}"
          owner: "platform-team"
```

### With ACL Token

```yaml
- hosts: secure_environment
  roles:
    - role: netdata_consul
      vars:
        netdata_consul_enabled: true
        netdata_consul_acl_token: "{{ vault_consul_acl_token }}"
        netdata_consul_collector_enabled: true
```

### With TLS/SSL

```yaml
- hosts: production
  roles:
    - role: netdata_consul
      vars:
        netdata_consul_enabled: true
        netdata_consul_tls_enabled: true
        netdata_consul_tls_ca: "/etc/consul/ca.pem"
        netdata_consul_tls_cert: "/etc/consul/client-cert.pem"
        netdata_consul_tls_key: "/etc/consul/client-key.pem"
```

### Custom Health Check

```yaml
- hosts: all
  roles:
    - role: netdata_consul
      vars:
        netdata_consul_enabled: true
        netdata_consul_health_check_interval: "30s"
        netdata_consul_health_check_timeout: "10s"
        netdata_consul_health_check_http: "http://localhost:19999/api/v1/info"
```

## Service Discovery

Once registered, Netdata can be discovered via Consul:

```bash
# Query service via DNS
dig @127.0.0.1 -p 8600 netdata.service.consul

# Query via API
curl http://localhost:8500/v1/catalog/service/netdata

# Health check status
curl http://localhost:8500/v1/health/service/netdata
```

## Metrics Available

When the Consul collector is enabled, Netdata collects:

- **Consul Node Metrics**
  - Leader status
  - Peer count
  - Service count
  - Check status

- **Service Metrics**
  - Service health
  - Check latency
  - Service instances

- **Network Metrics**
  - RPC calls
  - HTTP requests
  - Raft metrics

## Files Generated

- `/etc/consul.d/netdata.json` - Consul service definition
- `/etc/netdata/go.d/consul.conf` - Consul collector configuration

## Handlers

- `restart netdata` - Restarts Netdata service
- `reload consul` - Reloads Consul configuration

## Tags

- `netdata` - All Netdata tasks
- `netdata-consul` - Consul integration tasks
- `netdata-consul-service` - Service registration
- `netdata-consul-collector` - Metrics collector configuration

## Troubleshooting

### Service Not Registered

1. Check Consul agent is running:

```bash
systemctl status consul
```

2. Verify connectivity:

```bash
curl http://localhost:8500/v1/agent/self
```

3. Check ACL permissions if using tokens

### Health Check Failing

1. Verify Netdata is accessible:

```bash
curl http://localhost:19999/api/v1/info
```

2. Check firewall rules
3. Verify health check URL is correct

### No Consul Metrics in Netdata

1. Ensure go.d plugin is enabled:

```bash
grep "go.d" /etc/netdata/netdata.conf
```

2. Check collector configuration:

```bash
cat /etc/netdata/go.d/consul.conf
```

3. Verify Consul API accessibility:

```bash
curl -H "X-Consul-Token: your-token" http://localhost:8500/v1/agent/metrics
```

### ACL Token Issues

1. Verify token has required permissions:

```hcl
# Minimum ACL policy needed
agent_prefix "" {
  policy = "read"
}
service_prefix "" {
  policy = "write"
}
```

1. Test token:

```bash
curl -H "X-Consul-Token: your-token" http://localhost:8500/v1/agent/services
```

## Integration with Other Roles

This role works well with:
- `netdata_streaming` - Stream Consul metrics to parent nodes
- `consul` - Deploy and configure Consul
- `netdata_cloud` - Send Consul metrics to Netdata Cloud

## Best Practices

1. **Use Service Tags** - Tag services appropriately for filtering
2. **Set Meaningful Metadata** - Include version, environment, owner
3. **Configure Health Checks** - Ensure services are monitored
4. **Secure with ACLs** - Use tokens in production
5. **Enable TLS** - Encrypt communication in production

## License

MIT

## Author Information

Andromeda Orchestration Infrastructure Team
