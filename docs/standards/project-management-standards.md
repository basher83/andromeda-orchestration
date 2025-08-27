# Project Management Standards

## Purpose

Define how projects, tasks, and progress are tracked to ensure visibility, accountability, and successful delivery in infrastructure automation projects.

## Background

Infrastructure automation projects involve complex dependencies, multiple systems, and potential for significant impact. Structured project management prevents scope creep, ensures clear communication, and provides predictable delivery. These standards were developed from the operational patterns in our DNS/IPAM implementation and are designed to scale across all infrastructure initiatives.

## Standard

### Task Tracking

#### Three-Tier Project Management System

Project management follows the three-tier system established in [ADR-2025-01-27](../project-management/decisions/ADR-2025-01-27-project-management-restructure.md):

**Tier 1: Strategic (Quarterly)**
- **Location**: `/ROADMAP.md` in repository root
- **Content**: High-level phases, milestones, completion percentages
- **Update Frequency**: Monthly
- **Links**: GitHub milestones for phase tracking

**Tier 2: Tactical (Weekly/Sprint)** 
- **Location**: `/docs/project-management/current-sprint.md`
- **Content**: Active sprint goals, blockers, in-progress work
- **Update Frequency**: Weekly
- **Format**:

```markdown
### Task Name

- **Description**: Clear description of the work
- **Status**: Not Started | In Progress | Completed | Blocked
- **Priority**: P0 (Critical) | P1 (High) | P2 (Medium) | P3 (Low)
- **Blockers**: None | Specific blocking issues
- **Related**: Links to GitHub issues, PRs, or docs
- **Next Actions**: Specific actionable steps
```

**Tier 3: Operational (Daily)**
- **Location**: GitHub Issues
- **Content**: Individual tasks, bug reports, feature requests
- **Update Frequency**: As work progresses
- **Labels**: Priority, status, component tags

**Priority Levels:**

- **P0 (Critical)**: System down, security issue, or deployment blocker (resolve immediately)
- **P1 (High)**: Implementation blockers or urgent requirements (1-3 days)
- **P2 (Medium)**: Important features or improvements (1-2 weeks)
- **P3 (Low)**: Nice-to-have or future enhancements (as time permits)

**Status Definitions:**

- **Not Started**: Task defined but work hasn't begun
- **In Progress**: Active work underway
- **Completed**: Task finished and verified
- **Blocked**: Cannot proceed due to dependencies or issues

#### Task Decomposition Guidelines

Break down large tasks into actionable subtasks:

- Each subtask should be completable in < 1 day
- Use checkbox format for easy progress tracking
- Group related subtasks under parent tasks
- Include verification steps in subtasks

### Documentation Requirements

#### Project Documentation Structure

```text
ROADMAP.md                           # Strategic planning (repo root)
docs/
├── project-management/
│   ├── README.md                   # Process guide & standards
│   ├── current-sprint.md          # Active sprint work (tactical)
│   ├── decisions/                 # Architecture Decision Records
│   │   ├── ADR-TEMPLATE.md       # Template for new decisions
│   │   └── ADR-YYYY-MM-DD-*.md   # Documented decisions
│   ├── phases/                    # Detailed phase planning
│   │   └── phase-X-*.md          # Phase-specific guides
│   ├── completed/                 # Archived sprint work
│   │   └── YYYY-MM.md            # Monthly completed tasks
│   └── archive/                   # Historical/deprecated docs
├── implementation/
│   ├── */implementation-plan.md   # Component implementation guides
│   └── */patterns.md             # Integration patterns
└── operations/
    ├── runbooks/                  # Operational procedures
    └── troubleshooting/           # Issue resolution guides
```

#### Required Documentation

**Strategic Planning** (`ROADMAP.md`):

- Phase status with completion percentages
- GitHub milestone links
- Current phase indication with badges
- Success criteria for each phase
- Cross-references to detailed phase docs

**Sprint Tracking** (`current-sprint.md`):

