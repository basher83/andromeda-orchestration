# Sprint Action Plan: August 20, 2025

**Focus**: Complete Domain Migration Sprint 3 - PowerDNS Integration
**Current Status**: 50% of domain migration complete (PRs #71, #72, #76 merged)
**Target**: Complete PR #4 today for PowerDNS integration

---

## 🚨 CRITICAL GAP DISCOVERED

### The Problem

PRs #71, #72, and #76 successfully updated the REPOSITORY CODE to use the new domain variable (spaceships.work), but these changes have NOT been applied to the ACTUAL RUNNING INFRASTRUCTURE yet.

**Current Situation**:

- Repository code: Updated with homelab_domain variable ✅
- Running infrastructure: Still using old configuration ❌
- Consul, Nomad, and all services: Still configured with old domains ❌
- PowerDNS: Not deployed yet ❌
- PostgreSQL backend: Not deployed yet ❌

### Impact

We CANNOT proceed with PowerDNS deployment until:

1. The new domain configuration is applied to all running infrastructure
2. PostgreSQL backend is deployed (PowerDNS dependency)
3. Services are restarted/reloaded with new configuration

## Revised Action Plan (Priority Order)

### Step 0: Apply Repository Changes to Infrastructure (CRITICAL - 1.5 hours)

**THIS MUST BE DONE FIRST - Infrastructure is still running old configuration!**

**Steps**:

1. Apply new group_vars to all hosts:

   ```bash
   # Apply to doggos-homelab cluster (Nomad/Consul)
   uv run ansible-playbook playbooks/site.yml 
     -i inventory/doggos-homelab/infisical.proxmox.yml 
     --limit doggos-homelab
   
   # Apply to og-homelab cluster if needed
   uv run ansible-playbook playbooks/site.yml 
     -i inventory/og-homelab/infisical.proxmox.yml 
     --limit og-homelab
   ```

2. Update Consul configuration with new domain:

   ```bash
   # Verify Consul is using new domain
   uv run ansible-playbook playbooks/infrastructure/consul-config-update.yml 
     -i inventory/doggos-homelab/infisical.proxmox.yml
   ```

3. Restart/reload critical services:

   ```bash
   # Restart Consul agents to pick up new configuration
   ansible doggos-homelab -m systemd -a "name=consul state=restarted" 
     -i inventory/doggos-homelab/infisical.proxmox.yml
   
   # Restart Nomad to ensure it's using updated Consul
   ansible doggos-homelab -m systemd -a "name=nomad state=restarted" 
     -i inventory/doggos-homelab/infisical.proxmox.yml
   ```

4. Update running Nomad jobs with new domain variables:

   ```bash
   # Re-deploy Traefik with new domain
   uv run ansible-playbook playbooks/infrastructure/nomad/deploy-traefik.yml 
     -i inventory/doggos-homelab/infisical.proxmox.yml
   
   # Update any other running jobs that use domains
   nomad job plan <job-name>
   nomad job run <job-name>
   ```

5. Verify changes are applied:

   ```bash
   # Check Consul services are registered with new domain
   consul catalog services
   consul catalog nodes
   
   # Verify Nomad jobs have new variables
   nomad job inspect traefik | grep spaceships.work
   ```

### Step 0.5: Deploy PostgreSQL Backend (PREREQUISITE - 45 minutes)

**PowerDNS requires PostgreSQL - must be deployed first!**

**Steps**:

1. Check if PostgreSQL job exists:

   ```bash
   ls nomad-jobs/platform-services/postgresql.nomad.hcl
   ```

2. If not, create PostgreSQL Nomad job:

   ```hcl
   # nomad-jobs/platform-services/postgresql.nomad.hcl
   job "postgresql" {
     datacenters = ["doggos"]
     type = "service"
     
     group "db" {
       network {
         port "db" { static = 5432 }
       }
       
       task "postgres" {
         driver = "docker"
         
         config {
           image = "postgres:15"
           ports = ["db"]
           volumes = [
             "/opt/postgresql/data:/var/lib/postgresql/data"
           ]
         }
         
         env {
           POSTGRES_DB = "powerdns"
           POSTGRES_USER = "powerdns"
           POSTGRES_PASSWORD = "${POSTGRES_PASSWORD}"
         }
         
         service {
           name = "postgresql"
           port = "db"
           
           check {
             type = "tcp"
             interval = "10s"
             timeout = "2s"
           }
         }
       }
     }
   }
   ```

3. Deploy PostgreSQL:

   ```bash
   uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml 
     -i inventory/doggos-homelab/infisical.proxmox.yml 
     -e job=nomad-jobs/platform-services/postgresql.nomad.hcl
   ```

4. Verify PostgreSQL is running:

   ```bash
   nomad job status postgresql
   
   # Test connection
   psql -h <postgres-ip> -U powerdns -d powerdns
   ```

5. Create PowerDNS schema:

   ```sql
   -- Connect to PostgreSQL and run PowerDNS schema
   -- This may be automated in the PowerDNS container
   ```

### Step 1: Deploy PowerDNS to Nomad (1 hour)

**Blocker**: PowerDNS must be running before we can sync zones

**Steps**:

1. Review and update `nomad-jobs/platform-services/powerdns-auth.nomad.hcl`
   - Add HCL2 variable for `homelab_domain`
   - Update any hardcoded domains
   - Verify PostgreSQL configuration

2. Deploy PowerDNS:

   ```bash
   uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
     -i inventory/doggos-homelab/infisical.proxmox.yml \
     -e job=nomad-jobs/platform-services/powerdns-auth.nomad.hcl
   ```

3. Verify deployment:
   - Check Nomad UI for job status
   - Test DNS port 53 is accessible
   - Verify API endpoint is reachable

### 2. Configure PowerDNS Backend (30 minutes)

**Requirements**:

- PostgreSQL database for PowerDNS
- API key configuration
- Consul KV store setup

**Steps**:

1. Set up PostgreSQL database (if not exists)
2. Configure Consul KV for PowerDNS:

   ```bash
   consul kv put pdns/db/host <postgres-host>
   consul kv put pdns/db/port 5432
   consul kv put pdns/db/name powerdns
   consul kv put pdns/db/user powerdns
   ```

3. Store secrets in Vault/Infisical:
   - Database password
   - API key

### 3. Sync NetBox Zones to PowerDNS (1 hour)

**Prerequisites**: PowerDNS running and accessible

**Steps**:

1. Update sync playbooks with correct PowerDNS endpoints
2. Run zone sync:

   ```bash
   uv run ansible-playbook playbooks/infrastructure/netbox/dns/sync-to-powerdns.yml
   ```

3. Verify zones in PowerDNS:

   ```bash
   # Test from client
   dig @<powerdns-ip> spaceships.work SOA
   dig @<powerdns-ip> ns1.spaceships.work A
   ```

### 4. Fix Remaining .local References (30 minutes)

**Files to update**:

- `playbooks/infrastructure/nomad/deploy-traefik.yml` (lines 88, 93)
- Any active configuration files

**Actions**:

1. Replace hardcoded `.local` with `{{ homelab_domain }}`
2. Update documentation strings
3. Test playbook execution

## Updated Time Estimates

- **Step 0**: Apply infrastructure changes - 1.5 hours (NEW)
- **Step 0.5**: Deploy PostgreSQL - 45 minutes (NEW)
- **Step 1**: Deploy PowerDNS - 1 hour
- **Step 2**: Configure backend - 30 minutes
- **Step 3**: Sync zones - 1 hour
- **Step 4**: Fix remaining references - 30 minutes

**Total Revised Estimate**: 5.5 hours (was 3 hours)

## Known Issues & Blockers

### Issue #75: Security Hardening Needed

- Nomad job deployment playbook lacks security validation
- Not blocking current work but should be addressed

### PowerDNS Deployment Architecture

- Using host network mode (port 53 requires root)
- API on dynamic port via Nomad
- Consul service registration for discovery

## Testing Checklist

- [ ] PowerDNS responds on port 53
- [ ] API endpoint accessible
- [ ] Zones transferred from NetBox
- [ ] Forward lookups working
- [ ] Reverse lookups working
- [ ] Consul service registered
- [ ] Traefik routing to API
- [ ] No .local references in active code

## Risk Mitigation

1. **DNS Service Disruption**
   - Keep Pi-hole as primary until PowerDNS verified
   - Test with specific clients first
   - Have rollback plan ready

2. **Database Connection Issues**
   - Verify PostgreSQL accessibility
   - Check credentials in Vault/Consul
   - Monitor connection pool

3. **Zone Transfer Failures**
   - Validate NetBox API connectivity
   - Check zone format compatibility
   - Review sync script logs

## Revised Success Criteria for Today

1. ✅ Infrastructure updated with new domain configuration
2. ✅ PostgreSQL backend deployed and accessible
3. ✅ PowerDNS deployed and running in Nomad
4. ⚠️  Zones synced from NetBox to PowerDNS (if time permits)
5. ⚠️  Basic DNS queries working for spaceships.work (if time permits)
6. ⚠️  PR #4 created with integration changes (may extend to tomorrow)
7. Clear documentation of actual infrastructure state

## Commands Reference

```bash
# STEP 0: Apply infrastructure changes (DO THIS FIRST!)
uv run ansible-playbook playbooks/site.yml 
  -i inventory/doggos-homelab/infisical.proxmox.yml 
  --limit doggos-homelab

# STEP 0.5: Deploy PostgreSQL backend
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml 
  -i inventory/doggos-homelab/infisical.proxmox.yml 
  -e job=nomad-jobs/platform-services/postgresql.nomad.hcl

# STEP 1: Deploy PowerDNS
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/platform-services/powerdns-auth.nomad.hcl

# Sync zones
uv run ansible-playbook playbooks/infrastructure/netbox/dns/sync-to-powerdns.yml

# Test DNS
dig @192.168.10.11 spaceships.work SOA
dig @192.168.10.11 ns1.spaceships.work A
dig @192.168.10.11 traefik.doggos.spaceships.work A

# Check job status (from Nomad server)
nomad job status powerdns-auth
nomad alloc status <alloc-id>

# View logs
nomad alloc logs <alloc-id>
```

## Next Sprint (Tomorrow - Aug 21)

**PR #5**: Update all Ansible playbooks

- Fix remaining .local references
- Update inventory files
- Test all critical playbooks
- Estimated: 3 hours

---

**Note**: This is a living document. Update as work progresses throughout the day.
