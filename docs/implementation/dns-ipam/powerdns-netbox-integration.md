# PowerDNS-NetBox Integration Guide

**Status**: DNS Zones Deployed (2025-08-08)
**Phase**: 4 - DNS Integration
**Next Step**: Configure PowerDNS backend integration

## Overview

This guide documents the integration between NetBox DNS plugin and PowerDNS, establishing NetBox as the authoritative source of truth for DNS records.

## Architecture

```
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
             ↓
┌─────────────────────────┐
│  PowerDNS (Nomad)       │
│  192.168.11.20          │
│ ┌─────────────────────┐ │
│ │  MySQL Backend      │ │
│ │  API (port 8081)    │ │
│ │  DNS (port 53)      │ │
│ └─────────────────────┘ │
└─────────────────────────┘
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

### Webhook Integration (Future)

NetBox supports webhooks for real-time updates:
1. Configure webhook in NetBox for DNS record changes
2. Create webhook receiver endpoint
3. Trigger sync on record changes

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| API connection failed | Verify PowerDNS API key in Consul KV |
| Zones not syncing | Check zone exists in NetBox first |
| Records missing | Run sync script manually with --dry-run |
| PTR not working | Ensure reverse zone exists for subnet |

### Debug Commands

```bash
# Check PowerDNS API
curl -H "X-API-Key: $KEY" http://192.168.11.20:8081/api/v1/servers

# List zones in PowerDNS
curl -H "X-API-Key: $KEY" http://192.168.11.20:8081/api/v1/servers/localhost/zones

# Check NetBox DNS plugin
curl -H "Authorization: Token $TOKEN" https://192.168.30.213/api/plugins/netbox-dns/

# View sync logs
journalctl -u netbox-powerdns-sync -f
```

## Security

### API Keys

- **NetBox Token**: Stored in Infisical at `/apollo-13/services/netbox/NETBOX_API_KEY`
- **PowerDNS Key**: Stored in Consul KV at `powerdns/api/key`

### Network Security

- PowerDNS API restricted to management network
- NetBox uses HTTPS (self-signed cert)
- Consider implementing API rate limiting

## Next Steps

1. **High Availability**
   - Deploy secondary PowerDNS instance
   - Configure zone transfers
   - Load balance DNS queries

2. **Enhanced Features**
   - Enable DNSSEC signing
   - Implement split-horizon DNS
   - Add GeoDNS capabilities

3. **Monitoring**
   - Add Prometheus metrics
   - Create Grafana dashboards
   - Set up alerting for sync failures

4. **Backup & Recovery**
   - Automated zone exports
   - Point-in-time recovery
   - Disaster recovery procedures

## Related Documentation

- [Phase 4: DNS Integration](../../project-management/phases/phase-4-dns-integration.md)
- [NetBox Integration Patterns](./netbox-integration-patterns.md)
- [PowerDNS Deployment](../../../nomad-jobs/platform-services/powerdns.nomad.hcl)