- Sprint goals and timeline (with dynamic badges)
- Active tasks with priority and status
- Blockers and risks
- Completed work section
- Sprint metrics (progress %, velocity)
- Links to GitHub issues and PRs

**Architecture Decisions** (`decisions/ADR-YYYY-MM-DD-*.md`):

Using the [ADR Template](../project-management/decisions/ADR-TEMPLATE.md):

- **Status**: Proposed | Accepted | Rejected | Superseded
- **Context**: Problem or decision driver
- **Decision**: Chosen solution
- **Consequences**: Positive, negative, and risks
- **Alternatives**: Other options considered
- **Implementation**: Action items
- **References**: Related documentation

### Project Phases

Infrastructure projects follow these standard phases:

#### Phase 0: Assessment/Discovery

- Current state documentation
- Requirements gathering
- Risk identification
- Success criteria definition
- Initial architecture design

#### Phase 1: Foundation

- Core infrastructure setup
- Basic service deployment
- Initial integration testing
- Documentation creation

#### Phase 2: Implementation

- Feature development
- Service integration
- Configuration management
- Initial testing

#### Phase 3: Migration

- Data migration planning
- Gradual rollout
- Rollback procedures
- User communication

#### Phase 4: Optimization

- Performance tuning
- Monitoring enhancement
- Automation improvements
- Documentation updates

#### Phase 5: Post-Implementation

- Lessons learned
- Documentation finalization
- Knowledge transfer
- Maintenance handoff

### Success Criteria

Define measurable success criteria for each phase:

**Technical Criteria:**

- All services operational
- Performance benchmarks met
- Zero data loss during migration
- Automated testing passing

**Operational Criteria:**

- Documentation complete
- Team trained
- Monitoring active
- Backup/recovery tested

**Business Criteria:**

- Downtime within acceptable limits
- User satisfaction maintained
- Cost targets achieved
- Timeline met

### Communication Standards

#### Status Update Frequency

**Three-Tier Update Cadence**:

- **Strategic (Monthly)**: Update ROADMAP.md phase percentages and milestones
- **Tactical (Weekly)**: Update current-sprint.md with goals, blockers, and progress
- **Operational (Daily)**: Update GitHub issues with comments and status changes

**Sprint Planning (Weekly)**:

1. Review ROADMAP.md for current phase objectives
2. Update current-sprint.md with week's goals
3. Link to relevant GitHub issues
4. Identify and document blockers

**Dynamic Status Badges** (automatic updates):

```markdown
![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/path/to/file.md)
![Sprint Status](https://img.shields.io/badge/Sprint-YYYY--MM--DD%20to%20YYYY--MM--DD-blue)
![Priority](https://img.shields.io/badge/Priority-Critical-red)
```

**Sprint Metrics** (in current-sprint.md):

- Completed tasks vs total
- Phase progress percentage  
- Active blockers count
- Risk level assessment
- Links to GitHub milestone

#### Stakeholder Communication

**Project Kickoff**:

- Objectives and success criteria
- Timeline and milestones
- Team and responsibilities
- Communication plan

**Phase Completion**:

- Achievements
- Lessons learned
- Next phase preview
- Updated timeline

**Project Completion**:

- Final deliverables
- Success metrics
- Handoff documentation
- Retrospective results

### Risk Management

#### Risk Register Format

```markdown
## Risk: [Title]
**Probability**: Low | Medium | High
**Impact**: Low | Medium | High
**Category**: Technical | Resource | Timeline | External
**Mitigation**: Planned response
**Owner**: Responsible person
**Status**: Active | Mitigated | Closed
```

#### Risk Categories

**Technical Risks**:

- Integration failures
- Performance issues
- Data loss
- Security vulnerabilities

**Resource Risks**:

- Key person dependencies
- Hardware availability
- Budget constraints
- Time limitations

**External Risks**:

- Vendor changes
- Compliance requirements
- Infrastructure failures
- Priority shifts

### Decision Tracking

#### Architecture Decision Records (ADRs)

