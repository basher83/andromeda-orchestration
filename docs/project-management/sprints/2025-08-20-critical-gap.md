# CRITICAL GAP: Infrastructure Configuration Not Applied

**Date Discovered**: August 20, 2025
**Severity**: CRITICAL - Blocks all further work
**Impact**: Domain migration timeline at risk

---

## Summary

A critical gap has been discovered in the domain migration process. While PRs #71, #72, and #76 have been successfully merged, updating the repository code to use the new `homelab_domain` variable (spaceships.work), these changes have NOT been applied to the actual running infrastructure.

## Current State

### Repository (Git)

- ✅ PR #71: Added homelab_domain variable to group_vars
- ✅ PR #72: Updated Nomad jobs to use HCL2 variables
- ✅ PR #76: Migrated NetBox DNS playbooks to use domain variables
- ✅ All code in repository uses new domain structure

### Running Infrastructure

- ❌ Consul: Still configured with old domains
- ❌ Nomad: Running with old configuration
- ❌ Traefik: Using old domain in routes
- ❌ All services: Registered with old domain names
- ✅ PostgreSQL: Running and accessible (port 30837)
- ⚠️ PowerDNS: Deployed but not operational (port conflicts)

## Impact Analysis

### Immediate Impact

1. Cannot proceed with PowerDNS deployment
2. Cannot sync DNS zones with new domain
3. Cannot complete domain migration as planned
4. macOS developers remain blocked (mDNS conflict)

### Timeline Impact

- Original estimate: 3 hours for today's work
- Revised estimate: 5.5+ hours
- Risk of spillover into tomorrow's sprint
- Potential delay of entire migration by 1-2 days

## Root Cause

The deployment process was not clearly defined in the original plan. The assumption was that merging PRs would automatically update the infrastructure, but this requires explicit Ansible playbook runs to apply the configuration changes.

## Corrective Actions

### Immediate (Today)

1. **Step 0: Apply Infrastructure Configuration** (1.5 hours)
   - Run site.yml playbook to apply group_vars
   - Restart Consul and Nomad services
   - Re-deploy Nomad jobs with new variables

2. **Step 0.5: Deploy PostgreSQL** (45 minutes)
   - Create and deploy PostgreSQL Nomad job
   - Verify database accessibility
   - Create PowerDNS database schema

3. **Then proceed with original plan**
   - Deploy PowerDNS
   - Configure backend
   - Sync zones

### Process Improvements

1. **Update deployment checklist**
   - Add "Apply to infrastructure" step after PR merge
   - Include verification steps
   - Document rollback procedures

2. **Enhance documentation**
   - Create clear deployment runbook
   - Add infrastructure state verification steps
   - Include troubleshooting guide

3. **Improve sprint planning**
   - Account for infrastructure application time
   - Add explicit deployment tasks
   - Include verification milestones

## Lessons Learned

1. **Assumption Risk**: Never assume code changes are automatically applied
2. **Verification Gap**: Need better infrastructure state verification
3. **Documentation Need**: Deployment processes must be explicitly documented
4. **Planning Gap**: Sprint plans must include infrastructure application steps

## Resolution Timeline

- **08:00**: Gap discovered during PowerDNS deployment attempt
- **08:30**: Root cause identified
- **09:00**: Action plan updated with corrective steps
- **09:30**: Begin infrastructure configuration application
- **11:00**: Target: Infrastructure updated with new configuration
- **12:00**: ✅ PostgreSQL deployed and operational
- **14:00**: ⚠️ PowerDNS deployed but facing issues
- **22:00**: Current status - troubleshooting deployment issues

## Verification Checklist

- [ ] All hosts have new group_vars applied
- [ ] Consul services show spaceships.work domain
- [ ] Nomad jobs have homelab_domain variable set
- [ ] Traefik routes use new domain
- [x] PostgreSQL is running and accessible
- [x] PowerDNS can connect to PostgreSQL
- [ ] DNS queries resolve for spaceships.work

## Current Issues & Blockers

### Completed Progress

1. ✅ **PostgreSQL**: Successfully running on nomad-client-1:30837
2. ✅ **Database Setup**: pdns user created with Infisical password
3. ✅ **Consul KV**: PowerDNS configuration stored
4. ✅ **Infisical Secrets**: All credentials securely stored
5. ✅ **PowerDNS Job**: Successfully deployed to Nomad

### Active Issues

1. **Port 53 Conflict**: systemd-resolved and dnsmasq using port 53 on target nodes
2. **HCL2 Variable Passing**: Nomad parse API not correctly passing passwords through playbook
3. **Vault Dev Mode**: Still in dev mode, credentials lost on restart
4. **Group Vars Not Applied**: Infrastructure still needs domain variable updates
5. **Playbook Bug Fixed**: namespace variable conflict resolved in deploy-job.yml

### Technical Details

- PostgreSQL: Running with temporary bootstrap password
- PowerDNS: Job deployed but container failing to bind to port 53
- Secrets: Stored in Infisical at `/apollo-13/services/postgresql` and `/apollo-13/services/powerdns`
- Consul KV: Database connection details at `pdns/db/*`

## Communication

This critical gap has been communicated through:

- Updated sprint documentation
- Revised action plan with clear prerequisites
- Task summary updated with blocked status
- This dedicated alert document

## Next Steps

### Immediate Actions Required

1. **Resolve Port 53 Conflict**
   - Option A: Stop systemd-resolved and dnsmasq on target nodes
   - Option B: Configure PowerDNS to use alternative port
   - Option C: Use different nodes without DNS services

2. **Fix HCL2 Variable Passing**
   - Debug why parse API returns 400 Bad Request
   - Consider alternative: hardcode non-sensitive config, use Vault for secrets only

3. **Apply Domain Variables to Infrastructure**
   - Still pending - original Step 0 not yet executed
   - Required before services can use new domain

### Resolution Path

1. First: Resolve port conflict to get PowerDNS running
2. Then: Apply domain variables to infrastructure
3. Finally: Sync NetBox zones and test resolution

## August 22 Update - DNS IPAM Audit Results

### Infrastructure Assessment Completed

DNS IPAM audit reveals infrastructure is ready for PowerDNS deployment:

- ✅ **No DNS services running**: No BIND, dnsmasq, PowerDNS, or Pi-hole detected
- ✅ **Consul DNS operational**: Port 8600 active on all nodes for service discovery
- ✅ **Clean networking**: All nodes have dual NICs (2.5G on 192.168.10.x, 10G on 192.168.11.x)
- ✅ **External DNS only**: Using Google/Cloudflare resolvers (8.8.8.8, 1.1.1.1)
- ⚠️ **Port 53 available**: Audit shows port 53 NOT listening (contradicts earlier findings)

### Key Discovery

The DNS audit found that **port 53 is NOT in use** on any Nomad node, which contradicts the earlier finding about systemd-resolved/dnsmasq conflicts. This suggests:

1. The port conflict may have been on different nodes (not Nomad nodes)
2. Or the services were stopped/disabled since the initial attempt
3. PowerDNS should be deployable without port conflicts

### Infrastructure Readiness

Based on the audit, the infrastructure is MORE ready than previously thought:

- No conflicting DNS services to stop
- Port 53 appears available
- Consul DNS won't conflict (uses port 8600)
- All nodes accessible via multiple networks (local and Tailscale)

---

**Next Review**: After PowerDNS deployment retry
**Last Updated**: August 22, 2025 21:20 UTC
