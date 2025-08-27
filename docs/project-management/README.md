# Project Management

![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/docs/project-management/README.md)
![PM Health](https://img.shields.io/badge/PM%20Health-Good-green)

This directory contains project tracking documentation using a streamlined three-tier system optimized for solo development.

## 🎯 Three-Tier Project Management System

### Tier 1: Strategic (Quarterly)
**[ROADMAP.md](../../ROADMAP.md)** - High-level phases and milestones
- Updated monthly
- Links to GitHub milestones
- Overall project direction

### Tier 2: Tactical (Weekly/Sprint)
**[current-sprint.md](./current-sprint.md)** - Active work tracking
- Updated weekly
- Current sprint goals and blockers
- Links to GitHub issues

**[decisions/](./decisions/)** - Architecture Decision Records (ADRs)
- Critical decisions and their rationale
- Created as needed for significant choices
- Template: [ADR-TEMPLATE.md](./decisions/ADR-TEMPLATE.md)

### Tier 3: Operational (Daily)
**[GitHub Issues](https://github.com/basher83/andromeda-orchestration/issues)** - Task tracking
- All actionable work items
- Bug reports and feature requests
- Daily updates via comments

## 📋 Process Guide

### Weekly Sprint Planning
1. Review ROADMAP.md for current phase objectives
2. Update current-sprint.md with week's goals
3. Link to relevant GitHub issues
4. Identify and document blockers

### Making Architectural Decisions
1. Copy ADR-TEMPLATE.md to `decisions/ADR-YYYY-MM-DD-title.md`
2. Fill out all sections
3. Update status badge when decision is finalized
4. Reference in current-sprint.md if relevant

### Monthly Roadmap Review
1. Update ROADMAP.md phase status
2. Archive completed sprint documentation
3. Review and close completed GitHub milestones
4. Plan next month's objectives

## 📊 Quick Status Check

Run this command to check PM documentation freshness:
```bash
mise run pm-status
```

## 🗂️ Directory Structure

```
project-management/
├── README.md              # This file - process guide
├── current-sprint.md      # Active sprint work
├── decisions/             # Architecture Decision Records
│   ├── ADR-TEMPLATE.md   # Template for new decisions
│   └── ADR-*.md          # Documented decisions
├── phases/                # Future phase planning
│   ├── phase-3-netbox.md
│   ├── phase-4-dns-integration.md
│   ├── phase-5-multisite.md
│   └── phase-6-post-implementation.md
├── completed/             # Completed work by month
│   ├── 2025-07.md        # July completions
│   └── 2025-08.md        # August completions
└── archive/               # Historical documents
    └── *.md              # Archived/deprecated docs
```

## 🚀 Quick Links

- **What's happening now?** → [current-sprint.md](./current-sprint.md)
- **Where are we heading?** → [ROADMAP.md](../../ROADMAP.md)
- **Why did we decide that?** → [decisions/](./decisions/)
- **What did we complete?** → [completed/](./completed/)

## 🏷️ Status Badges

All key documents use dynamic GitHub badges to show last update time:
- No manual date updates needed
- Automatically reflects git commit times
- Visual indication of staleness

Example:
```markdown
![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/path/to/file.md)
```

## 📝 Best Practices

### For Solo Development
1. **Keep it simple** - Don't duplicate GitHub data locally
2. **Update regularly** - Weekly sprints, monthly roadmap
3. **Document decisions** - ADRs for future reference
4. **Use automation** - Dynamic badges over manual dates

### What NOT to Track Here
- Individual task details (use GitHub issues)
- Code discussions (use PR comments)
- Bug reports (use GitHub issues)
- Feature requests (use GitHub issues)

## 🔄 Migration Note

This structure was adopted on 2025-01-27 to simplify project management. See [ADR-2025-01-27-project-management-restructure.md](./decisions/ADR-2025-01-27-project-management-restructure.md) for details on why we made this change.

Previous files have been archived for reference:
- task-summary.md → Merged into ROADMAP.md
- github-issue-tracker.md → Removed (use GitHub directly)
- task-list.md → Merged into this README