All significant architectural decisions must be documented using ADRs as per [ADR-2025-01-27](../project-management/decisions/ADR-2025-01-27-project-management-restructure.md).

**Creating an ADR**:

1. Copy `/docs/project-management/decisions/ADR-TEMPLATE.md`
2. Name it `ADR-YYYY-MM-DD-descriptive-title.md`
3. Fill out all sections
4. Update status badge when decision is finalized
5. Reference in current-sprint.md if relevant

**ADR Process**:

1. **Identify**: Significant decision needed
2. **Document**: Create ADR with context and alternatives
3. **Review**: Share for team/stakeholder input
4. **Decide**: Update status to Accepted/Rejected
5. **Implement**: Track action items in GitHub issues
6. **Reference**: Link from relevant documentation

#### Change Management

**Change Request Format**:

```markdown
## Change Request: [Title]
**Date**: YYYY-MM-DD
**Requester**: Name
**Priority**: Critical | High | Medium | Low
**Impact**: Systems/services affected
**Justification**: Why this change is needed
**Implementation Plan**: How to implement
**Rollback Plan**: How to revert if needed
**Approval**: Required approvals
**Status**: Pending | Approved | Implemented | Rejected
```

## Rationale

The three-tier project management system provides:

1. **Clear Separation of Concerns**:
   - Strategic (ROADMAP.md): Quarterly planning, phase management
   - Tactical (current-sprint.md): Weekly goals, active work tracking
   - Operational (GitHub Issues): Daily task execution

2. **Automatic Dating**: Dynamic GitHub badges eliminate manual date updates
3. **Single Source of Truth**: Each tier has one authoritative location
4. **Reduced Overhead**: No duplication between local files and GitHub
5. **Better Visibility**: Stakeholders can engage at appropriate level
6. **Documented Decisions**: ADRs capture why, not just what

**When to Use Each Tier**:

- **ROADMAP.md**: Phase transitions, milestone planning, quarterly reviews
- **current-sprint.md**: Sprint planning, blocker tracking, weekly updates  
- **GitHub Issues**: Bug reports, feature requests, task assignments
- **ADRs**: Architectural decisions, technology choices, process changes

## Examples

### Good Example - Sprint Task (current-sprint.md)

```markdown
### Deploy Vault in Production Mode

- **Description**: Migrate Vault from dev mode to production with persistent storage
- **Status**: In Progress
- **Priority**: P0 (Critical - Blocks ALL production services)
- **Blockers**: None
- **Related**: [docs/implementation/vault/production-deployment.md](../implementation/vault/production-deployment.md)
- **Next Actions**:
  1. Create Raft storage configuration
  2. Deploy Vault with persistent volumes
  3. Initialize and unseal Vault
  4. Migrate existing secrets from Infisical
```

### Good Example - Strategic Planning (ROADMAP.md)

```markdown
## Phase 3: Hook up NetBox → PowerDNS

![Status](https://img.shields.io/badge/Status-40%25%20Complete-yellow)

- ✅ NetBox deployed and operational
- ✅ DNS zones configured
- 🚧 Integration with PowerDNS in progress
- ⏳ Sync script development

**GitHub Milestone**: [Phase 3: NetBox Integration](https://github.com/basher83/andromeda-orchestration/milestone/3)
```

### Bad Example - Mixed Concerns

```markdown
#### DNS Migration
Need to move DNS from old system to new system.
Status: Working on it
- Setup new DNS  
- Move records
- Test everything
- Update documentation
- Train team
```

*Issues: Mixes strategic, tactical, and operational concerns. Should be split across tiers.*

### Good Example - Risk Documentation

```markdown
## Risk: Pi-hole HA Cluster Migration Complexity
**Probability**: High
**Impact**: High
**Category**: Technical
**Mitigation**:
- Document current HA configuration thoroughly
- Create detailed migration runbook
- Test migration in dev environment
- Plan phased rollout with rollback capability
**Owner**: Infrastructure Team
**Status**: Active

**Updates**:
- 2025-07-30: Documentation completed in docs/operations/pihole-ha-cluster.md
- 2025-08-01: Dev environment testing scheduled for next sprint
```

