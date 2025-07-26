# NetBox Ansible Automation Project Overview

## Purpose

This is a NetBox-focused Ansible automation project designed to manage network infrastructure with NetBox as the source of truth. The project is implementing a comprehensive DNS & IPAM overhaul to transition from ad-hoc DNS management to a service-aware infrastructure using Consul, PowerDNS, and NetBox.

## Tech Stack

- **Ansible** 2.15+ with ansible-core
- **Python** 3.9+
- **1Password** (CLI and Connect) for secrets management
- **Proxmox** for virtualization (dynamic inventory)
- **Consul** v1.21.2 for service discovery (deployed and healthy)
- **Nomad** v1.10.2 for orchestration (operational on doggos-homelab)
- **NetBox** for IPAM (planned - Phase 3)
- **PowerDNS** for DNS (ready to deploy - Phase 2)
- **Docker** 28.3.0 for containerized workloads
- **uv** for Python dependency management

## Infrastructure

- **og-homelab**: Original Proxmox cluster at 192.168.30.30:8006
  - Contains Pi-hole instances and various services
  - To be assessed for DNS/IPAM migration

- **doggos-homelab**: 3-node Proxmox cluster at 192.168.10.2:8006
  - Physical nodes: lloyd, holly, mable (4 CPU, 16GB RAM, 65GB disk each)
  - Consul cluster: 3 servers + 3 clients (ACLs enabled)
  - Nomad cluster: 3 servers + 3 clients (ACLs disabled)
  - Dual-network: Management (192.168.10.x), Internal (192.168.11.x)

## Project Structure

- `inventory/` - Dynamic inventory configurations for both clusters
- `playbooks/` - Ansible playbooks organized by function
  - `assessment/` - Infrastructure assessment playbooks
  - `consul/` - Consul service management
  - `nomad/` - Nomad job deployment and management
  - `examples/` - Example playbooks for common tasks
- `jobs/` - Nomad job specifications (PowerDNS ready)
- `docs/` - Project documentation
- `reports/` - Generated assessment reports
- `bin/` - Helper scripts (ansible-connect wrapper)
- `scripts/` - Utility scripts
- `.ansible/` - Local Ansible configuration

## Key Features

- Multi-cluster Proxmox management with fixed ansible_host resolution
- Dynamic inventory using community.proxmox plugin
- Secure credential management via 1Password (Consul ACL token stored)
- Containerized Ansible execution environments
- Production-grade linting (ansible-lint, yamllint, ruff)
- Comprehensive assessment framework
- HashiCorp tools integration (ansible-community.hashicorp-tools)

## Current Status

- ✅ Phase 0: Infrastructure assessment completed
- ✅ Consul cluster healthy with ACL token in 1Password
- ✅ Nomad cluster ready (no ACLs needed)
- ✅ Service registration framework built
- ✅ PowerDNS Nomad job specification created
- 🚀 Ready to deploy PowerDNS (Phase 2)
- 📋 Following 5-phase DNS/IPAM implementation plan

## Available Integrations

- **1Password**: Consul ACL token as "Consul ACL - doggos-homelab"
- **Consul**: Service discovery on port 8600, API on port 8500
- **Nomad**: Job deployment API on port 4646, no authentication required
- **Docker**: Available on all Nomad client nodes
