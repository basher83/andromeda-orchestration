# Consul Implementation Documentation

This directory contains guides for implementing and configuring HashiCorp Consul in the infrastructure.

## Documents

### 🔐 [acl-integration.md](acl-integration.md)
Comprehensive guide for Consul ACL (Access Control List) configuration:
- ACL bootstrap process
- Policy creation and management
- Token generation and distribution
- Integration with Nomad and other services
- Security best practices

### 📊 [telemetry-setup.md](telemetry-setup.md)
Configure Consul telemetry and monitoring:
- Prometheus integration
- StatsD configuration
- Metrics endpoint setup
- Performance monitoring
- Alert configuration

## Related Resources

### Playbooks
- **Consul Configuration**: [`../../../playbooks/infrastructure/consul/`](../../../playbooks/infrastructure/consul/)
- **Consul-Nomad Integration**: [`../../../playbooks/infrastructure/consul-nomad/`](../../../playbooks/infrastructure/consul-nomad/)

### Assessment Reports
- **Consul Health**: [`../../../reports/consul/`](../../../reports/consul/)

### Roles
- **Consul Role**: [`../../../roles/consul/`](../../../roles/consul/)
- **Consul DNS Role**: [`../../../roles/consul_dns/`](../../../roles/consul_dns/)

## Implementation Status

- ✅ Basic Consul deployment
- 🚧 ACL configuration (Phase 1)
- ✅ Telemetry setup complete
- 🚧 DNS integration (Phase 1)
- ✅ Nomad integration configured

## Common Tasks

1. **Enable Consul DNS** - Part of Phase 1 implementation
2. **Configure ACLs** - Essential for production security
3. **Setup Monitoring** - Enable telemetry for observability
4. **Integrate with Nomad** - For service registration

## Troubleshooting

- Check [`../../operations/`](../../operations/) for operational guides
- Review assessment reports for current state
- Use debug playbooks in infrastructure directory