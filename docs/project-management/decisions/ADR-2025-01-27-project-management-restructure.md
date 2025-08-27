# ADR-2025-01-27: Three-Tier Project Management Structure

![Status](https://img.shields.io/badge/Status-Accepted-green)
![Date](https://img.shields.io/badge/Date-2025--01--27-lightgrey)
![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/docs/project-management/decisions/ADR-2025-01-27-project-management-restructure.md)

## Status

Accepted

## Context

As a solo developer managing the andromeda-orchestration project, the project management structure had grown unwieldy:

- Multiple files tracking the same information (github-issue-tracker.md, task-summary.md, current-sprint.md)
- Manual date updates that were always stale (ROADMAP.md last updated July 27, 2025)
- Duplication between local tracking and GitHub issues
- No formal process for documenting architectural decisions
- File sprawl making it hard to find current information

## Decision

Implement a three-tier project management system with automatic status badges:

### Tier 1: Strategic (Quarterly)

- **ROADMAP.md** in repo root with dynamic GitHub badges
- High-level phases and milestones
- Links to GitHub milestones
- Updated monthly

### Tier 2: Tactical (Weekly/Sprint)

- **current-sprint.md** for active work
- **decisions/** directory for Architecture Decision Records (ADRs)
- Dynamic badges showing last update times
- Minimal manual maintenance

### Tier 3: Operational (Daily)

- GitHub Issues for all actionable tasks
- GitHub Projects for kanban/workflow
- No local duplication of GitHub data

## Consequences

### Positive

- Automatic dating via GitHub badges eliminates stale "Last Updated" fields
- Clear separation of concerns (strategic/tactical/operational)
- ADRs capture important decisions for future reference
- Reduced maintenance overhead for solo developer
- Single source of truth for each type of information

### Negative

- Requires internet connection to see badge status
- Some learning curve for ADR format
- Historical PM files need migration/archival

### Risks

- Badge service (shields.io) dependency
- GitHub API rate limits for badges (unlikely to hit)

## Alternatives Considered

### Alternative 1: Git Hooks for Auto-Dating

- Would update dates in files automatically on commit
- Rejected: More complex, requires local setup, can cause merge conflicts

### Alternative 2: Keep Current Structure

- Continue with manual date updates and multiple tracking files
- Rejected: Proven to not work (dates always stale, files out of sync)

### Alternative 3: All-in-GitHub Approach

- Move all documentation to GitHub Wiki/Projects
- Rejected: Important to keep strategic docs in repo for versioning

## Implementation

1. ✅ Update ROADMAP.md with current status and badges
2. ✅ Create decisions/ directory with ADR template
3. ✅ Create this ADR as first decision record
4. Simplify current-sprint.md with badges
5. Archive redundant PM files (task-summary.md, github-issue-tracker.md)
6. Update PM README with new process
7. Add mise task for PM health check

## References

- [Original PM structure discussion](../archive/pm-assesment-2025-08-10.md)
- [GitHub Shields.io Documentation](https://shields.io/)
- [ADR Overview by Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
