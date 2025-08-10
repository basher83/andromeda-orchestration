# Netdata Consul Template Role

This role configures Consul Template to dynamically manage Netdata configuration based on Consul KV store values.

## Features

- Dynamic alarm threshold management via Consul KV
- Automatic configuration reload on KV changes
- Multiple template support
- Consul Template service management
- KV store initialization with defaults
- Support for custom templates

## Requirements

- Netdata installed and configured
- Consul agent running and accessible
- Ansible 2.9+
- Network access to Consul cluster

## Architecture

```text
┌─────────────┐     Watch KV      ┌─────────────┐     Update      ┌─────────────┐
│ Consul KV   │ <──────────────── │   Consul    │ ──────────────> │   Netdata   │
│    Store    │                   │   Template  │                  │    Config   │
└─────────────┘                   └─────────────┘                  └─────────────┘
```

## Role Variables

### Basic Configuration

```yaml
# Enable Consul Template integration
netdata_consul_template_enabled: false

# Consul Template version
consul_template_version: "0.35.0"

# Logging
netdata_consul_template_log_level: "info"

# Enable CPU alarm template example
netdata_consul_template_cpu_alarms: false

# Initialize KV store with default values
netdata_consul_template_populate_kv: false
```

### Template Configuration

```yaml
# Define templates to manage
netdata_consul_template_configs:
  - name: "cpu.conf.ctmpl"
    source: "cpu.conf.ctmpl"
    destination: "/etc/netdata/health.d/cpu.conf"
    command: "systemctl reload netdata"
    wait_min: "5s"
    wait_max: "30s"

  - name: "memory.conf.ctmpl"
    source: "memory.conf.ctmpl"
    destination: "/etc/netdata/health.d/memory.conf"
    command: "systemctl reload netdata"
    wait_min: "5s"
    wait_max: "30s"
```

### Default KV Values

```yaml
# Default alarm thresholds (populated if netdata_consul_template_populate_kv is true)
netdata_consul_kv_defaults:
  - key: "netdata/alarms/cpu/10min_usage_warning_low"
    value: "75"
  - key: "netdata/alarms/cpu/10min_usage_warning_high"
    value: "85"
  - key: "netdata/alarms/cpu/10min_usage_critical_low"
    value: "85"
  - key: "netdata/alarms/cpu/10min_usage_critical_high"
    value: "95"
  - key: "netdata/alarms/memory/available_warning"
    value: "20"
  - key: "netdata/alarms/memory/available_critical"
    value: "10"
```

## Dependencies

- `netdata_install` - Netdata must be installed
- `netdata_configure` - Basic configuration complete
- Consul should be running (not managed by this role)

## Example Playbooks

### Basic Consul Template Setup

```yaml
- hosts: netdata_nodes
  roles:
    - role: netdata_consul_template
      vars:
        netdata_consul_template_enabled: true
        netdata_consul_template_cpu_alarms: true
        netdata_consul_template_populate_kv: true
```

### Custom Templates

```yaml
- hosts: monitoring
  roles:
    - role: netdata_consul_template
      vars:
        netdata_consul_template_enabled: true
        netdata_consul_template_configs:
          - name: "disk.conf.ctmpl"
            source: "custom/disk.conf.ctmpl"
            destination: "/etc/netdata/health.d/disk.conf"
            command: "systemctl reload netdata"
            wait_min: "10s"
            wait_max: "60s"
```

### Environment-Specific Thresholds

```yaml
- hosts: production
  roles:
    - role: netdata_consul_template
      vars:
        netdata_consul_template_enabled: true
        netdata_consul_kv_defaults:
          - key: "netdata/alarms/cpu/10min_usage_warning_low"
            value: "60"  # More aggressive for production
          - key: "netdata/alarms/cpu/10min_usage_critical_low"
            value: "80"
```

## Template Examples

### CPU Alarm Template (cpu.conf.ctmpl)

```hcl
# CPU usage alarms - dynamically configured via Consul KV
alarm: cpu_10min_usage
    on: system.cpu
    lookup: average -10m of user,system
    units: %
    every: 1m
    {{ range $key, $pairs := tree "netdata/alarms/cpu/" }}
    {{ if eq $key "10min_usage_warning_low" }}warn: $this > {{ .Value }}{{ end }}
    {{ if eq $key "10min_usage_warning_high" }}warn: $this > {{ .Value }}{{ end }}
    {{ if eq $key "10min_usage_critical_low" }}crit: $this > {{ .Value }}{{ end }}
    {{ if eq $key "10min_usage_critical_high" }}crit: $this > {{ .Value }}{{ end }}
    {{ end }}
    info: CPU usage over last 10 minutes
```

