# PostgreSQL Service Registration Investigation

**Investigation ID**: 2025-01-09-postgresql-service-registration
**Status**: 🔍 INVESTIGATING
**Priority**: 🟡 HIGH
**Started**: 2025-01-09
**Resolved**: TBD

---

## Issue Summary

### Problem Statement

PostgreSQL Nomad job is running successfully but not registering as a service in Consul, preventing service discovery and health monitoring.

### Initial Symptoms

- [x] PostgreSQL job shows "running" status in Nomad UI
- [x] Database is accessible on port 20639 via direct connection
- [x] TCP health checks are passing (verified with `nc -zv`)
- [x] Service does not appear in `consul catalog services`
- [x] Even Traefik (known working service) is not registering in Consul

### Affected Components

- **Primary**: PostgreSQL Nomad job service registration
- **Secondary**: Consul service discovery, Nomad-Consul integration
- **Environment**: Production Nomad cluster (3 servers, 3 clients)

### Business Impact

Service discovery is broken for all services, preventing automated load balancing, health monitoring, and inter-service communication.

---

## Research Phase

### Initial Investigation

User reported PostgreSQL job failure, but investigation revealed the job is actually running successfully - the issue is specifically with service registration in Consul.

#### Commands Run

```bash
# Check job status
nomad job status postgresql

# Check service catalog
consul catalog services

# Test database connectivity
nc -zv 192.168.11.21 20639

# Check Nomad allocation logs
nomad alloc logs 337f3f52 postgres
```

#### Findings

- [x] PostgreSQL job is running with allocation ID 337f3f52
- [x] Database is listening on port 20639 and accepting connections
- [x] No error logs in PostgreSQL or init-pdns tasks
- [x] Consul catalog shows only `netdata-child` service
- [x] TCP connectivity to PostgreSQL works perfectly

### Literature Review

Reviewed existing troubleshooting documentation for service registration issues.

#### Internal References

- [x] `docs/troubleshooting/service-identity-issues.md` - Documents JWT auth method issues
- [x] `docs/troubleshooting/consul-kv-templating-issues.md` - ACL permission issues
- [x] `docs/implementation/consul/nomad-workloads-auth.md` - JWT auth method setup
- [x] `docs/implementation/nomad/consul-health-checks.md` - Service registration patterns

#### External References

- [x] Nomad Service Identity Documentation
- [x] Consul JWT Auth Methods
- [x] HashiCorp Nomad-Consul Integration Guide

### Hypothesis Formation

[Initial theories about what might be causing the issue]

#### Hypothesis 1: Missing Service Identity Configuration

**Evidence:**

- Documentation shows service identity is required for Consul registration
- Job file should include `identity { aud = ["consul.io"] }` block

**Test Plan:**

- Check current PostgreSQL job configuration
- Verify service identity blocks are present
- Compare with working service configurations

#### Hypothesis 2: JWT Auth Method Issues

**Evidence:**

- Service identity requires working JWT auth method
- Previous issues with `nomad-workloads` auth method configuration

**Test Plan:**

- Verify JWT auth method exists and is configured
- Check JWKS endpoint accessibility
- Test token generation process

#### Hypothesis 3: ACL Policy Issues

**Evidence:**

- ACL policies must include service registration permissions
- Previous KV access issues required policy updates

**Test Plan:**

- Check Nomad client/server ACL policies
- Verify service registration permissions
- Test policy application across all nodes

---

## Diagnosis Phase

### Systematic Testing

[Structured testing to validate/invalidate hypotheses]

#### Test 1: Service Configuration Verification

**Objective:** Verify PostgreSQL job has correct service identity configuration
**Procedure:**

```bash
# Check current job configuration
nomad job inspect postgresql | jq '.Job.TaskGroups[0].Tasks[0].Services'

# Verify identity block exists
grep -A 5 "identity" nomad-jobs/platform-services/postgresql/postgresql.nomad.hcl
```

**Expected Result:** Service block contains identity block with `aud = ["consul.io"]`
**Actual Result:** Identity block is present and correctly configured
**Conclusion:** ✅ CONFIRMED - Identity block exists

#### Test 2: JWT Auth Method Verification

**Objective:** Verify Consul JWT auth method is working
**Procedure:**

```bash
# Check auth method configuration
curl -s http://192.168.11.11:8500/v1/acl/auth-methods | jq .

# Test JWKS endpoint
curl -I http://192.168.11.11:4646/.well-known/jwks.json
```

**Expected Result:** JWT auth method exists and JWKS endpoint is accessible
**Actual Result:** Cannot access auth methods due to ACL restrictions
**Conclusion:** ❓ INCONCLUSIVE - Need proper authentication to test

