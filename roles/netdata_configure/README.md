# Netdata Configure Role

This role handles the configuration of Netdata monitoring agent after installation.

## Features

- Core Netdata configuration (memory mode, history, update frequency)
- Web interface settings
- Plugin enable/disable management
- Alarm configuration
- Machine learning settings
- Database engine configuration
- Process scheduling and OOM settings

## Requirements

- Netdata must be installed (use `netdata_install` role first)
- Ansible 2.9+

## Role Variables

### Basic Configuration

```yaml
# Web interface
netdata_bind_to: "0.0.0.0"
netdata_port: 19999
netdata_web_enabled: true

# Memory and history
netdata_memory_mode: "dbengine"  # save, map, ram, none, alloc, dbengine
netdata_history: 3600            # seconds of history
netdata_update_every: 1          # data collection frequency

# Database engine (when using dbengine)
netdata_page_cache_size: 32
netdata_dbengine_disk_space: 256
```

### Plugin Configuration

```yaml
netdata_plugins:
  apps: true
  cgroups: true
  charts.d: true
  checks: true
  diskspace: true
  ebpf: false
  fping: true
  go.d: true
  idlejitter: true
  proc: true
  python.d: true
  tc: true
```

### Advanced Settings

```yaml
# Machine Learning
netdata_ml_enabled: true

# Alarms
netdata_alarms_enabled: true

# Process scheduling
netdata_process_scheduling_policy: "idle"
netdata_oom_score: 1000

# Logging
netdata_debug_log: "none"
netdata_error_log: "syslog"
netdata_access_log: "none"

# Web compression
netdata_web_gzip_enabled: true
netdata_web_gzip_level: 3
```

## Dependencies

- `netdata_install` role should be run first

## Example Playbook

### Basic Configuration

```yaml
- hosts: monitoring_servers
  roles:
    - role: netdata_configure
      vars:
        netdata_memory_mode: "dbengine"
        netdata_history: 7200
```

### Production Configuration

```yaml
- hosts: production
  roles:
    - role: netdata_configure
      vars:
        netdata_bind_to: "127.0.0.1"  # Local only
        netdata_memory_mode: "dbengine"
        netdata_dbengine_disk_space: 512
        netdata_history: 86400  # 24 hours
        netdata_ml_enabled: true
        netdata_plugins:
          apps: true
          proc: true
          cgroups: true
          ebpf: false  # Disable eBPF for performance
```

### Minimal Resource Configuration

```yaml
- hosts: edge_devices
  roles:
    - role: netdata_configure
      vars:
        netdata_memory_mode: "ram"
        netdata_history: 600  # 10 minutes only
        netdata_update_every: 5  # Less frequent updates
        netdata_plugins:
          apps: false
          ebpf: false
          python.d: false
```

## Files Generated

- `/etc/netdata/netdata.conf` - Main configuration file
- `/etc/netdata/health_alarm_notify.conf` - Alarm notification settings

## Handlers

- `restart netdata` - Restarts the Netdata service
- `reload netdata` - Reloads configuration without restart

## Tags

- `netdata` - All Netdata tasks
- `netdata-config` - Configuration tasks only
- `netdata-alarms` - Alarm configuration
- `netdata-plugins` - Plugin configuration

## Notes

- The role creates a backup of existing configuration files
- Plugin settings are applied by modifying the main configuration
- Database engine mode provides the best balance of features and resource usage
- For streaming setups, use the `netdata_streaming` role after this

## Troubleshooting

### High Memory Usage

Reduce history or switch to a lighter memory mode:

```yaml
netdata_memory_mode: "save"
netdata_history: 1800
```

### Missing Metrics

Ensure required plugins are enabled:

```yaml
netdata_plugins:
  go.d: true
  python.d: true
```

### Web Interface Not Accessible

Check bind address and firewall rules:

```yaml
netdata_bind_to: "0.0.0.0"  # Listen on all interfaces
netdata_port: 19999
```

## License

MIT

## Author Information

Andromeda Orchestration Infrastructure Team
