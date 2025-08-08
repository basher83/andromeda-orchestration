# Getting Started Documentation

This directory contains essential documentation for new users and developers working with the NetBox Ansible project.

## Contents

### Setup and Configuration
- **[repository-structure.md](repository-structure.md)** - Complete overview of the project directory structure and organization
- **[pre-commit-setup.md](pre-commit-setup.md)** - Configure pre-commit hooks for code quality and security scanning
- **[uv-ansible-notes.md](uv-ansible-notes.md)** - Important notes about using `uv` with Ansible in this project

### Help and Support
- **[troubleshooting.md](troubleshooting.md)** - Common issues and their solutions, including macOS permissions and Infisical setup

## Quick Start Path

1. **Understand the Structure** - Read `repository-structure.md` to understand project layout
2. **Set Up Development Environment** - Follow `pre-commit-setup.md` for development tools
3. **Configure uv** - Review `uv-ansible-notes.md` for Python environment management
4. **Troubleshoot Issues** - Check `troubleshooting.md` when you encounter problems

## Next Steps

After completing the getting started guides:
- Review implementation guides in [`../implementation/`](../implementation/)
- Check project status in [`../project-management/`](../project-management/)
- Explore playbooks in [`../../playbooks/`](../../playbooks/)

## Prerequisites

Before starting:
- Python 3.9+
- Ansible 2.15+
- Infisical account and machine identity
- Access to target infrastructure (Proxmox clusters)
