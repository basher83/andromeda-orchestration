# Issue Investigation Template

**Investigation ID**: YYYY-MM-DD-issue-name
**Status**: 🆕 NEW | 🔍 INVESTIGATING | 🎯 DIAGNOSED | ✅ RESOLVED | 📚 DOCUMENTED | 🔄 RECURRING
**Priority**: 🔴 CRITICAL | 🟡 HIGH | 🟢 MEDIUM | 🔵 LOW
**Started**: YYYY-MM-DD
**Resolved**: YYYY-MM-DD (if applicable)

---

## Issue Summary

### Problem Statement

[Brief, clear description of the issue as reported]

### Initial Symptoms

- [ ] Symptom 1
- [ ] Symptom 2
- [ ] Symptom 3

### Affected Components

- **Primary**: [component/service]
- **Secondary**: [affected components]
- **Environment**: [production/staging/development]

### Business Impact

[Describe impact on operations, users, or business processes]

---

## Research Phase

### Initial Investigation

[What was done first to understand the issue]

#### Commands Run

```bash
# Initial diagnostic commands
command 1
command 2
```

#### Findings

- [ ] Finding 1
- [ ] Finding 2

### Literature Review

[Research into similar issues, documentation, known solutions]

#### Internal References

- [ ] Related issue #123
- [ ] Previous investigation YYYY-MM-DD-similar-issue
- [ ] Documentation reference

#### External References

- [ ] Official documentation link
- [ ] Community forum discussion
- [ ] Stack Overflow/GitHub issue

### Hypothesis Formation

[Initial theories about what might be causing the issue]

#### Hypothesis 1: [Brief description]

**Evidence:**

- Point 1
- Point 2

**Test Plan:**

- Step 1
- Step 2

#### Hypothesis 2: [Brief description]

**Evidence:**

- Point 1
- Point 2

**Test Plan:**

- Step 1
- Step 2

---

## Diagnosis Phase

### Systematic Testing

[Structured testing to validate/invalidate hypotheses]

#### Test 1: [Test name]

**Objective:** [What we're testing]
**Procedure:**

```bash
# Test commands
command 1
command 2
```

**Expected Result:** [What should happen]
**Actual Result:** [What actually happened]
**Conclusion:** ✅ CONFIRMED | ❌ INVALIDATED | ❓ INCONCLUSIVE

#### Test 2: [Test name]

**Objective:** [What we're testing]
**Procedure:**

```bash
# Test commands
command 1
command 2
```

**Expected Result:** [What should happen]
**Actual Result:** [What actually happened]
**Conclusion:** ✅ CONFIRMED | ❌ INVALIDATED | ❓ INCONCLUSIVE

### Root Cause Analysis

[Final determination of the actual cause]

#### Confirmed Root Cause

[Detailed explanation of what was actually causing the issue]

#### Contributing Factors

- [ ] Factor 1
- [ ] Factor 2
- [ ] Factor 3

#### Why It Wasn't Initially Obvious

[Explain why initial symptoms pointed elsewhere]

---

## Resolution Phase

### Solution Design

[Detailed plan for fixing the issue]

#### Solution Components

1. **Component 1**: [Description]
2. **Component 2**: [Description]
3. **Component 3**: [Description]

#### Risk Assessment

- **Risk Level**: 🔴 HIGH | 🟡 MEDIUM | 🟢 LOW
- **Potential Impact**: [Description]
- **Mitigation Plan**: [Steps to minimize risk]

### Implementation Steps

#### Step 1: [Step name]

**Objective:** [What this step achieves]
**Commands:**

```bash
# Implementation commands
command 1
command 2
```

**Verification:**

```bash
# Verification commands
command 1
command 2
```

**Rollback Plan:**

```bash
# Rollback commands if needed
command 1
command 2
```

#### Step 2: [Step name]

**Objective:** [What this step achieves]
**Commands:**

```bash
# Implementation commands
command 1
command 2
```

**Verification:**

```bash
# Verification commands
command 1
command 2
```

**Rollback Plan:**

```bash
# Rollback commands if needed
command 1
command 2
```

### Testing & Validation

#### Functional Testing

[Tests to ensure the fix works]

##### Test Case 1: [Test name]

**Objective:** [What we're verifying]
**Procedure:**

```bash
# Test commands
command 1
command 2
```

**Expected Result:** [What should happen]
**Actual Result:** [What actually happened]
**Status:** ✅ PASSED | ❌ FAILED | ❓ NEEDS REVIEW

##### Test Case 2: [Test name]

**Objective:** [What we're verifying]
**Procedure:**

```bash
# Test commands
command 1
command 2
```

**Expected Result:** [What should happen]
**Actual Result:** [What actually happened]
**Status:** ✅ PASSED | ❌ FAILED | ❓ NEEDS REVIEW

#### Regression Testing

[Tests to ensure we didn't break anything]

##### Regression Test 1: [Test name]

**Status:** ✅ PASSED | ❌ FAILED | ❓ NEEDS REVIEW

##### Regression Test 2: [Test name]

**Status:** ✅ PASSED | ❌ FAILED | ❓ NEEDS REVIEW

---

## Documentation & Knowledge Transfer

### Resolution Summary

[Executive summary of what was done and why]

### Files Created/Modified

- [ ] File 1: [description of changes]
- [ ] File 2: [description of changes]
- [ ] File 3: [description of changes]

### Playbooks/Scripts Created

- [ ] Playbook 1: [description and usage]
- [ ] Script 1: [description and usage]

### Lessons Learned

[What we learned from this investigation]

#### What Went Well

- [ ] Point 1
- [ ] Point 2

#### What Could Be Improved

- [ ] Point 1
- [ ] Point 2

#### Prevention Measures

- [ ] Measure 1
- [ ] Measure 2

### Permanent Documentation Plan

[How this will be integrated into the knowledge base]

#### Target Location

- [ ] `docs/troubleshooting/[category]/[issue].md`
- [ ] `docs/operations/[procedure].md`
- [ ] `docs/implementation/[component]/README.md`

#### Integration Steps

1. Step 1
2. Step 2
3. Step 3

---

## Timeline & Effort

### Investigation Timeline

- **Started**: YYYY-MM-DD HH:MM
- **Root Cause Identified**: YYYY-MM-DD HH:MM
- **Resolution Implemented**: YYYY-MM-DD HH:MM
- **Testing Completed**: YYYY-MM-DD HH:MM
- **Documentation Completed**: YYYY-MM-DD HH:MM

### Time Breakdown

- **Research**: X hours
- **Diagnosis**: X hours
- **Resolution**: X hours
- **Testing**: X hours
- **Documentation**: X hours

### Team Involvement

- **Primary Investigator**: [Name]
- **Contributors**: [Names]
- **Reviewers**: [Names]

---

## References & Links

### Internal References

- [ ] Issue/PR #123
- [ ] Investigation YYYY-MM-DD-related-issue
- [ ] Documentation reference

### External References

- [ ] Official documentation
- [ ] Community resources
- [ ] Vendor support tickets

### Related Issues

- [ ] Issue #456 (similar symptoms)
- [ ] Issue #789 (related component)
- [ ] Investigation YYYY-MM-DD-previous-occurrence

---

## Follow-up Actions

### Immediate (Next 24 hours)

- [ ] Action 1
- [ ] Action 2

### Short-term (Next week)

- [ ] Action 1
- [ ] Action 2

### Long-term (Next month)

- [ ] Action 1
- [ ] Action 2

### Monitoring & Alerts

[What monitoring should be added to detect this issue early]

---

_Template Version: 1.0 | Last Updated: YYYY-MM-DD_
