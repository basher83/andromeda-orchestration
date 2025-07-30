# system_base Ansible Role

## Purpose

The `system_base` role provides a single, reusable source of truth for all system-level setup and hardening tasks. It is designed to be included as a dependency by other roles or playbooks, ensuring consistent configuration across your infrastructure.

**Features:**

- Chrony time synchronization
- nftables firewall configuration
- SSH hardening
- Docker installation and configuration
- Creation of standard directories
- Installation of common system packages

---

## Variable Interface

All variables can be overridden as needed in your playbooks or inventory.

| Variable                            | Default                                         | Description                                        |
| ----------------------------------- | ----------------------------------------------- | -------------------------------------------------- |
| `system_base_chrony_enabled`        | `true`                                          | Enable Chrony time synchronization                 |
| `system_base_nftables_enabled`      | `true`                                          | Enable nftables firewall configuration             |
| `system_base_ssh_hardening_enabled` | `true`                                          | Enable SSH hardening                               |
| `system_base_docker_enabled`        | `true`                                          | Enable Docker installation and configuration       |
| `system_base_directories`           | <ul><li>/opt/data</li><li>/srv/shared</li></ul> | List of directories to create on the system        |
| `system_base_packages`              | <ul><li>curl</li><li>vim</li><li>htop</li></ul> | List of additional system packages to install      |
| `system_base_chrony_config`         | `{}`                                            | Custom Chrony configuration options (dictionary)   |
| `system_base_nftables_config`       | `{}`                                            | Custom nftables configuration options (dictionary) |
| `system_base_ssh_hardening_options` | `{}`                                            | Custom SSH hardening options (dictionary)          |
| `system_base_docker_options`        | `{}`                                            | Custom Docker daemon options (dictionary)          |
| `system_base_docker_users`          | `[]`                                            | List of users to add to the Docker group           |

---

## Usage

### As a Dependency in Other Roles

Add `system_base` to the `dependencies` section of your role's `meta/main.yml`:

```yaml
dependencies:
  - role: system_base
```

### In a Playbook

```yaml
- hosts: all
  become: true
  roles:
    - role: system_base
      vars:
        system_base_chrony_enabled: true
        system_base_nftables_enabled: true
        system_base_ssh_hardening_enabled: true
        system_base_docker_enabled: true
        system_base_directories:
          - /opt/data
          - /srv/shared
        system_base_packages:
          - curl
          - vim
          - htop
        # Add custom config as needed
```

---

## Notes

- All system-level setup is now handled exclusively by `system_base`. Other roles (e.g., `core`, `bootstrap`, `docker`) depend on this role for baseline configuration.
- Override variables as needed for your environment.
- For advanced configuration, provide custom dictionaries to the relevant `*_config` or `*_options` variables.

---

## Handlers

- **restart chrony**: Restarts the Chrony time synchronization service.
- **reload chrony**: Reloads Chrony configuration (ignores errors).
- **restart nftables**: Restarts the nftables firewall.
- **reload nftables**: Reloads nftables configuration (ignores errors).
- **restart sshd**: Restarts the SSH daemon.
- **reload sshd**: Reloads SSH configuration (ignores errors).
- **restart docker**: Restarts the Docker service.
- **reload docker**: Reloads Docker configuration (ignores errors).

---

## Idempotency, DRYness, and Best Practices

- All tasks are idempotent and safe to re-run.
- Variables are defined in `defaults/main.yml` for easy override.
- Handlers are used for service restarts after configuration changes.
- Role is modular and reusable as a dependency for other roles.
- Follows Ansible best practices for variable naming, handler usage, and documentation.

---
