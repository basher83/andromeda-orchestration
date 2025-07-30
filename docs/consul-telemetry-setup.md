# Consul Telemetry Setup Guide

This guide documents the process for enabling Consul telemetry and configuring Netdata to collect metrics across the cluster.

## Overview

Consul telemetry exposes Prometheus-compatible metrics that can be collected by monitoring systems like Netdata. This setup involves:

1. Enabling telemetry endpoints on all Consul nodes
2. Creating ACL policies and tokens for secure access
3. Configuring Netdata collectors
4. Validating the setup

## Prerequisites

- Consul cluster with ACLs enabled
- Netdata installed on monitoring nodes
- Infisical access for secret storage
- Ansible with `infisical.vault` collection

## Implementation Steps

### Step 1: Enable Telemetry on Consul Nodes

The telemetry configuration needs to be added to each Consul node's configuration file.

**Configuration Block:**
```hcl
# Expose Prometheus endpoint for monitoring
telemetry {
  prometheus_retention_time = "360h"
  disable_hostname = false
  metrics_prefix = "consul"
}
```

**Playbook: `playbooks/infrastructure/simple-telemetry-enable.yml`**
```bash
uv run ansible-playbook playbooks/infrastructure/simple-telemetry-enable.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

This playbook:
- Checks if telemetry is already configured
- Adds the telemetry block to `/etc/consul.d/consul.hcl`
- Reloads Consul service
- Validates the endpoint is accessible

### Step 2: Create ACL Policy and Token

Consul's ACL system requires a token with appropriate permissions to access metrics.

**ACL Policy: `prometheus-scraping`**
```hcl
# Policy for Prometheus/Netdata scraping
operator = "read"

node_prefix "" {
  policy = "read"
}

agent_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "read"
}
```

**Playbook: `playbooks/infrastructure/create-prometheus-acl.yml`**
```bash
uv run ansible-playbook playbooks/infrastructure/create-prometheus-acl.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

This creates:
- ACL policy named "prometheus-scraping"
- ACL token with the policy attached
- Tests the token against the metrics endpoint

### Step 3: Configure Netdata Collectors

Netdata needs to be configured with the ACL token to collect Consul metrics.

**Netdata Configuration: `/etc/netdata/go.d/consul.conf`**
```yaml
jobs:
  - name: local
    url: http://127.0.0.1:8500
    acl_token: "<token-from-step-2>"
    update_every: 1
    timeout: 2
    autodetection_retry: 0
    collect_node_metadata: yes
    collect_service_metadata: yes
```

**Playbook: `playbooks/infrastructure/configure-netdata-consul.yml`**
```bash
uv run ansible-playbook playbooks/infrastructure/configure-netdata-consul.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Step 4: Store Token in Infisical

The ACL token should be stored securely in Infisical for future use.

**Using Infisical MCP Tool:**
```python
mcp__infisical__create-secret(
    projectId="7b832220-24c0-45bc-a5f1-ce9794a31259",
    environmentSlug="prod",
    secretPath="/apollo-13/consul",
    secretName="PROMETHEUS_SCRAPING_TOKEN",
    secretValue="<generated-token>"
)
```

**Location:** `/apollo-13/consul/PROMETHEUS_SCRAPING_TOKEN`

## Validation

### Check Telemetry Endpoint

With ACL token:
```bash
curl -H "X-Consul-Token: <token>" \
  http://<consul-node>:8500/v1/agent/metrics?format=prometheus
```

### List Available Metrics in Netdata

```bash
# List all Consul charts
curl -s http://<node>:19999/api/v1/charts | \
  jq -r '.charts | keys[] | select(startswith("consul"))'

# View specific metric
curl "http://<node>:19999/api/v1/data?chart=consul_local.autopilot_health_status&after=-60"
```

## Available Metrics

Once configured, the following Consul metrics are available:

- **Autopilot Metrics**
  - `consul_local.autopilot_failure_tolerance`
  - `consul_local.autopilot_health_status`

- **Client RPC Metrics**
  - `consul_local.client_rpc_requests_rate`
  - `consul_local.client_rpc_requests_failed_rate`
  - `consul_local.client_rpc_requests_exceeded_rate`

- **KV Store Metrics**
  - `consul_local.kvs_apply_operations_rate`

- **Health Check Metrics**
  - `consul_local.health_check_*_status`

- **Performance Metrics**
  - `consul_local.gc_pause_time`
  - Memory usage metrics
  - Raft consensus metrics

## Troubleshooting

### Telemetry Endpoint Returns 403 Forbidden

This indicates ACLs are enabled but no token was provided. Ensure:
1. The ACL token is valid
2. The token has the correct policy attached
3. Include the token in the request header

### Netdata Not Collecting Metrics

1. Check Netdata service is running: `systemctl status netdata`
2. Verify configuration: `cat /etc/netdata/go.d/consul.conf`
3. Check Netdata logs: `journalctl -u netdata -f`
4. Ensure the ACL token in the config is correct

### Consul Not Reloading Configuration

1. Validate configuration: `consul validate /etc/consul.d/consul.hcl`
2. Check Consul logs: `journalctl -u consul -f`
3. Manually reload: `consul reload`

## Playbooks Reference

All telemetry-related playbooks are in `playbooks/infrastructure/`:

- `simple-telemetry-enable.yml` - Basic telemetry enablement
- `create-prometheus-acl.yml` - ACL policy and token creation
- `configure-netdata-consul.yml` - Netdata collector configuration
- `consul-telemetry-setup.yml` - Comprehensive setup (includes all steps)
- `enable-consul-telemetry.yml` - Role-based telemetry enablement

## Security Considerations

1. **ACL Tokens**: Always use ACL tokens for production environments
2. **Token Storage**: Store tokens in Infisical, never in plain text
3. **Minimal Permissions**: The policy only grants read access as needed
4. **Network Security**: Consider firewall rules for metrics endpoints

## Next Steps

1. Configure Netdata dashboards for Consul monitoring
2. Set up alerts for critical metrics
3. Document metric thresholds for your environment
4. Consider implementing metric retention policies