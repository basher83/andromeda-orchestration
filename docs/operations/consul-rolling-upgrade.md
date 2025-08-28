# Consul Rolling Upgrade Guide

## Overview

The `consul-rolling-upgrade.yml` playbook provides a production-ready, safe method for upgrading Consul clusters with zero downtime. It follows best practices from the ansible-collections/ansible-consul project and HashiCorp's official upgrade guidelines.

## Features

### Safety Features

- **Automatic leader detection** - Identifies and upgrades the leader last to minimize disruption
- **Version comparison** - Skips nodes already at target version to prevent unnecessary restarts
- **Health checks** - Validates cluster health before, during, and after upgrades
- **Graceful leave** - Uses `consul leave` before stopping service for clean handoff
- **Binary backup** - Creates timestamped backups before replacing binaries
- **Automatic rollback** - Restores previous binary on failure
- **Check mode support** - Test upgrade plan without making changes

### Implementation Details

- **Serial execution** - Processes one server at a time
- **Leader-last ordering** - Automatically sorts hosts to upgrade leader last
- **Dynamic configuration** - No hardcoded IPs, discovers from inventory
- **Infisical integration** - Secure credential management
- **Comprehensive validation** - Pre-flight, per-node, and post-upgrade checks

## Prerequisites

1. **Infisical Authentication**

   ```bash
   export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID="your-client-id"
   export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET="your-client-secret"
   ```

2. **Healthy Cluster**
   - All servers must be online and healthy
   - Minimum 3 servers for safe upgrade
   - Cluster must have a stable leader

3. **Version Compatibility**
   - Check [Consul upgrade docs](https://www.consul.io/docs/upgrading.html) for version compatibility
   - Generally safe to upgrade patch versions (1.21.3 → 1.21.4)
   - Minor version upgrades may require additional planning

## Usage

### Test Upgrade Plan (Check Mode)

```bash
# See what would happen without making changes
ansible-playbook consul-rolling-upgrade.yml \
  -i inventory/environments/doggos-homelab/proxmox.yml \
  -e consul_version=1.21.5 \
  --check
```

### Perform Upgrade

```bash
# Upgrade to specific version
ansible-playbook consul-rolling-upgrade.yml \
  -i inventory/environments/doggos-homelab/proxmox.yml \
  -e consul_version=1.21.5
```

### Force Upgrade

```bash
# Force upgrade even if version matches (useful for reinstalling)
ansible-playbook consul-rolling-upgrade.yml \
  -i inventory/environments/doggos-homelab/proxmox.yml \
  -e consul_version=1.21.4 \
  -e consul_force_upgrade=true
```

## Upgrade Process

### Phase 1: Pre-flight Checks

1. Validates target version format
2. Retrieves ACL tokens from Infisical
3. Checks current version on all nodes
4. Verifies cluster health
5. Identifies current leader
6. Creates upgrade order (followers first, leader last)

### Phase 2: Rolling Upgrade

For each server (followers first, leader last):

1. Skip if already at target version (unless forced)
2. Download and verify new binary
3. Perform graceful leave (`consul leave`)
4. Stop Consul service
5. Backup existing binary
6. Install new binary
7. Reload systemd daemon
8. Start Consul service
9. Wait for node to rejoin cluster
10. Verify version and health
11. Pause for cluster stabilization

### Phase 3: Post-Upgrade Validation

1. Verify cluster health
2. Confirm all servers are voters
3. Check new leader election
4. Display upgrade summary

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `consul_version` | Target Consul version | Required |
| `consul_force_upgrade` | Force upgrade even if version matches | `false` |
| `consul_binary_path` | Path to Consul binary | `/usr/bin/consul` |
| `minimum_servers` | Minimum servers for safe upgrade | `3` |

## Rollback

If an upgrade fails on any node:

1. The playbook automatically stops (no cascade failures)
2. Failed node's binary is restored from backup
3. Service is restarted with original binary
4. Clear error message indicates which node failed

### Manual Rollback

If needed, backups are stored at:

```bash
/usr/bin/consul.backup.<timestamp>
```

To manually rollback:

```bash
sudo systemctl stop consul
sudo cp /usr/bin/consul.backup.<timestamp> /usr/bin/consul
sudo systemctl start consul
```

## Monitoring

### During Upgrade

The playbook provides detailed output:

- Current vs target version comparison
- Upgrade order with leader identification
- Per-node progress updates
- Health check results

### Example Output

```text
Upgrade order:
1. nomad-server-1 (192.168.11.11)
2. nomad-server-3 (192.168.11.13)
3. nomad-server-2 (192.168.11.12) [LEADER - LAST]
```

### Post-Upgrade Verification

```bash
# Check all node versions
consul members -detailed

# Verify cluster health
consul operator autopilot health

# Check raft peers
consul operator raft list-peers
```

## Troubleshooting

### Common Issues

#### "Cluster is not healthy"

- Check `consul operator autopilot health`
- Ensure all nodes can communicate
- Verify ACL tokens are valid

#### "Insufficient servers for safe upgrade"

- Ensure all servers are online
- Check inventory file includes all servers
- Verify minimum 3 servers available

#### Version mismatch after upgrade

- Check if download was successful
- Verify checksum validation passed
- Ensure systemd reloaded properly

#### Node fails to rejoin cluster

- Check network connectivity
- Verify ACL tokens
- Review Consul logs: `journalctl -u consul -f`

### Recovery Steps

1. **If upgrade fails mid-process:**
   - Playbook will automatically rollback failed node
   - Fix the issue
   - Re-run playbook (it will skip already upgraded nodes)

2. **If cluster loses quorum:**
   - Stop trying to upgrade
   - Focus on restoring quorum first
   - Use `consul operator raft` commands if needed

3. **If leader election fails:**
   - Wait for automatic election (usually 10-30 seconds)
   - If stuck, restart one follower to trigger election

## Best Practices

1. **Always test in check mode first**

   ```bash
   ansible-playbook consul-rolling-upgrade.yml --check
   ```

2. **Upgrade during maintenance window**
   - While designed for zero downtime, plan for issues
   - Have rollback plan ready

3. **Monitor cluster during upgrade**

   ```bash
   watch consul members
   ```

4. **Backup configuration before major upgrades**

   ```bash
   consul snapshot save backup-$(date +%Y%m%d).snap
   ```

5. **Review release notes**
   - Check for breaking changes
   - Note new features or deprecations
   - Verify compatibility with your configuration

## Integration with CI/CD

The playbook can be integrated into CI/CD pipelines:

```yaml
# Example GitLab CI job
consul-upgrade:
  stage: deploy
  script:
    - export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=$CI_INFISICAL_CLIENT_ID
    - export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=$CI_INFISICAL_CLIENT_SECRET
    - ansible-playbook consul-rolling-upgrade.yml -e consul_version=$CONSUL_VERSION
  when: manual
  only:
    - main
```

## Related Documentation

- [Consul Upgrade Documentation](https://www.consul.io/docs/upgrading.html)
- [Consul Version Compatibility](https://www.consul.io/docs/upgrading/compatibility)
- [ansible-collections/ansible-consul](https://github.com/ansible-collections/ansible-consul)
- [Infisical Setup Guide](../implementation/infisical/infisical-complete-guide.md)
