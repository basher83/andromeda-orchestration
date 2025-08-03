# Platform Services

This directory contains Nomad job specifications for infrastructure services that provide functionality to the platform.

## Services

### PowerDNS

**Purpose**: Authoritative DNS server for the homelab infrastructure.

**Key Features**:
- Runs on standard DNS port 53 (static allocation required)
- API accessible via Traefik at https://powerdns.lab.local
- MySQL backend for zone storage
- Ready for NetBox integration (Phase 3)

**Access**:
- DNS queries: `<node-ip>:53`
- API: https://powerdns.lab.local (via Traefik)
- No longer uses static port 8081

**Deployment**:
```bash
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/platform-services/powerdns.nomad.hcl
```

## Planned Services

### NetBox (Phase 3)
- IPAM and DCIM
- Source of truth for infrastructure
- PowerDNS integration for automatic DNS updates

### Monitoring Stack
- Prometheus for metrics collection
- Grafana for visualization
- AlertManager for notifications

### Logging Stack
- Loki for log aggregation
- Promtail for log shipping
- Integration with Grafana