# Traefik External Access Issues

## Problem Description

Traefik dashboard and external endpoints are not accessible from outside the host, despite the container running correctly internally. This typically manifests as:

- ✅ Internal access works: `curl http://172.17.0.2:8080/ping` returns "OK"
- ❌ External access fails: `curl http://192.168.11.21:8080/ping` times out
- ✅ Other services on the host are accessible (e.g., Nomad UI on port 4646)

## Root Cause

The issue stems from conflicts between **nftables** and **iptables** firewall management systems. Specifically:

1. The `fix-docker-consul-dns.yml` playbook configures iptables rules to redirect Docker container DNS queries to Consul
2. When transitioning to nftables-only management, these critical iptables rules get flushed
3. Without DNS redirection rules, Docker containers lose proper DNS resolution
4. This breaks Docker's port mapping and external connectivity

## Symptoms Checklist

- [ ] Traefik container is running and healthy in Nomad
- [ ] Internal container access works via Docker IP
- [ ] External access via host IP times out
- [ ] Both nftables and iptables are active on the system
- [ ] Docker daemon is configured with Consul DNS settings

## Solution

### Step 1: Verify the Issue

Check if both firewall systems are active:
```bash
systemctl is-active nftables    # Should return: active
systemctl is-active iptables    # Should return: inactive (desired state)
```

Check for Docker DNS configuration:
```bash
cat /etc/docker/daemon.json
```
Should contain:
```json
{
  "dns": ["192.168.10.21"],
  "dns-search": ["service.consul", "node.consul"]
}
```

### Step 2: Disable iptables and Consolidate to nftables

Run the disable-iptables playbook:
```bash
uv run ansible-playbook playbooks/fix/disable-iptables.yml -i inventory/doggos-homelab/infisical.proxmox.yml
```

This will:
- ✅ Backup existing iptables rules
- ✅ Flush all iptables chains
- ✅ Disable iptables services
- ✅ Ensure nftables is the only active firewall

### Step 3: Update nftables with Docker Support

The nftables configuration template needs to include Docker-specific rules. Ensure `roles/system_base/templates/nftables.conf.j2` contains:

```nft
table inet filter {
    chain forward {
        type filter hook forward priority 0; policy drop;

        # Allow Docker bridge forwarding
        iifname "docker0" accept
        oifname "docker0" ct state established,related accept
        oifname "docker0" accept
    }
}

# NAT table for Docker DNS redirection to Consul
table ip nat {
    chain prerouting {
        type nat hook prerouting priority -100; policy accept;

        # Redirect Docker container DNS queries to Consul
        ip saddr 172.17.0.0/16 udp dport 53 dnat to {{ ansible_default_ipv4.address }}:8600
        ip saddr 172.17.0.0/16 tcp dport 53 dnat to {{ ansible_default_ipv4.address }}:8600
    }

    chain postrouting {
        type nat hook postrouting priority 100; policy accept;
    }
}
```

### Step 4: Apply Updated nftables Configuration

```bash
uv run ansible-playbook playbooks/infrastructure/network/update-nftables-traefik.yml -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Step 5: Restart Docker

After firewall changes, restart Docker to clear old iptables rules:
```bash
ansible nomad-client-2-holly -i inventory/doggos-homelab/infisical.proxmox.yml -m systemd -a "name=docker state=restarted" --become
```

### Step 6: Verify Fix

Test external access:
```bash
curl -f http://192.168.11.21:8080/ping          # Should return: OK
curl -f http://192.168.11.21:8080/dashboard/    # Should return: HTML content
```

## Prevention

To avoid this issue in the future:

1. **Use only nftables**: Don't mix iptables and nftables on the same system
2. **Include Docker rules**: Ensure nftables configuration includes Docker forwarding and DNS redirection
3. **Test after changes**: Always verify external access after firewall modifications

## Related Files

- `playbooks/fix/disable-iptables.yml` - Migrates from iptables to nftables-only
- `playbooks/infrastructure/network/update-nftables-traefik.yml` - Updates nftables rules
- `playbooks/infrastructure/consul-nomad/configure-docker-consul-dns.yml` - Modern Docker DNS configuration (nftables compatible)
- `playbooks/.archive/fix-docker-consul-dns-iptables.yml` - Archived iptables-based Docker DNS fix
- `roles/system_base/templates/nftables.conf.j2` - nftables configuration template

## Technical Details

The core issue is that Docker's port mapping relies on proper DNS resolution and network forwarding. The original DNS fix used iptables NAT rules to redirect container DNS queries:

```bash
# Original iptables rules (now converted to nftables)
iptables -t nat -A PREROUTING -s 172.17.0.0/16 -p udp --dport 53 -j DNAT --to-destination 192.168.11.21:8600
iptables -t nat -A PREROUTING -s 172.17.0.0/16 -p tcp --dport 53 -j DNAT --to-destination 192.168.11.21:8600
```

When these rules were removed, Docker containers lost the ability to resolve Consul service names, breaking the entire networking stack.

## Status

- **Issue**: Resolved ✅
- **Root Cause**: iptables/nftables conflict ✅
- **Solution**: Consolidated to nftables with Docker support ✅
- **Prevention**: Documented and template updated ✅
