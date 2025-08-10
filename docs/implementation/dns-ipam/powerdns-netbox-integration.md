# PowerDNS-NetBox Integration Guide

**Status**: DNS Zones Deployed (2025-08-08)
**Phase**: 4 - DNS Integration
**Next Step**: Configure PowerDNS backend integration

## Overview

This guide documents the integration between NetBox DNS plugin and PowerDNS, establishing NetBox as the authoritative source of truth for DNS records.

## Architecture

```text
┌─────────────────────────┐
│   NetBox (LXC 213)      │
│   192.168.30.213        │
│ ┌─────────────────────┐ │
│ │  DNS Plugin v1.3.5  │ │
│ │  - Zones            │ │
│ │  - Records          │ │
│ │  - PTR Generation   │ │
│ └──────────┬──────────┘ │
└────────────┼────────────┘
             │ API
             ↓
    ┌────────────────┐
    │  NetBox API    │
    │  Backend       │
    └────────┬───────┘
             │
```

## Implementation Steps

### 1. DNS Zone Configuration

Zones created in NetBox:

**Forward Zones:**

- `homelab.local` - Primary homelab domain
- `doggos.local` - Doggos cluster domain
- `og.local` - OG homelab cluster domain

**Reverse Zones:**

- `10.168.192.in-addr.arpa` - 192.168.10.0/24
- `11.168.192.in-addr.arpa` - 192.168.11.0/24
- `30.168.192.in-addr.arpa` - 192.168.30.0/24

### 2. Synchronization Script

The `netbox-powerdns-sync.py` script provides:

- Full zone synchronization
- Record management (A, AAAA, CNAME, PTR, etc.)
- Dry-run mode for testing
- Automatic PTR generation

### 3. PowerDNS Configuration

PowerDNS configured with:

- MySQL backend for zone storage
- API enabled on port 8081
- DNS service on port 53
- Integration with NetBox API

## Playbook Usage

### Initial Setup

```bash
# 1. Create DNS zones in NetBox
uv run ansible-playbook playbooks/infrastructure/powerdns/netbox-dns-zones-setup.yml \
  -i inventory/localhost.yml

# 2. Populate DNS records
uv run ansible-playbook playbooks/infrastructure/powerdns/netbox-dns-populate-records.yml \
  -i inventory/localhost.yml

# 3. Configure PowerDNS integration
uv run ansible-playbook playbooks/infrastructure/powerdns/powerdns-netbox-integration.yml \
  -i inventory/localhost.yml

# 4. Test DNS resolution
uv run ansible-playbook playbooks/infrastructure/powerdns/test-dns-resolution.yml \
  -i inventory/localhost.yml
```

### Manual Sync

```bash
# Dry run
python3 scripts/netbox-powerdns-sync.py \
  --netbox-url https://192.168.30.213 \
  --netbox-token $NETBOX_TOKEN \
  --powerdns-url http://192.168.11.20:8081 \
  --powerdns-api-key $PDNS_API_KEY \
  --no-verify-ssl \
  --dry-run

# Actual sync
python3 scripts/netbox-powerdns-sync.py \
  --netbox-url https://192.168.30.213 \
  --netbox-token $NETBOX_TOKEN \
  --powerdns-url http://192.168.11.20:8081 \
  --powerdns-api-key $PDNS_API_KEY \
  --no-verify-ssl
```

## Testing

### DNS Resolution Tests

```bash
# Forward lookup
dig @192.168.11.20 lloyd.homelab.local

# Reverse lookup
dig @192.168.11.20 -x 192.168.11.11

# Zone transfer
dig @192.168.11.20 homelab.local AXFR

# Service discovery
dig @192.168.11.20 netbox.homelab.local
dig @192.168.11.20 powerdns.homelab.local
```

### Expected Results

- All infrastructure hosts resolvable by name
- PTR records return correct hostnames
- Service aliases (CNAME) resolve correctly
- Zone transfers show all records

## Automation

### Cron-based Sync

Add to crontab for automatic synchronization:

```bash
# Sync every 5 minutes
*/5 * * * * /path/to/netbox-powerdns-sync.sh >> /var/log/dns-sync.log 2>&1
```
