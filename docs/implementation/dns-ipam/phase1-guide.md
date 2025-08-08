# Phase 1: Cement Your Consul Foundation - Implementation Guide

This guide walks through implementing Phase 1 of the DNS & IPAM overhaul, establishing Consul as the service discovery backbone.

## Prerequisites

Before starting Phase 1, ensure:

1. ✅ **Consul-Nomad Integration Working** (Completed 2025-07-30)
   - All Nomad services registered in Consul
   - ACL tokens properly configured
2. ✅ **Infrastructure Roles Imported** (Completed 2025-07-30)
   - consul, nomad, system_base, nfs roles available
   - Custom modules for Consul/Nomad management
3. ✅ **Firewall Rules Configured**
   - Port 8600/udp already open (via system_base role)

## Phase 1 Objectives

1. **Enable Consul DNS** on all nodes
2. **Configure DNS resolution** for `.consul` domain
3. **Register existing infrastructure** services in Consul
4. **Validate service discovery** is working

## Implementation Steps

### Step 1: Review Current Configuration

Check the current DNS setup on your nodes:

```bash
# Check current DNS configuration
uv run ansible all -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m command -a "cat /etc/resolv.conf"

# Check if systemd-resolved is active
uv run ansible all -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m command -a "systemctl is-active systemd-resolved"
```

### Step 2: Deploy Consul DNS Configuration

Run the Phase 1 playbook to configure DNS resolution:

```bash
# Using the role-based approach (recommended)
uv run ansible-playbook playbooks/infrastructure/phase1-consul-dns.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# Or use the detailed playbook with more control
uv run ansible-playbook playbooks/infrastructure/phase1-consul-foundation.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Step 3: Verify DNS Resolution

After deployment, verify Consul DNS is working:

```bash
# Test Consul service discovery
uv run ansible all -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m command -a "dig @127.0.0.1 -p 8600 consul.service.consul +short"

# Test with system resolver (if systemd-resolved is configured)
uv run ansible all -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m command -a "dig consul.service.consul +short"

# Check registered services
uv run ansible nomad-server-1-lloyd -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m shell -a "consul catalog services -token {{ consul_acl_token }}"
```

### Step 4: Validate Infrastructure Services

Verify that infrastructure services are registered:

```bash
# Check Pi-hole services
uv run ansible nomad-server-1-lloyd -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m command -a "dig @127.0.0.1 -p 8600 pihole.service.consul +short"

# Check Pi-hole VIP
uv run ansible nomad-server-1-lloyd -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m command -a "dig @127.0.0.1 -p 8600 pihole-vip.service.consul +short"
```

## What Gets Configured

### 1. DNS Resolution (per node)

The `consul_dns` role configures:

- **systemd-resolved**: Forwards `.consul` queries to Consul DNS on port 8600
- **Fallback**: Maintains existing DNS servers for non-Consul queries
- **Cache**: Enables DNS caching for performance

Configuration file: `/etc/systemd/resolved.conf.d/consul.conf`

### 2. Service Registration (on first Consul server)

[TODO]: Unsure why we're registering these services. They are running in og-homelab

The following services are registered:

- **pihole**: 3 instances (LXC containers)
  - pihole-lxc-103: 192.168.30.103
  - pihole-lxc-136: 192.168.30.136
  - pihole-lxc-139: 192.168.30.139
- **pihole-vip**: Keepalived virtual IP
  - Address: 192.168.30.100

### 3. Health Checks

Each service includes TCP health checks on port 53 with 10-second intervals.

## Customization Options

### Using Different DNS Methods

The `consul_dns` role supports multiple DNS backends:

```yaml
# In your playbook or inventory
consul_dns_method: systemd-resolved # Default
# consul_dns_method: dnsmasq        # Alternative
# consul_dns_method: resolv         # Direct /etc/resolv.conf
```

### Registering Additional Services

Add services to the `consul_infrastructure_services` variable:

```yaml
consul_infrastructure_services:
  - name: my-service
    instances:
      - id: my-service-1
        address: 192.168.30.200
        tags: ["web", "production"]
    port: 80
    check_type: http
    check_interval: 30s
```

### Skipping Service Registration

If you only want DNS configuration without service registration:

```yaml
consul_register_services: false
```

## Troubleshooting

### DNS Resolution Not Working

1. Check systemd-resolved status:

   ```bash
   systemctl status systemd-resolved
   journalctl -u systemd-resolved -f
   ```

2. Verify Consul DNS is responding:

   ```bash
   dig @127.0.0.1 -p 8600 consul.service.consul
   ```

3. Check resolved configuration:
   ```bash
   resolvectl status
   resolvectl query consul.service.consul
   ```

### Services Not Registering

1. Verify Consul ACL token:

   ```bash
   consul catalog services -token <your-token>
   ```

2. Check service registration API:

   ```bash
   curl -H "X-Consul-Token: <token>" http://127.0.0.1:8500/v1/agent/services
   ```

3. Review Consul logs:
   ```bash
   journalctl -u consul -f
   ```

### Validation Playbook

Run the validation tasks separately:

```bash
uv run ansible-playbook playbooks/infrastructure/phase1-consul-dns.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  --tags validate
```

## Next Steps

After Phase 1 is complete:

1. **Monitor Service Health**: Check Consul UI or use `consul catalog services`
2. **Test Applications**: Update applications to use `.service.consul` domains
3. **Prepare for Phase 2**: Review PowerDNS requirements and Nomad job specs

## Phase 1 Checklist

[TODO]: Wrong, pihole does not run in consul.

- [ ] DNS resolution configured on all nodes
- [ ] `.consul` domain queries forwarded to Consul
- [ ] Pi-hole services registered in Consul
- [ ] Service discovery validated with dig
- [ ] Health checks passing for all services
- [ ] Documentation updated with any custom configurations

## Additional Resources

- [Consul DNS Interface](https://www.consul.io/docs/discovery/dns)
- [systemd-resolved Configuration](https://www.freedesktop.org/software/systemd/man/resolved.conf.html)
- [Consul Service Registration](https://www.consul.io/api-docs/agent/service)
