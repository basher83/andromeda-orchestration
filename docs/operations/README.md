# Operations Documentation

This directory contains operational guides for managing and troubleshooting deployed infrastructure components.

## Documents

### 📊 [netdata-architecture.md](netdata-architecture.md)
Comprehensive Netdata monitoring architecture:
- Parent-child streaming topology
- Multi-cluster configuration
- Data retention policies
- Performance optimization

### 🔧 [netdata-streaming-troubleshooting.md](netdata-streaming-troubleshooting.md)
Troubleshooting guide for Netdata streaming issues:
- Common streaming problems
- Diagnostic procedures
- Configuration validation
- Performance tuning

### 🎯 [pihole-ha-cluster.md](pihole-ha-cluster.md)
Pi-hole high availability cluster documentation:
- Current HA configuration
- Gravity sync setup
- Failover procedures
- Migration planning (Phase 4)

## Purpose

These documents provide:
- **Operational Procedures** - How to manage running services
- **Troubleshooting Guides** - How to diagnose and fix issues
- **Architecture References** - Understanding deployed systems
- **Performance Tuning** - Optimizing service operation

## Service Coverage

### Currently Documented
- ✅ Netdata monitoring system
- ✅ Pi-hole DNS (current state)
- 🚧 PowerDNS operations (coming soon)
- 🚧 Consul operations (coming soon)

### Planned Documentation
- NetBox operational procedures
- Nomad cluster management
- Backup and recovery procedures
- Disaster recovery plans

## Common Operations

### Monitoring
- Check Netdata parent-child connections
- Validate streaming configuration
- Review retention policies

### DNS Services
- Pi-hole cluster health checks
- Gravity sync validation
- DNS resolution testing

### Troubleshooting Process
1. Check service health
2. Review logs and metrics
3. Validate configuration
4. Test connectivity
5. Apply fixes
6. Verify resolution

## Related Resources

- **Monitoring Playbooks**: [`../../playbooks/infrastructure/monitoring/`](../../playbooks/infrastructure/monitoring/)
- **Netdata Role**: [`../../roles/netdata/`](../../roles/netdata/)
- **Assessment Reports**: [`../../reports/`](../../reports/)
- **Implementation Guides**: [`../implementation/`](../implementation/)

## Quick Reference

| Service | Status | Documentation |
|---------|--------|---------------|
| Netdata | ✅ Deployed | Complete |
| Pi-hole | ✅ Active | Current state documented |
| PowerDNS | 🚧 Deploying | In progress |
| Consul | ✅ Active | Planned |
| NetBox | ⏳ Planned | Future |