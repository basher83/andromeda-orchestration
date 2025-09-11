# Investigation Tracking Index

## Active Investigations

Track all investigation status and progress here.

### Current Active

| Investigation | Status | Priority | Started | Updated | Description |
| ------------- | ------ | -------- | ------- | ------- | ----------- |
|               |        |          |         |         |             |

### Recently Resolved

| Investigation                                                                    | Status      | Priority | Resolved   | Description                                           |
| -------------------------------------------------------------------------------- | ----------- | -------- | ---------- | ----------------------------------------------------- |
| [PostgreSQL Service Registration](2025-09-09-postgresql-service-registration.md) | ✅ RESOLVED | 🟡 HIGH  | 2025-09-09 | Fixed duplicate service blocks and ACL authentication |

### Archived

Investigations older than 30 days that have been resolved and documented

| Investigation | Status | Archived | Permanent Doc |
| ------------- | ------ | -------- | ------------- |
| _None yet_    | -      | -        | -             |

## Status Legend

- 🆕 **NEW** - Just discovered, investigation starting
- 🔍 **INVESTIGATING** - Research and diagnosis in progress
- 🎯 **DIAGNOSED** - Root cause identified, solution proposed
- ✅ **RESOLVED** - Issue fixed, testing completed
- 📚 **DOCUMENTED** - Moved to permanent troubleshooting guide
- 🔄 **RECURRING** - Issue reappeared, investigation reopened

## Priority Levels

- 🔴 **CRITICAL** - Production down, immediate action required
- 🟡 **HIGH** - Service degraded, needs urgent attention
- 🟢 **MEDIUM** - Important but not urgent
- 🔵 **LOW** - Nice to fix, minimal impact

## Quick Start New Investigation

```bash
# Create new investigation from template
cp template.md $(date +%Y-%m-%d)-issue-name.md

# Edit investigation document
vim $(date +%Y-%m-%d)-issue-name.md

# Update this INDEX.md with new entry
vim INDEX.md
```

## Investigation Resources

- **[Template](template.md)** - Standard investigation template
- **[Workflow Guide](workflow.md)** - How to conduct investigations
- **[Example](2025-09-09-postgresql-service-registration.md)** - Completed investigation example

## Monthly Maintenance

- [ ] Archive resolved investigations > 30 days old
- [ ] Update permanent documentation with findings
- [ ] Review investigation effectiveness
- [ ] Update template based on lessons learned