## Exceptions

Lighter-weight project management is acceptable for:

1. **Emergency Fixes**: Document after resolution
2. **Small Changes**: < 4 hours effort, low risk
3. **Experimentation**: Proof of concepts or research
4. **Documentation Updates**: Unless major restructuring

Even exceptions should have minimal documentation:

- What was done
- Why it was urgent/small
- Any follow-up needed

## Migration

### Adopting Three-Tier System

Per [ADR-2025-01-27](../project-management/decisions/ADR-2025-01-27-project-management-restructure.md):

1. **Strategic Setup**:
   - Create/update ROADMAP.md with phases and milestones
   - Add dynamic GitHub badges for automatic dating
   - Link to GitHub milestones

2. **Tactical Setup**:
   - Create current-sprint.md for active work
   - Set up decisions/ directory with ADR template
   - Archive old tracking files (task-list.md, task-summary.md)

3. **Operational Setup**:
   - Move detailed tasks to GitHub issues
   - Set up labels (priority:P0-P3, status tags)
   - Create milestones for phases

4. **Weekly Workflow**:
   - Monday: Update current-sprint.md with week's goals
   - Daily: Update GitHub issues
   - Friday: Archive completed work, plan next sprint
   - Monthly: Update ROADMAP.md percentages

### Templates

**New Project Checklist**:

```markdown
- [ ] Create/update ROADMAP.md with phases
- [ ] Add GitHub milestones for each phase
- [ ] Create current-sprint.md from template
- [ ] Set up decisions/ with ADR template
- [ ] Create GitHub issue labels (priority:P0-P3)
- [ ] Add dynamic badges to key documents
- [ ] Document in ADR if significant architecture
```

**Weekly Sprint Checklist**:

```markdown
- [ ] Review ROADMAP.md for phase objectives
- [ ] Update current-sprint.md with week's goals
- [ ] Archive last week's completed tasks
- [ ] Create/update GitHub issues for new work
- [ ] Link sprint tasks to GitHub milestone
- [ ] Document blockers and risks
- [ ] Update phase percentage if milestone hit
```

## Tools

### Project Management Commands

```bash
# Check PM documentation freshness
mise run pm-status

# Quick HashiCorp service status checks
mise run status:quick     # All services (unauthenticated)
mise run status:consul    # Consul only
mise run status:nomad     # Nomad only
mise run status:vault     # Vault only

# Full authenticated status checks
mise run status:full      # Comprehensive check with Infisical tokens
```

### GitHub CLI for Task Management

```bash
# List issues for current milestone
gh issue list --milestone "Sprint 2025-01-27"

# Create new issue
gh issue create --title "Task title" --label "priority:P0" --milestone "Sprint 2025-01-27"

# View issue status
gh issue view NUMBER

# List pull requests
gh pr list --state open
```

### Sprint Progress Tracking

```bash
# Find blocked tasks in current sprint
grep -B2 "Blocked" docs/project-management/current-sprint.md

# Count GitHub issues by label
gh issue list --label "priority:P0" --json number --jq length
```

## References

- [ROADMAP](../../ROADMAP.md) - Strategic planning and phase tracking
- [Current Sprint](../project-management/current-sprint.md) - Active tactical work
- [Project Management README](../project-management/README.md) - Process guide
- [ADR-2025-01-27](../project-management/decisions/ADR-2025-01-27-project-management-restructure.md) - Three-tier system decision
- [ADR Template](../project-management/decisions/ADR-TEMPLATE.md) - Architecture decision template
- [Implementation Plans](../implementation/dns-ipam/implementation-plan.md) - Phase planning example
- [GitHub Issues](https://github.com/basher83/andromeda-orchestration/issues) - Operational task tracking
- [GitHub Milestones](https://github.com/basher83/andromeda-orchestration/milestones) - Phase milestones
