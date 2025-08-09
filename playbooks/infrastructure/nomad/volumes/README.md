# Nomad Volume Management Playbooks

This directory contains playbooks for managing storage volumes in Nomad, supporting all four storage types: ephemeral, static host, dynamic host, and CSI volumes.

## Playbooks

### provision-host-volumes.yml

Provisions static host volumes on Nomad client nodes.

**Purpose**: Create persistent storage directories for services like databases and certificate storage.

**Usage**:
```bash
# Provision default volumes (PowerDNS, Traefik, Prometheus, etc.)
uv run ansible-playbook playbooks/infrastructure/nomad/volumes/provision-host-volumes.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# Provision a specific volume
uv run ansible-playbook playbooks/infrastructure/nomad/volumes/provision-host-volumes.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e volume_name=myapp-data \
  -e volume_owner=1000 \
  -e volume_group=1000 \
  -e volume_mode=0755
```

**Default Volumes Created**:
- `powerdns-mysql` - MySQL data for PowerDNS
- `traefik-certs` - SSL certificates
- `prometheus-data` - Metrics storage
- `grafana-data` - Dashboard storage
- `postgres-data` - PostgreSQL databases
- `mysql-backup` - Database backups

### enable-dynamic-volumes.yml

Configures Nomad clients to support dynamic volume provisioning.

**Purpose**: Enable on-demand volume creation for per-allocation storage needs.

**Usage (uv)**:
```sh
uv run ansible-playbook -i inventory/localhost.yml \
  playbooks/infrastructure/nomad/volumes/enable-dynamic-volumes.yml --check
```

Remove `--check` to apply.

**What it does now** (role-based):
- Ensures base directories: `/opt/nomad/volumes/dynamic/.registry` and `/opt/nomad/plugins`
- Installs the ext4 dynamic volume plugin to `/opt/nomad/plugins/ext4-volume`
- Installs `nomad-dynvol@.service` and reloads systemd
- Delegates the work to the Nomad role task `roles/nomad/tasks/dynamic-volumes.yml`

Note: Legacy inline XFS plugin/cleanup scripts were removed to avoid drift. If you need XFS, open an issue and we can add a compatible plugin.

### deploy-csi-driver.yml (Coming Soon)

Deploys CSI drivers for advanced storage features.

**Planned CSI Drivers**:
- NFS CSI - For shared file storage
- Democratic CSI - For iSCSI/NFS
- Ceph CSI - For distributed storage

## Storage Strategy

### Decision Flow

1. **Is the data temporary?** → Use Ephemeral Disk
2. **Does it need multi-node access?** → Use CSI Volume
3. **Does it need dynamic provisioning?** → Use Dynamic Host Volume
4. **Otherwise** → Use Static Host Volume

### Storage Types Comparison

| Type | Use Case | Persistence | Multi-Node | Dynamic |
|------|----------|-------------|------------|---------|
| Ephemeral | Cache, temp files | Until alloc stops | No | N/A |
| Static Host | Databases | Permanent | No | No |
| Dynamic Host | Per-alloc data | Permanent | No | Yes |
| CSI | Shared storage | Permanent | Yes | Yes |

## Volume Naming Conventions

### Static Volumes
Format: `{service}-{type}`
- `mysql-data`
- `redis-backup`
- `nginx-config`

### Dynamic Volumes
Format: `{service}-{type}-{alloc_id}`
- Allocation ID is automatically appended

### CSI Volumes
Format: `{service}-{type}-{environment}`
- `gitlab-data-production`
- `minio-objects-staging`

## Common Tasks

### Check Volume Status

```bash
# List all volumes on a node
ansible tag_client -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m shell -a "ls -la /opt/nomad/volumes/"

# Check disk usage
ansible tag_client -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m shell -a "df -h /opt/nomad/volumes/*"
```

### Backup Volumes

```bash
# Run backup for specific volume
ansible tag_client -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m shell -a "/opt/nomad/volumes/backup-volumes.sh mysql-data"
```

### Update Nomad Configuration

After provisioning volumes, update the Nomad client configuration. An example is provided by the Nomad role at `roles/nomad/templates/client-dynamic-volume.hcl.example.j2`.

```hcl
client {
  # Static host volume
  host_volume "mysql-data" {
    path      = "/opt/nomad/volumes/mysql-data"
    read_only = false
  }

  # Dynamic host volume
  host_volume "dynamic-data" {
    path    = "/opt/nomad/volumes/dynamic"
    dynamic = true
    plugin  = "ext4-volume"
  }
}
```

Then restart Nomad:
```bash
ansible tag_client -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m systemd -a "name=nomad state=restarted" -b
```

## Job Examples

### Using Static Host Volume

```hcl
job "mysql" {
  group "db" {
    volume "data" {
      type      = "host"
      source    = "mysql-data"
      read_only = false
    }

    task "mysql" {
      volume_mount {
        volume      = "data"
        destination = "/var/lib/mysql"
      }
    }
  }
}
```

### Using Dynamic Host Volume

```hcl
job "prometheus" {
  group "monitoring" {
    volume "data" {
      type   = "host"
      source = "dynamic-data"
    }

    task "prometheus" {
      volume_mount {
        volume      = "data"
        destination = "/prometheus"
        # Optional on Nomad 1.6+
        size        = "50GiB"
      }
    }
  }
}
```

## Troubleshooting

### Volume Mount Failed

```bash
# Check if volume exists
ls -la /opt/nomad/volumes/

# Check Nomad client config
nomad node status -self -verbose | grep host_volume

# Check allocation details
nomad alloc status <alloc-id>
```

### Permission Denied

```bash
# Fix ownership
ansible tag_client -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m file -a "path=/opt/nomad/volumes/mysql-data owner=999 group=999" -b
```

### Dynamic Volume Issues

```bash
# Check plugin logs
journalctl -u nomad | grep volume

# Test plugin manually
/opt/nomad/plugins/ext4-volume create test-vol 5
/opt/nomad/plugins/ext4-volume stats test-vol
/opt/nomad/plugins/ext4-volume delete test-vol
```

## Best Practices

1. **Always Set Correct Permissions**
   - Database volumes need specific UIDs
   - Use the service's container UID/GID

2. **Plan for Growth**
   - Size volumes appropriately
   - Monitor disk usage
   - Implement cleanup policies

3. **Backup Critical Data**
   - Use the provided backup script
   - Test restore procedures
   - Consider off-site backups

4. **Monitor Volume Health**
   - Set up disk usage alerts
   - Check I/O performance
   - Watch for mount issues

## Related Documentation

- [Nomad Storage Strategy](../../../../docs/implementation/nomad/storage-strategy.md)
- [Storage Implementation Patterns](../../../../docs/implementation/nomad/storage-patterns.md)
- [Dynamic Volumes Implementation](../../../../docs/implementation/nomad/dynamic-volumes/README.md)