### Memory Alarm Template

```hcl
alarm: ram_available
    on: system.ram
    lookup: average -1m of available
    units: %
    every: 1m
    {{ with key "netdata/alarms/memory/available_warning" }}
    warn: $this < {{ . }}
    {{ end }}
    {{ with key "netdata/alarms/memory/available_critical" }}
    crit: $this < {{ . }}
    {{ end }}
    info: Available RAM
```

## Managing Thresholds

### Via Consul CLI

```bash
# Set CPU warning threshold
consul kv put netdata/alarms/cpu/10min_usage_warning_low 70

# Set memory critical threshold
consul kv put netdata/alarms/memory/available_critical 5

# View all Netdata alarms
consul kv get -recurse netdata/alarms/
```

### Via Consul UI

1. Navigate to Consul UI ([http://consul-server:8500](http://consul-server:8500))
2. Go to Key/Value section
3. Navigate to `netdata/alarms/`
4. Edit values as needed

### Via Ansible

```yaml
- name: Update alarm thresholds
  consul_kv:
    key: "netdata/alarms/cpu/10min_usage_critical_high"
    value: "90"
    host: "{{ consul_host }}"
```

## Files and Directories

- `/etc/consul-template/` - Consul Template configuration
- `/etc/consul-template/templates/` - Template files
- `/etc/systemd/system/consul-template.service` - Systemd service
- `/etc/netdata/health.d/` - Generated alarm configurations

## Service Management

```bash
# Start Consul Template
systemctl start consul-template

# Check status
systemctl status consul-template

# View logs
journalctl -u consul-template -f

# Reload templates
systemctl reload consul-template
```

## Troubleshooting

### Templates Not Rendering

1. Check Consul Template service:
   ```bash
   systemctl status consul-template
   ```

2. Verify Consul connectivity:
   ```bash
   consul-template -consul-addr=http://localhost:8500 -dry
   ```

3. Check template syntax:
   ```bash
   consul-template -template="/path/to/template:test.out" -dry -once
   ```

### KV Values Not Updating

1. Verify KV values exist:
   ```bash
   consul kv get -recurse netdata/
   ```

2. Check Consul Template logs:
   ```bash
   journalctl -u consul-template | tail -50
   ```

3. Test template manually:
   ```bash
   consul-template -template="cpu.conf.ctmpl:test.conf" -once
   ```

### Netdata Not Reloading

1. Verify reload command works:
   ```bash
   systemctl reload netdata
   ```

2. Check Consul Template command output:
   ```bash
   consul-template -log-level=debug
   ```

## Advanced Configuration

### Multiple Consul Clusters

```yaml
netdata_consul_template_consul_addr: "consul-prod.example.com:8500"
netdata_consul_template_consul_token: "{{ vault_consul_token }}"
```

### Custom Wait Times

```yaml
netdata_consul_template_configs:
  - name: "critical.conf.ctmpl"
    destination: "/etc/netdata/health.d/critical.conf"
    command: "systemctl reload netdata"
    wait_min: "2s"   # Quick response for critical alarms
    wait_max: "10s"
```

### Backup Before Update

```yaml
netdata_consul_template_configs:
  - name: "production.conf.ctmpl"
    destination: "/etc/netdata/health.d/production.conf"
    command: "cp /etc/netdata/health.d/production.conf /backup/ && systemctl reload netdata"
    backup: true
```

## Best Practices

1. **Test Templates** - Always test in development first
2. **Version Control** - Keep templates in version control
3. **Gradual Rollout** - Update one node at a time
4. **Monitor Changes** - Log all threshold changes
5. **Set Boundaries** - Define min/max acceptable values
6. **Document Thresholds** - Maintain documentation of alarm meanings

## Integration Examples

### With Monitoring Pipeline

```yaml
# Update thresholds based on historical data
- name: Calculate optimal thresholds
  script: analyze_metrics.py
  register: thresholds

- name: Update Consul KV
  consul_kv:
    key: "netdata/alarms/{{ item.key }}"
    value: "{{ item.value }}"
  loop: "{{ thresholds.results }}"
```

### With GitOps

```yaml
# Store thresholds in Git, apply via CI/CD
- name: Load thresholds from Git
  include_vars: "thresholds/{{ environment }}.yml"

- name: Apply to Consul
  consul_kv:
    key: "{{ item.key }}"
    value: "{{ item.value }}"
  loop: "{{ alarm_thresholds }}"
```

## License

MIT

## Author Information

Andromeda Orchestration Infrastructure Team
