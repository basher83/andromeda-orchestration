# Investigation Workflow Guide

This guide explains how to use the standardized investigation framework for documenting complex infrastructure issues.

## When to Create an Investigation

Use the investigation framework for:

- **Complex Issues**: Issues requiring systematic research and testing
- **Unknown Root Causes**: When the problem isn't immediately obvious
- **Multiple Components**: Issues affecting multiple systems or services
- **Business Impact**: Issues with significant operational impact
- **Recurring Issues**: Problems that have appeared before but weren't fully resolved

## Quick Start

### 1. Create Investigation Document

```bash
# Copy the template
cp docs/troubleshooting/investigations/template.md \
   docs/troubleshooting/investigations/$(date +%Y-%m-%d)-new-issue.md

# Edit with your issue details
vim docs/troubleshooting/investigations/$(date +%Y-%m-%d)-new-issue.md
```

### 2. Update Status Tracking

```bash
# Update the investigations INDEX
vim docs/troubleshooting/investigations/INDEX.md
# Add your investigation to the "Current Active Investigations" section
```

### 3. Follow the Investigation Workflow

The template guides you through:

- Research Phase: Initial investigation and hypothesis formation
- Diagnosis Phase: Systematic testing and root cause analysis
- Resolution Phase: Solution implementation and validation
- Documentation Phase: Knowledge transfer and permanent documentation

## Investigation Template Structure

### Issue Summary

- **Problem Statement**: Clear, concise description
- **Initial Symptoms**: What was first observed
- **Affected Components**: What's impacted
- **Business Impact**: Why this matters

### Research Phase

- **Initial Investigation**: What you did first
- **Literature Review**: Research into similar issues
- **Hypothesis Formation**: Initial theories with evidence

### Diagnosis Phase

- **Systematic Testing**: Structured validation of hypotheses
- **Root Cause Analysis**: Final determination of the cause

### Resolution Phase

- **Solution Design**: Detailed fix plan
- **Implementation Steps**: Exact commands and procedures
- **Testing & Validation**: Verification that the fix works

### Documentation Phase

- **Resolution Summary**: What was done and why
- **Lessons Learned**: What we learned
- **Permanent Documentation Plan**: How this becomes permanent knowledge

## Status Tracking

Update the investigation status as you progress:

- 🆕 **NEW** - Just created, investigation starting
- 🔍 **INVESTIGATING** - Research and diagnosis in progress
- 🎯 **DIAGNOSED** - Root cause identified, solution proposed
- ✅ **RESOLVED** - Issue fixed, testing completed
- 📚 **DOCUMENTED** - Moved to permanent troubleshooting guide
- 🔄 **RECURRING** - Issue reappeared, investigation reopened

## Transition to Permanent Documentation

When an investigation is resolved, create permanent documentation:

### 1. Create Permanent Guide

```bash
# Create in appropriate location
vim docs/troubleshooting/[category]/[issue]-guide.md
```

### 2. Update Cross-References

- Update the main troubleshooting README
- Link from related documentation
- Add to relevant implementation guides

### 3. Archive Investigation

```bash
# Move to archive
mv docs/troubleshooting/investigations/YYYY-MM-DD-issue-name.md \
   docs/troubleshooting/archive/investigations/

# Update status to 📚 DOCUMENTED
```

## Best Practices

### Documentation

- **Be Specific**: Include exact commands, error messages, and outputs
- **Show Evidence**: Document why you eliminated certain hypotheses
- **Include Context**: Explain why certain approaches were chosen
- **Track Timeline**: Record when things happened and how long they took

### Investigation

- **Start Broad**: Don't assume you know the cause initially
- **Test Systematically**: Have a clear plan for validating each hypothesis
- **Document Everything**: Even failed attempts provide valuable context
- **Collaborate**: Include team involvement and peer review

### Resolution

- **Plan Rollbacks**: Always have a way to undo changes
- **Test Thoroughly**: Verify fixes work and don't break other things
- **Monitor Long-term**: Ensure issues don't reappear

## Tools and Resources

### Investigation Tools

```bash
# Status checking
nomad job status <job>
consul catalog services
journalctl -u <service> -f

# Log analysis
nomad alloc logs <alloc-id>
grep -r "error\|fail" /var/log/

# Network testing
nc -zv <host> <port>
curl -I http://service.consul:port/health
```

### Documentation Tools

```bash
# Create investigation
cp investigation-template.md investigations/$(date +%Y-%m-%d)-issue-name.md

# Track progress
git add investigations/
git commit -m "docs: Add investigation for issue-name"
```

## Examples

### Good Investigation Topics

- Service registration failures
- Authentication/permission issues
- Performance degradation
- Network connectivity problems
- Configuration drift issues
- Resource exhaustion problems

### Investigation vs Quick Fix

- **Use Investigation**: PostgreSQL service registration (complex, multi-component)
- **Use Quick Fix**: Simple configuration error (single file change)

## Maintenance

### Monthly Review

- Archive resolved investigations older than 30 days
- Update permanent documentation with new findings
- Review investigation effectiveness

### Template Updates

- Update template based on lessons learned
- Add new sections for common patterns
- Incorporate feedback from investigators

## Getting Help

- **Template Issues**: Check the template for guidance
- **Workflow Questions**: Review this workflow guide
- **Examples**: Look at archived investigations
- **Team Review**: Have complex investigations peer-reviewed

---

Workflow Version: 1.0 | Last Updated: 2025-09-10 | Status source: investigations/INDEX.md
