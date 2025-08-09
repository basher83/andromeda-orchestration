# PowerDNS

Nomad job templates that match your standards (static :53, everything else dynamic, Consul service discovery, Traefik for API, KV/Vault-driven config). Two deployment modes:

# Deployment Options

[Mode A](./mode-a/) (Simple / Production-friendly): pdns-auth serves :53 directly.

[Mode B](./mode-b/) (Full stack): dnsdist on :53 in front of pdns-auth and pdns-recursor (cleanest when you want both auth + recursion anywhere in the cluster). Why: clean split of concerns; dnsdist routes auth zones to pdns-auth and everything else to pdns-recursor. Lets you scale components independently and keep :53 consistent.

## Assumptions

Storage: PostgreSQL backend for PDNS Auth (already reachable from Nomad nodes).

Secrets:

Vault path kv/pdns: db_password, api_key

Consul KV pdns/db/\*: host, port, name, user

Networking:

Static: :53 (TCP/UDP)

Dynamic: APIs (Nomad alloc ports 20000–32000)

Service Discovery: Consul registration with health checks

Ingress: Traefik (Consul Catalog provider) picks up API via tags

## Mode A

[powerdns-testing.nomad.hcl](./mode-a/powerdns-testing.nomad.hcl)

## Mode B

[powerdns-testing.nomad.hcl](./mode-b/powerdns-testing.nomad.hcl)

## Consul KV / Vault bootstrap (quick sketch)

Consul KV

```bash
pdns/db/host = postgres.service.consul
pdns/db/port = 5432
pdns/db/name = powerdns
pdns/db/user = pdns
```

Vault (kv/pdns)

```json
{
  "db_password": "REDACTED",
  "api_key": "REDACTED"
}
```

Which mode should you pick?
Mode A if you only need authoritative DNS (primary/secondary), simplest HA, static :53, minimal moving parts.

Mode B if you want a unified :53 entry that can do both auth + recursion cluster-wide, with clean separation and scale knobs.
