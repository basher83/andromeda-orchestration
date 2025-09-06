# PowerDNS Deployment - Final Status

**Date**: August 8, 2025
**Status**: ⚠️ Outdated Prototype (SQLite) — superseded by PostgreSQL + Vault deployment

## Summary

This document describes an early SQLite-based prototype. The current production path is Mode A with a PostgreSQL backend and Vault dynamic credentials.

For the current deployment, see:

- `nomad-jobs/platform-services/postgresql.nomad.hcl`
- `docs/implementation/powerdns/postgresql-vault-integration.md`
- `docs/implementation/powerdns/postgresql-vault-quickstart.md`

## Current Configuration

### Allocation Details

- **Allocation ID**: c19fb3f1-2a08-00ee-9317-84ce3ad2b8f3
- **Node**: nomad-client-2 (192.168.11.21)
- **Status**: Running and healthy
- **DNS Port**: 53 (static, accessible)
- **API Port**: 21421 (dynamic, mapped to container port 8081)

### Services Registered in Consul

- `powerdns-dns` - DNS service on port 53
- `powerdns-api` - API service with Traefik routing

## Key Learnings

### 1. MySQL Backend Challenges

- Docker container networking makes MySQL connectivity complex
- Authentication between containers requires careful configuration
- Environment variables alone don't override config files in PowerDNS image
- Command-line arguments are needed to override default settings

### 2. PowerDNS Configuration

- The official Docker image uses `/etc/powerdns/pdns.conf` with defaults
- Command-line arguments must be passed via `args` in Nomad job
- Don't specify `command` - the container has correct entrypoint
- API must be enabled with `--api=yes` and `--webserver=yes`

### 3. Why prototype used SQLite

- Simplified initial validation without external DB
- Allowed rapid iteration on API and port wiring
  > Replaced by PostgreSQL for persistence, security, and integration with Vault dynamic credentials

## Working Configuration

```hcl
job "powerdns" {
  datacenters = ["dc1"]
  type        = "service"

  group "powerdns" {
    count = 1

    network {
      port "dns" {
        static = 53
        to     = 53
      }
      port "api" {
        to = 8081
      }
    }

    task "powerdns" {
      driver = "docker"

      config {
        image = "powerdns/pdns-auth-48:latest"
        ports = ["dns", "api"]

        args = [
          "--daemon=no",
          "--guardian=no",
          "--launch=gsqlite3",
          "--gsqlite3-database=/var/lib/powerdns/pdns.sqlite3",
          "--webserver=yes",
          "--webserver-address=0.0.0.0",
          "--webserver-port=8081",
          "--webserver-allow-from=0.0.0.0/0",
          "--api=yes",
          "--api-key=changeme789xyz"
        ]
      }
    }
  }
}
```

## DNS Testing

DNS queries work correctly:

```bash
# Test DNS resolution
dig @192.168.11.21 -p 53 test.lab.spaceships.work

# The DNS server responds (though no zones configured yet)
```

## API Access

The API is running and accessible from within the container network:

- Internal: <http://localhost:8081/api/v1/servers>
- External: <http://192.168.11.21:21421/api/v1/servers> (may require firewall rules)

### API Key

- Current: `changeme789xyz`
- Should be moved to Vault/Infisical in production

## Next Steps for Full Integration

1. **Configure firewall rules** to allow dynamic port range (20000-32000)
2. **Use Traefik** for API access via `powerdns.lab.spaceships.work`
3. **Sync zones from NetBox** using the sync playbook
4. **Configure PowerDNS** to use NetBox as remote backend (optional)
5. **Add persistent storage** for SQLite database

## Files Created/Modified

### New Files

- `/nomad-jobs/platform-services/powerdns-sqlite.nomad.hcl` - Working SQLite configuration
- `/nomad-jobs/platform-services/powerdns.nomad.hcl` - MySQL attempt (for reference)
- `/docs/operations/powerdns-deployment-final.md` - This documentation

### Updated Files

- `/playbooks/infrastructure/netbox/dns/sync-to-powerdns.yml` - Updated with correct API endpoint
- `/CLAUDE.md` - Added critical insights about deployment

## Troubleshooting Commands

```bash
# Check job status
nomad job status powerdns

# Get allocation details
nomad alloc status <alloc-id>

# Check logs
nomad alloc logs -stderr <alloc-id> powerdns

# Get dynamic port
nomad alloc status -json <alloc-id> | jq '.AllocatedResources.Shared.Networks[0].DynamicPorts'

# Test DNS
dig @192.168.11.21 -p 53 test.lab.spaceships.work

# Test API (from inside network)
curl -H "X-API-Key: changeme789xyz" http://192.168.11.21:21421/api/v1/servers
```

## Conclusion

This SQLite deployment is archived as historical reference. The active implementation uses PostgreSQL with Vault dynamic credentials (Mode A). Refer to the integration docs for current procedures and troubleshooting.
