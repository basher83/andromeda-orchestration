# Roadmap: Service-Aware DNS & IPAM Overhaul

![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/ROADMAP.md)
![Current Phase](https://img.shields.io/badge/Current%20Phase-3--4%20NetBox%20%26%20PowerDNS-yellow)
![Status](https://img.shields.io/badge/Status-Active%20Development-green)

A phased approach to move from ad-hoc DNS to a robust, service-aware infrastructure using Consul, PowerDNS, NetBox, and Nomad.

## 📊 Current Status: Phase 3-4 In Progress 🚧

### ✅ Completed

- **Phase 0**: Infrastructure assessments (July 2025)
- **Phase 1**: Consul foundation (August 2025)
- **Phase 2**: PowerDNS deployment preparation (August 2025)

### 🚧 Active Work

- **Phase 3**: NetBox Integration (40% complete)
  - NetBox deployed and operational
  - DNS zones configured
  - Integration with PowerDNS in progress
- **Phase 4**: Domain Migration (.local → spaceships.work)
  - Critical priority due to macOS mDNS conflicts
  - Code updated, infrastructure deployment pending

### 🔗 Links

- [Current Sprint](docs/project-management/current-sprint.md)
- [GitHub Milestone](https://github.com/basher83/andromeda-orchestration/milestone/1)
- [Architecture Decisions](docs/project-management/decisions/)

---

## Phase 1: Cement Your Consul Foundation

1. **Enable Consul DNS on both clusters**
   - Open port `8600/udp` on Proxmox hosts and Nomad clients.
   - Point `/etc/resolv.conf` (or DHCP overrides) to `127.0.0.1#8600` for the `.service.consul` domain.
2. **Auto-register existing workloads**
   - VMs/LXCs: drop Consul agent config into `/etc/consul.d/` with node metadata.
   - Nomad jobs: include `consul { }` blocks in HCL so tasks appear under `service` in Consul.
3. **Validate service discovery**
   - `dig @127.0.0.1 -p 8600 web01.service.consul`
   - `consul catalog services`

---

## Phase 2: Deploy PowerDNS into Nomad

1. **Nomad job spec**
   - Group containing MariaDB and PowerDNS tasks.
   - Expose ports `53` (DNS) and `8081` (API/UI).
   - Add a `service` stanza for PowerDNS in Consul.
2. **Run and verify**
   - `nomad job run powerdns.nomad.hcl`
   - Test DNS: `dig @<nomad-node> example.lab.spaceships.workA`
   - Test API: `curl -H "X-API-Key: ChangeMe" http://<nomad-node>:8081/api/v1/servers`

---

## Phase 3: Hook up NetBox → PowerDNS

**🛠️ Bootstrap Tip:** You don't need NetBox fully populated to start—seed it with just the key host records you'll
initially manage (e.g., `proxmox01.lab.spaceships.work`, `nomad-client.lab.spaceships.work`). PowerDNS will sync these, and you can flesh
out the rest of your IPAM in parallel.

1. **NetBox IPAM**
   - Install and configure NetBox if not already running.
2. **PowerDNS plugin or sync script**
   - On record changes, push zones/records via PowerDNS HTTP API.
3. **Update resolvers**
   - Point DHCP or `/etc/resolv.conf` at the new PowerDNS service.

---

## Phase 4: Phase Out Pi-hole as Authoritative

1. **Flip authoritative roles**
   - Keep Pi-hole+Unbound upstream for ad-blocking only.
   - PowerDNS becomes authoritative for `*.lab.spaceships.work`.
2. **Migrate static entries**
   - Import any host entries from Pi-hole into NetBox.
3. **Deprecate and monitor**
   - Lower Pi-hole TTLs, remove its DHCP DNS option, watch for residual queries.

---

## Phase 5: Scale, Harden & Automate

1. **Scale PowerDNS**
   - Bump `group.count` to 2 in Nomad job.
   - Use Consul Connect or IPVS for active/active load balancing.
2. **Versioning & Rollbacks**
   - Push new Docker tags; Nomad handles rolling upgrades.
3. **Backup & DR**
   - Nightly MariaDB dumps; volume snapshots for NetBox/PDNS.
4. **Observability**

   - Integrate PowerDNS metrics into existing monitoring (Prometheus/StatsD).
   - Dashboard for query rates and replication lag.

5. **TLS/SSL Management**
   - **Public endpoints:** Use DNS-01 ACME (Let's Encrypt via PowerDNS API) in a Nomad job to obtain
     `*.lab.example.com` wildcard certificates.
   - **Internal services:** Leverage Vault PKI or Consul Connect mTLS for service-to-service encryption.
   - **Automation:** Schedule Nomad periodic jobs for certificate issuance and renewal; store certs in host volumes,
     Consul KV, or Vault.

---

> 🎯 **Outcome:**
>
> - Dynamic service discovery via Consul
> - Authoritative, audited DNS/IPAM via NetBox & PowerDNS
> - PowerDNS as authoritative for `*.lab.spaceships.work`
> - Scalable, self-healing deployments managed by Nomad
