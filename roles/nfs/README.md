# NFS Role

This role is used to configure NFS (Network File System) on the target hosts.

## Variables

### `nfs_exports`

- **Purpose**: List of directories to export via NFS.
- **Default Value**: `[]` (empty list)
- **Example**:
  ```yaml
  nfs_exports:
    - path: /srv/nfs
      clients: 192.168.1.0/24(rw,sync,no_root_squash)
  ```

## Usage

Include this role in your playbook and define the required variables:

```yaml
- hosts: all
  roles:
    - role: nfs
      vars:
        nfs_exports:
          - path: /srv/nfs
            clients: 192.168.1.0/24(rw,sync,no_root_squash)
```

---

## Additional Variables

### `nfs_client_shares`

- **Purpose**: List of NFS shares to mount as a client.
- **Default Value**:
  ```yaml
  nfs_client_shares:
    - server_ip: "192.168.30.6"
      share_path: "/mnt/DataLake/nomad-volumes"
      mount_point: "/mnt/nomad-volumes"
      mount_options: "rw,sync,hard,intr"
      service_folders: [coder, grafana, prometheus, fabio]
      directory_owner: "nobody"
      directory_group: "nogroup"
      directory_mode: "0755"
  ```
- **Description**: Defines remote NFS shares, mount options, and directory ownership for each service folder.

---

## Handlers

- **Remount NFS shares**: Ensures all NFS shares are remounted after configuration changes using `mount -a`.

---

## Idempotency, DRYness, and Best Practices

- All tasks are idempotent and safe to re-run.
- Variables are defined in `defaults/main.yml` for easy override.
- Handlers are used for remounting after changes.
- Role is modular and can be used for both NFS server and client scenarios.
- Follows Ansible best practices for variable naming, handler usage, and documentation.

---

## Integration Notes

- Ensure NFS server is reachable from all clients.
- Use inventory or group_vars to define `nfs_exports` and `nfs_client_shares` as needed.
- For advanced scenarios, customize mount options and directory permissions per service.

---

```

```
