# Tailscale Codespace Configuration

This guide covers using Tailscale from GitHub Codespaces or other remote development environments to access your homelab infrastructure.

## Critical Safety Information

⚠️ **NEVER run Ansible playbooks directly against Proxmox hypervisor hosts!**

The Proxmox hosts (`lloyd`, `holly`, `mable`) are critical infrastructure. Any misconfiguration or accident on these hosts could bring down your entire homelab. Always work with the VMs/containers running ON the hypervisors, not the hypervisors themselves.

## Understanding Tailscale Tags

Your infrastructure uses Tailscale tags to organize devices:

### Tag Structure

- `tag:homelab-doggos` - ALL devices in the doggos homelab (includes Proxmox hosts!)
- `tag:nomad-server` - Only Nomad server nodes
- `tag:nomad-client` - Only Nomad client nodes
- `tag:homelab-og` - Original homelab devices

### Safe vs Unsafe Scopes

**❌ UNSAFE - Do NOT use:**

```bash
# This includes Proxmox hosts - DANGEROUS!
--limit "tag_homelab_doggos"
```

**✅ SAFE - Use these:**

```bash
# Only Nomad servers
--limit "tag_nomad_server"

# Only Nomad clients
--limit "tag_nomad_client"

# Both Nomad servers and clients (but NOT Proxmox hosts)
--limit "tag_nomad_server,tag_nomad_client"
```

## SSH Configuration

### Correct SSH User

The SSH user for Ansible connections is `ansible`, not `root` or `codespace`:

✅ **CORRECT:**

```bash
uv run ansible-playbook playbook.yml -i inventory/tailscale/ansible_tailscale_inventory.py -u ansible
```

❌ **WRONG - Will fail with Tailscale policy errors:**

```bash
# DO NOT USE root
uv run ansible-playbook playbook.yml -i inventory/tailscale/ansible_tailscale_inventory.py -u root

# DO NOT USE default (codespace user)
uv run ansible-playbook playbook.yml -i inventory/tailscale/ansible_tailscale_inventory.py
```

## Using the Tailscale Dynamic Inventory

The project includes a dynamic inventory script at `inventory/tailscale/ansible_tailscale_inventory.py` that automatically discovers all Tailscale devices.

### List Available Hosts

```bash
# See all hosts and their tags
tailscale status

# View inventory structure
uv run ansible-inventory -i inventory/tailscale/ansible_tailscale_inventory.py --list

# Graph view of specific tags
uv run ansible-inventory -i inventory/tailscale/ansible_tailscale_inventory.py --graph tag_nomad_server
```

### Running Playbooks Safely

Always specify the correct scope using tags:

```bash
# Test connectivity to Nomad nodes only
uv run ansible all -i inventory/tailscale/ansible_tailscale_inventory.py \
  --limit "tag_nomad_server,tag_nomad_client" \
  -u ansible \
  -m ping

# Run assessment on Nomad cluster
uv run ansible-playbook playbooks/assessment/robust-connectivity-test.yml \
  -i inventory/tailscale/ansible_tailscale_inventory.py \
  --limit "tag_nomad_server,tag_nomad_client" \
  -u ansible
```

## Environment Configuration

When working remotely via Tailscale, ensure your mise environment is set correctly:

```bash
# Check current environment
mise run env:status

# Switch to remote/Tailscale environment if needed
mise run env:remote
eval "$(mise env)"
```

This ensures you're using Tailscale IPs (100.x.x.x) instead of local LAN IPs (192.168.x.x).

## Troubleshooting

### "Failed to look up local user" Error

This means you're using the wrong SSH user. Use `-u ansible` not the default Codespace user.

### "Tailnet policy does not permit" Error

You're trying to SSH as `root`. Tailscale policies restrict root access. Use `-u ansible`.

### Connection Timeouts to 192.168.x.x

You're trying to reach local LAN IPs from a remote environment. Use Tailscale IPs (100.x.x.x) or ensure you're using the Tailscale inventory.

### Accidentally Including Proxmox Hosts

If you see `lloyd`, `holly`, or `mable` in your playbook output, STOP! You're using the wrong tag filter. These are hypervisors and should not be managed directly.

## Quick Reference

| Task | Safe Command |
|------|-------------|
| Ping Nomad nodes | `ansible all -i inventory/tailscale/ansible_tailscale_inventory.py --limit "tag_nomad_server,tag_nomad_client" -u ansible -m ping` |
| List Nomad services | `consul members` |
| Check Nomad status | `nomad node status` |
| Deploy to Nomad | `nomad job run <job.hcl>` |

## Related Documentation

- [Mise Setup Guide](./mise-setup-guide.md) - Environment management
- [Repository Structure](./repository-structure.md) - Project organization
- [Troubleshooting](./troubleshooting.md) - Common issues
