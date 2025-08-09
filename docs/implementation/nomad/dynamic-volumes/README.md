# Nomad Dynamic Volumes

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
