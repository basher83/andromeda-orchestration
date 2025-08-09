# Netdata Install Role

This role handles the installation of the Netdata monitoring agent.

## Features

- Multiple installation methods (repository, package, script)
- OS-specific repository configuration
- Idempotent installation
- Service management

## Requirements

- Ansible 2.9+
- Supported OS: Ubuntu, Debian, RHEL/CentOS, Rocky Linux

## Role Variables

```yaml
# Installation method
netdata_install_method: "repository"  # repository, package, or script
netdata_version: "stable"             # stable, edge, or nightly
netdata_repository_channel: "stable"  # stable or edge

# User and group
netdata_user: netdata
netdata_group: netdata

# Package name
netdata_package_name: netdata

# Script installation options
netdata_install_flags: "--dont-wait --disable-telemetry"
netdata_install_script_url: "https://my-netdata.io/kickstart.sh"
```

## Dependencies

None

## Example Playbook

```yaml
- hosts: all
  roles:
    - role: netdata_install
      vars:
        netdata_install_method: "repository"
        netdata_repository_channel: "stable"
```

## Installation Methods

### Repository (Recommended)

Uses the official Netdata package repository for your distribution.

### Package

Uses the distribution's default package manager without adding repositories.

### Script

Uses the official Netdata kickstart script for installation.

## License

MIT

## Author Information

Andromeda Orchestration Infrastructure Team
