# Consul Telemetry Implementation Summary

**Date**: 2025-07-30

## Overview

Successfully enabled Consul telemetry across the cluster and configured Netdata to collect Consul metrics using Prometheus endpoints.

## Implementation Steps Completed

### 1. Enabled Telemetry on All Consul Nodes ✅

- Modified `/etc/consul.d/consul.hcl` on all Consul nodes
- Added telemetry configuration block:
  ```hcl
  telemetry {
    prometheus_retention_time = "360h"
    disable_hostname = false
    metrics_prefix = "consul"
  }
  ```
- Nodes updated: All nomad-server and nomad-client containers

### 2. Created Consul ACL Policy and Token ✅

- Policy Name: `prometheus-scraping`
- Policy Rules: Read access to operator, nodes, agents, and services
- Token ID: `73d098e0-3dda-a9d9-e9e2-4756ee1334e4`
- Token validated and working

### 3. Configured Netdata Collectors ✅

- Updated `/etc/netdata/go.d/consul.conf` on all nodes
- Configured with ACL token for secure access
- Netdata restarted and collecting metrics successfully

### 4. Validation ✅

- Confirmed telemetry endpoints accessible at `/v1/agent/metrics?format=prometheus`
- Verified Netdata is collecting Consul metrics (consul_local.* charts)
- All Consul nodes reporting metrics successfully

## Playbooks Created

1. `simple-telemetry-enable.yml` - Basic telemetry enablement
2. `create-prometheus-acl.yml` - ACL policy and token creation
3. `configure-netdata-consul.yml` - Netdata configuration
4. `consul-telemetry-setup.yml` - Comprehensive setup (needs refinement)
5. `enable-consul-telemetry.yml` - Role-based telemetry enablement

## Metrics Now Available

- Consul autopilot metrics
- Client RPC request rates and failures
- Key-Value store operations
- Health check statuses
- Raft consensus metrics
- Memory and GC metrics
- Service discovery metrics

## Next Steps

1. **IMPORTANT**: Store the Prometheus token in Infisical:
   - Path: `/apollo-13/consul/PROMETHEUS_SCRAPING_TOKEN`
   - Value: `73d098e0-3dda-a9d9-e9e2-4756ee1334e4`

2. Configure dashboards in Netdata for Consul monitoring

3. Set up alerts for critical Consul metrics

4. Consider enabling telemetry on any new Consul nodes added to the cluster

## Files Modified

- `/etc/consul.d/consul.hcl` - Added telemetry block on all Consul nodes
- `/etc/netdata/go.d/consul.conf` - Created/updated on all nodes with Netdata

## Verification Commands

```bash
# Check telemetry endpoint (requires token)
curl -H "X-Consul-Token: 73d098e0-3dda-a9d9-e9e2-4756ee1334e4" \
  http://<consul-node>:8500/v1/agent/metrics?format=prometheus

# List Consul metrics in Netdata
curl -s http://<node>:19999/api/v1/charts | jq -r '.charts | keys[] | select(startswith("consul"))'

# View specific metric data
curl "http://<node>:19999/api/v1/data?chart=consul_local.autopilot_health_status&after=-60"
```
