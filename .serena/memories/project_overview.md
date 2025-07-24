# NetBox Ansible Automation Project Overview

## Purpose
This is a NetBox-focused Ansible automation project designed to manage network infrastructure with NetBox as the source of truth. The project is currently implementing a comprehensive DNS & IPAM overhaul to transition from ad-hoc DNS management to a service-aware infrastructure using Consul, PowerDNS, and NetBox.

## Tech Stack
- **Ansible** 2.15+ with ansible-core
- **Python** 3.9+
- **1Password** (CLI and Connect) for secrets management
- **Proxmox** for virtualization (dynamic inventory)
- **Consul** for service discovery (deployed, pending assessment)
- **Nomad** for orchestration (operational on doggos-homelab)
- **NetBox** for IPAM (planned)
- **PowerDNS** for DNS (planned)
- **Docker** for containerized execution environments
- **uv** for Python dependency management

## Infrastructure
- **og-homelab**: Original Proxmox cluster (details pending assessment)
- **doggos-homelab**: 3-node Proxmox cluster (lloyd, holly, mable) running:
  - 3 Nomad servers (one per node)
  - 3 Nomad clients (one per node)
  - Tagged with: nomad, staging, terraform, server/client roles

## Key Features
- Dynamic inventory from Proxmox (currently) and NetBox (planned)
- Secure credential management via 1Password Connect
- Containerized Ansible execution environments
- Service-aware DNS infrastructure (in progress)
- Comprehensive testing and linting setup