# Nomad Dynamic Volumes

### Prerequisites

- Linux host with loop device support
- mkfs.ext4 available
- systemd present and enabled
- Root privileges for installation and mounting
- Nomad 1.6+ with dynamic host volume support

### Related Links

- Ansible installer: `playbooks/infrastructure/nomad/volumes/enable-dynamic-volumes.yml`
- Client config template: `roles/nomad/templates/client-dynamic-volume.hcl.example.j2`

## Plugin script

`/opt/nomad/plugins/ext4-volume`

Permissions: `chmod 0755 /opt/nomad/plugins/ext4-volume`

## systemd unit (boot remount)

`/etc/systemd/system/nomad-dynvol@.service`

Reload units: `systemctl daemon-reload`

## Nomad client config (enable dynamic host volume)

Use the example from the Nomad role:

`roles/nomad/templates/client-dynamic-volume.hcl.example.j2`

## Ansible quick installer (role-based)

Use the playbook:

`playbooks/infrastructure/nomad/volumes/enable-dynamic-volumes.yml`

With this repository's tooling, prefer using `uv run` (see `docs/getting-started/uv-ansible-notes.md`) or the Taskfile (`task setup`, then `uv run ansible-playbook ...`).

## Sanity Checks

```bash
# Create a test volume
/opt/nomad/plugins/ext4-volume create demo-alloc 1
/opt/nomad/plugins/ext4-volume path demo-alloc
# Reboot (or simulate) then:
systemctl start nomad-dynvol@demo-alloc
mountpoint /opt/nomad/volumes/dynamic/demo-alloc

# Clean it up
/opt/nomad/plugins/ext4-volume delete demo-alloc
```

### Validation Checklist

- Plugin exists and is executable: `test -x /opt/nomad/plugins/ext4-volume`
- Systemd unit file present: `/etc/systemd/system/nomad-dynvol@.service`
- Unit loads without error: `systemctl daemon-reload` and `systemctl status nomad-dynvol@demo-alloc`
- Create/remount/delete cycle works as shown in Sanity Checks