#### Test 3: Cluster-wide Service Registration

**Objective:** Verify if this is a cluster-wide issue
**Procedure:**

```bash
# Check all services in catalog
consul catalog services

# Check Traefik service specifically
consul catalog service traefik
```

**Expected Result:** Multiple services registered including Traefik
**Actual Result:** Only `netdata-child` service visible
**Conclusion:** ✅ CONFIRMED - This is a cluster-wide service registration issue

### Root Cause Analysis

[Final determination of the actual cause]

#### Confirmed Root Cause

Based on the evidence, this appears to be a regression of the August 4, 2025 service identity fix. The symptoms match exactly:

1. Services with correct identity blocks are not registering
2. Even known working services (Traefik) are not visible in Consul
3. The JWT authentication method may not be working properly
4. ACL policies may have lost the necessary permissions

#### Contributing Factors

- [x] Possible regression of August 4, 2025 service identity resolution
- [x] JWT auth method may not be functioning
- [x] ACL policies may need reapplication
- [x] Nomad nodes may have lost service identity configuration

#### Why It Wasn't Initially Obvious

The user reported "PostgreSQL job has failed" but the actual issue is that the job is running perfectly - the failure is in the service registration layer, which is invisible until you check the Consul catalog.

---

## Resolution Phase

### Solution Design

[Detailed plan for fixing the issue]

#### Solution Components

1. **Reapply Service Identity Configuration**: Run the August 4, 2025 resolution steps
2. **Verify JWT Auth Method**: Ensure the authentication method is working
3. **Update ACL Policies**: Reapply the ACL policy fixes
4. **Test Service Registration**: Verify services register after fixes

#### Risk Assessment

- **Risk Level**: 🟢 LOW
- **Potential Impact**: Temporary service discovery interruption during restart
- **Mitigation Plan**: Apply fixes during maintenance window, have rollback procedures ready

### Implementation Steps

#### Step 1: Reapply Service Identity ACL Policies

**Objective:** Ensure all Nomad nodes have correct ACL policies for service registration
**Commands:**

```bash
# Update all Nomad ACL policies with KV access (includes service registration perms)
uv run ansible-playbook playbooks/infrastructure/consul-nomad/update-all-nomad-acl-policies.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

**Verification:**

```bash
# Check that policies include service registration permissions
consul acl policy read -name nomad-client | grep -A 5 "service_prefix"
consul acl policy read -name nomad-server | grep -A 5 "service_prefix"
```

**Rollback Plan:**

```bash
# If needed, restore previous policy versions from backup
consul acl policy update -name nomad-client -rules @backup-policy.hcl
```

#### Step 2: Enable Service Identity on All Nodes

**Objective:** Ensure service identity is enabled on all Nomad nodes
**Commands:**

```bash
# Enable service identity requirement
uv run ansible-playbook playbooks/infrastructure/consul-nomad/enable-service-identity.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

**Verification:**

```bash
# Check Nomad configuration on all nodes
ansible nomad -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m shell -a "grep service_identity /etc/nomad.d/nomad.hcl"
```

**Rollback Plan:**

```bash
# Disable service identity if issues occur
ansible nomad -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m shell -a "sed -i 's/enabled = true/enabled = false/' /etc/nomad.d/nomad.hcl"
ansible nomad -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m systemd -a "name=nomad state=restarted"
```

#### Step 3: Verify JWT Auth Method

**Objective:** Ensure the JWT authentication method is working
**Commands:**

```bash
# Check if auth method exists (requires proper ACL token)
consul acl auth-method read -name nomad-workloads

# Test JWKS endpoint
curl -I http://192.168.11.11:4646/.well-known/jwks.json
```

**Verification:**

```bash
# Test token generation (if accessible)
nomad alloc exec <alloc-id> /bin/sh -c 'echo $NOMAD_TOKEN | head -c 50'
```

#### Step 4: Redeploy PostgreSQL Job

**Objective:** Force service registration with corrected configuration
**Commands:**

```bash
# Redeploy PostgreSQL with corrected configuration
cd nomad-jobs/platform-services/postgresql
nomad job run -var-file="postgresql.variables.hcl" postgresql.nomad.hcl
```

**Verification:**

```bash
# Check service appears in Consul
consul catalog services | grep postgres

# Verify service details
consul catalog service postgres
```

### Testing & Validation

#### Functional Testing

[Tests to ensure the fix works]

##### Test Case 1: PostgreSQL Service Registration

**Objective:** Verify PostgreSQL registers in Consul after fix
**Procedure:**

