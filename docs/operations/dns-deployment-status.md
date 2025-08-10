# DNS Deployment Status Report
**Date**: August 8, 2025
**Phase**: 4 - DNS Integration

## Summary

Successfully deployed DNS zones to NetBox, but PowerDNS integration requires fixes.

## Completed Tasks ✅

### 1. NetBox DNS Plugin Setup
- Plugin v1.3.5 installed and operational
- API accessible at https://192.168.30.213
- Token stored in Infisical at `/apollo-13/services/netbox/NETBOX_API_KEY`

### 2. DNS Zones Created in NetBox
**Forward Zones:**
- `homelab.local` - Primary homelab domain
- `doggos.local` - Doggos cluster domain
- `og.local` - OG homelab cluster domain

**Reverse Zones:**
- `10.168.192.in-addr.arpa` - 192.168.10.0/24
- `11.168.192.in-addr.arpa` - 192.168.11.0/24
- `30.168.192.in-addr.arpa` - 192.168.30.0/24

**DNS Records:**
- Nameserver: `ns1.homelab.local` (192.168.11.20)
- NS records for all zones
- SOA records configured
- Total: 6 zones, 11 records

### 3. Playbook Organization
Reorganized into clean structure:
```
playbooks/infrastructure/netbox/
├── dns/
│   ├── discover-zones.yml      # Working ✅
│   ├── setup-zones.yml          # Working ✅
│   ├── populate-records.yml     # Ready
│   ├── sync-to-powerdns.yml     # Needs PowerDNS API
│   └── test-dns-resolution.yml  # Ready
└── netbox-populate-infrastructure.yml  # Working ✅
```

## Issues Found 🔧

### 1. PowerDNS Configuration Problems

- **Issue**: PowerDNS is using SQLite3 backend instead of MySQL
- **Cause**: Environment variables in Nomad job not being applied
- **Impact**: No persistent storage, zones lost on restart
- **Fix Needed**: Update Nomad job to properly configure MySQL backend

### 2. PowerDNS API Not Accessible

- **Issue**: API on port 8081 not responding to requests
- **Expected**: [http://192.168.11.21:26406/api/v1/](http://192.168.11.21:26406/api/v1/)
- **Impact**: Cannot sync zones from NetBox to PowerDNS
- **Fix Needed**: Verify API is enabled via command-line arguments

### 3. macOS mDNS Interference

- **Issue**: `.local` domains reserved for mDNS on macOS
- **Impact**: DNS queries from Mac don't reach PowerDNS
- **Workaround**: Use `.lab` TLD or test from Linux hosts

## Critical Insights 💡

### Infisical Integration

- **Always use** `uv run ansible-playbook` for proper Python environment
- Infisical Ansible collection has "worker dead state" issues
- **Workaround**: Use CLI to export tokens as environment variables

```bash
export NETBOX_TOKEN=$(infisical run --env=staging --path="/apollo-13/services/netbox" -- printenv NETBOX_API_KEY)
```

### PowerDNS Requirements

- API must be enabled via command-line args, not just environment variables
- MySQL backend requires proper PDNS_gmysql_* environment variables
- Persistent volume needed for database storage

## Next Steps 📋

1. **Fix PowerDNS Deployment**
   - Update Nomad job to use MySQL backend properly
   - Ensure API is enabled with correct arguments
   - Add persistent volume for PowerDNS data

2. **Complete Integration**
   - Once PowerDNS API works, sync zones from NetBox
   - Configure PowerDNS to query NetBox directly (remote backend)
   - Or implement periodic sync mechanism

3. **Testing**
   - Validate DNS resolution from Linux hosts
   - Test forward and reverse lookups
   - Verify zone transfers if needed

## Commands for Testing

```bash
# Check PowerDNS status
nomad job status powerdns
nomad alloc logs <alloc-id> powerdns

# Test DNS (from Linux host to avoid mDNS)
dig @192.168.11.21 -p 53 test.lab A
nslookup test.lab 192.168.11.21

# Check NetBox zones
uv run ansible-playbook playbooks/infrastructure/netbox/dns/discover-zones.yml

# Get PowerDNS API key from Consul
consul kv get powerdns/api/key
```

## Files Updated

- Added to `CLAUDE.md`: Critical insights about `uv run` and Infisical issues
- Created organized playbook structure under `netbox/dns/`
- Archived old test playbooks to `.archive/`
- Updated `docs/implementation/dns-ipam/powerdns-netbox-integration.md`

## Recommendations

1. **Priority**: Fix PowerDNS Nomad job first
2. **Alternative**: Consider using PowerDNS remote backend to query NetBox directly
3. **Testing**: Use Linux hosts for DNS testing to avoid mDNS issues
4. **Documentation**: Keep CLAUDE.md updated with operational insights
