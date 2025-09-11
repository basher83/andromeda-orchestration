# Investigations Directory

This directory contains active investigation documents for complex infrastructure issues requiring systematic research, diagnosis, and resolution.

## Directory Structure

```text
investigations/
├── README.md                    # This file
├── template.md                  # Investigation template
├── workflow.md                  # How to use the framework
└── YYYY-MM-DD-issue-name.md     # Active investigation documents
```

## Quick Start

### For New Investigations

```bash
# Create new investigation from template
cp template.md $(date +%Y-%m-%d)-new-issue-name.md

# Edit with your issue details
vim $(date +%Y-%m-%d)-new-issue-name.md

# Update main troubleshooting README
vim ../README.md  # Add to "Current Active Investigations"
```

### Template Structure

Each investigation follows a structured approach:

1. **Issue Summary** - Clear problem statement and impact
2. **Research Phase** - Initial investigation and hypothesis formation
3. **Diagnosis Phase** - Systematic testing and root cause analysis
4. **Resolution Phase** - Solution implementation and validation
5. **Documentation Phase** - Knowledge transfer and permanent guides

## Status Tracking

Update investigation status as work progresses:

- 🆕 **NEW** - Just created, investigation starting
- 🔍 **INVESTIGATING** - Research and diagnosis in progress
- 🎯 **DIAGNOSED** - Root cause identified, solution proposed
- ✅ **RESOLVED** - Issue fixed, testing completed
- 📚 **DOCUMENTED** - Moved to permanent troubleshooting guide
- 🔄 **RECURRING** - Issue reappeared, investigation reopened

## File Naming Convention

- **Template**: `template.md`
- **Workflow Guide**: `workflow.md`
- **Investigations**: `YYYY-MM-DD-issue-name.md`

## Workflow Integration

When an investigation is resolved:

1. **Create Permanent Documentation** in appropriate location
2. **Update Cross-References** in related guides
3. **Archive Investigation** (move to archive subdirectory)
4. **Update Status** to 📚 DOCUMENTED

## Current Active Investigations

- 🔍 **[PostgreSQL Service Registration](2025-01-09-postgresql-service-registration.md)** - Service identity regression investigation

## Archive

Resolved investigations are moved to the `archive/` subdirectory for historical reference.

---

Last Updated: 2025-09-10

## Source of truth for statuses: investigations/INDEX.md
