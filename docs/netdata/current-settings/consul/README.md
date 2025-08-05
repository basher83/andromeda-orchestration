# Enable Prometheus telemetry for Netdata

Enable telemetry on your Consul Agent, by increasing the value of prometheus_retention_time from 0.

[Consul Template](roles/consul/templates/consul.hcl.j2)

```hcl
# Expose Prometheus endpoint for Netdata
telemetry {
  prometheus_retention_time = "{{ consul_prometheus_retention_time | default('360h') }}"
}
```

Add required ACLs to the Consul Agent.

- operator:read
- node:read
- agent:read

Configure consul.conf to use the ACL token.

```yaml
# Location: /etc/netdata/go.d/consul.conf

jobs:
  - name: local
    url: http://127.0.0.1:8500
    acl_token: "consul_api_token"
```

Check the logs for any errors with consul.

```bash
journalctl _SYSTEMD_INVOCATION_ID="$(systemctl show --value --property=InvocationID netdata)" --namespace=netdata --grep consul
```

Restart Netdata.

```bash
sudo systemctl restart netdata
```
