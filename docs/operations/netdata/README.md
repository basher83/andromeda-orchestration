# Netdata Reference Documentation

Configuration references and current settings for Netdata monitoring infrastructure.

## 📂 Directory Structure

### Reference Documentation

- **[Consul-Integration.md](Consul-Integration.md)** - Upstream documentation for Consul metrics collection
- **[Daemon-Configuration-Reference.md](Daemon-Configuration-Reference.md)** - Netdata daemon configuration reference

### Current Configuration

- **[current-settings/](current-settings/)** - Active configuration files from deployed systems
  - `consul/` - Consul telemetry integration settings
  - `proxmox/` - Proxmox monitoring configuration

### Stock Configuration

- **[stock-referance/](stock-referance/)** - Default Netdata configuration templates
  - `health_alarm_notify.conf` - Alert notification configuration
  - `stream.conf` - Parent-child streaming configuration

## 🔗 Related Documentation

### Architecture & Operations

- [Netdata Architecture](../netdata-architecture.md) - Complete monitoring architecture
- [Streaming Troubleshooting](../netdata-streaming-troubleshooting.md) - Diagnostic procedures

### Implementation

- [Monitoring Playbooks](../../../playbooks/infrastructure/monitoring/) - Deployment automation

## 📝 Notes

This directory contains:

1. **Reference material** from upstream Netdata documentation
2. **Current configurations** captured from running systems for reference
3. **Stock templates** for comparison and troubleshooting

These files are preserved for operational reference and should be updated when:

- Netdata configuration changes significantly
- New integrations are added
- Troubleshooting requires configuration comparison
