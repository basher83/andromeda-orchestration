# Network Infrastructure Playbooks

This directory contains playbooks for managing network configuration, including firewall rules, port management, and network policies.

## Playbooks

### update-nftables-netdata.yml

Updates nftables rules specifically for Netdata monitoring traffic.

**Purpose**: Opens required ports for Netdata parent-child streaming
**Target**: All hosts running Netdata

### update-nftables-nomad.yml

Configures firewall rules optimized for Nomad client nodes.

**Purpose**: Implements the dynamic port allocation strategy for Nomad workloads
**Target**: All Nomad client nodes (tag_client)

**Key Features**:

- Opens dynamic port range (20000-32000) for Nomad allocations
- Maintains static ports only for essential services (DNS)
- Prevents port conflicts by following best practices
- Includes verification tasks

## Firewall Strategy

Our firewall configuration follows these principles:

1. **Dynamic Ports by Default** - Services use Nomad's dynamic range (20000-32000)
2. **Minimal Static Ports** - Only DNS (53) and legacy services
3. **Load Balancer Pattern** - One service owns 80/443, all others use dynamic ports
4. **Default Deny** - Only explicitly allowed ports are open

## Usage

### Update Firewall Rules for Nomad Clients

```bash
# Update all Nomad clients
uv run ansible-playbook playbooks/infrastructure/network/update-nftables-nomad.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# Update specific node
uv run ansible-playbook playbooks/infrastructure/network/update-nftables-nomad.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  --limit nomad-client-1-lloyd

# Dry run to see changes
uv run ansible-playbook playbooks/infrastructure/network/update-nftables-nomad.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  --check --diff
```

### Verify Firewall Configuration

After running the playbook:

```bash
# Check current rules
nft list ruleset

# Test port connectivity
nc -zv <node-ip> 53    # DNS
nc -zv <node-ip> 24000 # Dynamic range

# Check Nomad allocations
nomad node status -verbose <node-id> | grep -A5 "Allocated Resources"
```

## Templates

### nftables-nomad-client.conf.j2

The main firewall template for Nomad clients includes:

- **Infrastructure Ports**: SSH, Consul, Nomad, Docker API
- **Dynamic Port Range**: 20000-32000 for Nomad allocations
- **Static Service Ports**: Minimal set (currently DNS and PowerDNS API)
- **Default Policy**: Drop all other traffic

## Port Allocation Reference

| Port Range | Purpose | Protocol |
|------------|---------|----------|
| 22 | SSH | TCP |
| 53 | DNS | TCP/UDP |
| 2375-2376 | Docker API | TCP |
| 4646-4648 | Nomad | TCP/UDP |
| 8300-8302, 8500, 8600 | Consul | TCP/UDP |
| 8081 | PowerDNS API | TCP |
| 19999 | Netdata | TCP |
| 20000-32000 | Nomad Dynamic Range | TCP/UDP |

## Best Practices

1. **Always Test First**: Use `--check` mode before applying changes
2. **Verify Services**: Ensure critical services remain accessible after updates
3. **Document Static Ports**: Any new static port must be justified and documented
4. **Monitor Logs**: Check `/var/log/syslog` for dropped packets if issues arise

## Troubleshooting

### Service Unreachable After Update

1. Verify the service port is in allowed range:

```bash
nomad alloc status <alloc-id> | grep "Allocated Ports"
```

2. Check if custom static port is needed:

```bash
# Add to template if justified
tcp dport <port> accept  # Service name
```

3. Restart nftables if manual changes made:

```bash
systemctl restart nftables
```

### Port Conflicts

1. Check what's using a port:

```bash
ss -tlnp | grep :<port>
```

2. Find Nomad job using static port:

```bash
nomad job status | xargs -I {} nomad job inspect {} | grep -B5 "static"
```

3. Convert to dynamic allocation (see best practices guide)

## Related Documentation

- [Firewall and Port Strategy](../../../docs/operations/firewall-port-strategy.md)
- [Nomad Port Allocation Best Practices](../../../docs/implementation/nomad-port-allocation.md)
- [Network Architecture Diagram](../../../docs/diagrams/network-port-architecture.md)

## Future Enhancements

- [ ] Template variables for port ranges
- [ ] Automatic static port documentation
- [ ] Integration with NetBox for port tracking
- [ ] Prometheus metrics for port usage
