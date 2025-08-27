# Operations Documentation

This directory contains operational guides, runbooks, and procedures for managing deployed services in the infrastructure.

## 📂 Directory Structure

### Core Operations Guides

- **[ansible-inventory.md](ansible-inventory.md)** - Ansible inventory structure, management, and best practices
- **[dns-deployment-status.md](dns-deployment-status.md)** - Current status and tracking of DNS infrastructure deployment
- **[firewall-port-strategy.md](firewall-port-strategy.md)** - Port allocation and firewall configuration strategies
- **[powerdns-deployment-final.md](powerdns-deployment-final.md)** - Final PowerDNS deployment procedures and validation
- **[pihole-ha-cluster.md](pihole-ha-cluster.md)** - Pi-hole high availability cluster configuration
- **[vault-access.md](vault-access.md)** - Vault access procedures and authentication methods
- **[security-scanning.md](security-scanning.md)** - Security scanning procedures and tools
- **[testing-strategy.md](testing-strategy.md)** - Testing approaches and validation procedures

### Monitoring & Observability

- **[netdata-architecture.md](netdata-architecture.md)** - Netdata monitoring architecture and deployment patterns
- **[netdata/](netdata/)** - Detailed Netdata configuration and integration documentation
  - [README.md](netdata/README.md) - Netdata overview and index
  - [Consul-Integration.md](netdata/Consul-Integration.md) - Integrating Netdata with Consul
  - [Daemon-Configuration-Reference.md](netdata/Daemon-Configuration-Reference.md) - Netdata daemon configuration
  - [current-settings/](netdata/current-settings/) - Current production configurations
  - [stock-referance/](netdata/stock-referance/) - Reference configurations

## 🚀 Quick Start

### For Incident Response

1. **Service Issues** → Check [troubleshooting/](../troubleshooting/) guides
2. **DNS Problems** → See [dns-deployment-status.md](dns-deployment-status.md)
3. **Monitoring Alerts** → Review [netdata-architecture.md](netdata-architecture.md)
4. **Security Events** → Follow [security-scanning.md](security-scanning.md)

### For Routine Operations

- **Manage Inventories** → [ansible-inventory.md](ansible-inventory.md)
- **Deploy PowerDNS** → [powerdns-deployment-final.md](powerdns-deployment-final.md)
- **Configure Monitoring** → [netdata/README.md](netdata/README.md)
- **Access Vault** → [vault-access.md](vault-access.md)
- **Update Firewall Rules** → [firewall-port-strategy.md](firewall-port-strategy.md)

## 📋 Operational Checklists

### Daily Operations

- [ ] Check service health in Consul
- [ ] Review Netdata dashboards for anomalies
- [ ] Verify DNS resolution (Pi-hole and PowerDNS)
- [ ] Check Vault seal status

### Weekly Operations

- [ ] Review security scan results
- [ ] Update documentation for any changes
- [ ] Check for pending system updates
- [ ] Review resource utilization trends

### Monthly Operations

- [ ] Rotate credentials where applicable
- [ ] Review and update firewall rules
- [ ] Audit access logs
- [ ] Update operational runbooks

## 🔧 Common Tasks

### Service Management

```bash
# Check service status via Consul
consul catalog services
consul health service <service-name>

# View Nomad job status
nomad job status
nomad alloc status <alloc-id>
```

### Monitoring

```bash
# Check Netdata status
systemctl status netdata

# View streaming configuration
cat /etc/netdata/stream.conf
```

### DNS Operations

```bash
# Test DNS resolution
dig @<dns-server> example.com

# Check PowerDNS API
curl -H "X-API-Key: <key>" http://powerdns:8081/api/v1/servers
```

## 📊 Service Status Matrix

| Service | Documentation | Monitoring | HA Setup | Status |
|---------|--------------|------------|----------|---------|
| PowerDNS | ✅ Complete | ✅ Netdata | 🚧 Planning | Deployed |
| Pi-hole | ✅ Complete | ✅ Netdata | ✅ 3-node | Production |
| Consul | ✅ Complete | ✅ Native | ✅ Cluster | Production |
| Nomad | ✅ Complete | ✅ Native | ✅ 3-node | Production |
| Vault | ✅ Complete | ✅ Native | ⚠️ Dev mode | Development |
| Netdata | ✅ Complete | Self | ✅ Parent-child | Production |

## 🔗 Related Documentation

### Infrastructure

- [Implementation Guides](../implementation/)
- [Troubleshooting](../troubleshooting/)
- [Standards](../standards/)

### Specific Services

- [Consul Operations](../implementation/consul/)
- [Nomad Operations](../implementation/nomad/)
- [PowerDNS Configuration](../implementation/powerdns/)
- [Vault Deployment](../implementation/vault/)

## 📝 Documentation Standards

When adding operational documentation:

1. **Include Prerequisites** - List required access, tools, and knowledge
2. **Provide Examples** - Show actual commands and expected output
3. **Document Rollback** - Always include how to undo changes
4. **Add Troubleshooting** - Common issues and their solutions
5. **Update Index** - Add new docs to this README

## 🚨 Emergency Procedures

For emergency procedures and incident response, see:

- [Troubleshooting Guide](../troubleshooting/README.md)
- [Service Identity Issues](../troubleshooting/service-identity-issues.md)
- [Consul KV Templating Issues](../troubleshooting/consul-kv-templating-issues.md)
- [Netdata Streaming Guide](../troubleshooting/netdata-streaming-guide.md)

## 📅 Maintenance Windows

Standard maintenance windows:

- **Development**: Anytime with notification
- **Staging**: Weekdays 10 PM - 2 AM
- **Production**: Weekends 2 AM - 6 AM

## 🤝 Contributing

When adding operational documentation:

1. Place in appropriate section
2. Update this README index
3. Include practical examples
4. Test all procedures
5. Add cross-references to related docs
