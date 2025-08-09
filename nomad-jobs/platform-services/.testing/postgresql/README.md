# PostgreSQL

production-starter PostgreSQL Nomad job that fits your standards (dynamic ports, Consul discovery, Vault/KV for secrets), plus an optional init task to create the PowerDNS DB/user.

## Option A — Single instance (starter/prod-lite)

[postgresql.nomad.hcl](nomad-jobs/platform-services/.testing/postgresql/postgresql.nomad.hcl)

## Notes
Dynamic port: Consul service postgres advertises the real port. Downstream jobs (like PowerDNS) should resolve service "postgres" in templates to grab Address/Port at render time.

Host volume: Add to each Nomad client you might schedule on:

```bash
host_volume "pgdata" { path = "/srv/nomad/pgdata"; read_only = false }
```

Tighten `pg_hba.conf` to only your app subnets.
Backups: add a sidecar with `pg_dump` cron or `wal-g` to S3/MinIO later.

## Using it from your PowerDNS job (dynamic port friendly)
In your `pdns.conf` template, swap your static DB host/port for Consul-discovered values:

```hcl
gmysql-host={{ with service "postgres" }}{{ (index . 0).Address }}{{ end }}
gmysql-port={{ with service "postgres" }}{{ (index . 0).Port }}{{ end }}
```

This keeps Postgres on dynamic ports and still satisfies PDNS’s need for explicit host/port.

## Option B — HA later: Patroni/Spilo (heads-up)
When you’re ready for HA:

Run 3× Patroni instances (Zalando Spilo image) using Consul DCS, each with its own host volume.

Expose two services: `postgres-leader` and `postgres-replicas` (or a single `postgres` with dnsdist-style routing via haproxy sidecar / tcp_check).

Add a pgbouncer pool in front for stable client connections and graceful leader failover.