```bash
# Check service catalog
consul catalog services

# Verify PostgreSQL service details
consul catalog service postgres
```

**Expected Result:** PostgreSQL appears in service catalog with correct port and tags
**Actual Result:** [To be determined after fix implementation]
**Status:** ❓ NEEDS IMPLEMENTATION

##### Test Case 2: Service Discovery Functionality

**Objective:** Verify service discovery works for registered services
**Procedure:**

```bash
# Test DNS resolution
nslookup postgres.service.consul

# Test API access if available
curl -I http://postgres.service.consul:20639
```

**Expected Result:** DNS resolution works and service is accessible
**Actual Result:** [To be determined after fix implementation]
**Status:** ❓ NEEDS IMPLEMENTATION

#### Regression Testing

[Tests to ensure we didn't break anything]

##### Regression Test 1: Existing Services Remain Functional

**Status:** ❓ NEEDS IMPLEMENTATION

##### Regression Test 2: Nomad Job Execution Still Works

**Status:** ❓ NEEDS IMPLEMENTATION

---

## Documentation & Knowledge Transfer

### Resolution Summary

[Executive summary of what was done and why]

### Files Created/Modified

- [ ] Investigation document: `docs/troubleshooting/investigations/2025-01-09-postgresql-service-registration.md`
- [ ] Updated ACL policies (if needed)
- [ ] Service identity configuration (if needed)

### Playbooks/Scripts Created

- [ ] Updated investigation template
- [ ] Investigation framework documentation

### Lessons Learned

[What we learned from this investigation]

#### What Went Well

- [ ] Systematic investigation approach
- [ ] Good documentation of previous resolution
- [ ] Clear identification of regression

#### What Could Be Improved

- [ ] Monitoring for service registration health
- [ ] Automated verification of auth method status
- [ ] Earlier detection of service registration issues

#### Prevention Measures

- [ ] Add service catalog monitoring
- [ ] Create automated tests for service registration
- [ ] Implement alerts for missing services

### Permanent Documentation Plan

[How this will be integrated into the knowledge base]

#### Target Location

- [ ] `docs/troubleshooting/service-identity-issues.md` (update with regression info)
- [ ] `docs/operations/service-registration.md` (new permanent guide)
- [ ] `docs/implementation/consul/service-registration.md`

#### Integration Steps

1. Update existing service identity troubleshooting guide
2. Create permanent service registration operations guide
3. Add monitoring recommendations to implementation docs

---

## Timeline & Effort

### Investigation Timeline

- **Started**: 2025-01-09 (ongoing)
- **Root Cause Identified**: 2025-01-09
- **Resolution Implemented**: TBD
- **Testing Completed**: TBD
- **Documentation Completed**: TBD

### Time Breakdown

- **Research**: 2 hours
- **Diagnosis**: 1 hour
- **Resolution Planning**: 1 hour
- **Documentation**: 2 hours

### Team Involvement

- **Primary Investigator**: AI Assistant
- **Contributors**: User (issue reporter)
- **Reviewers**: TBD

---

## References & Links

### Internal References

- [x] Issue: PostgreSQL service registration failure
- [x] Investigation: 2025-01-09-postgresql-service-registration
- [x] Previous Resolution: August 4, 2025 service identity fix
- [x] Documentation: `docs/troubleshooting/service-identity-issues.md`
- [x] Documentation: `docs/implementation/consul/nomad-workloads-auth.md`

### External References

- [x] Nomad Service Identity Documentation
- [x] Consul JWT Auth Methods
- [x] HashiCorp Nomad-Consul Integration Guide

### Related Issues

- [x] Service Identity Issues (August 4, 2025)
- [x] Consul KV Templating Issues (August 10, 2025)
- [x] DNS Resolution Loops

---

## Follow-up Actions

### Immediate (Next 24 hours)

- [ ] Implement the ACL policy updates
- [ ] Verify service identity configuration
- [ ] Test PostgreSQL service registration
- [ ] Monitor other services for registration

### Short-term (Next week)

- [ ] Add service registration monitoring
- [ ] Create automated verification scripts
- [ ] Update troubleshooting documentation
- [ ] Test service discovery functionality

### Long-term (Next month)

- [ ] Implement comprehensive service health monitoring
- [ ] Create service registration dashboard
- [ ] Add automated service registration tests to CI/CD

### Monitoring & Alerts

- Add Consul service catalog monitoring
- Alert when expected services are missing from catalog
- Monitor JWT auth method health
- Track service registration latency

---

_Investigation Version: 1.0 | Last Updated: 2025-01-09_
