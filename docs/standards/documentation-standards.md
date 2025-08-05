# Documentation Standards

## Purpose
Establish consistent documentation practices that ensure knowledge is preserved, discoverable, and actionable.

## Background
Documentation is not an afterthought—it's a first-class citizen in this repository. We've learned that undocumented systems become unmaintainable, and scattered documentation becomes useless.

## Standard

### Documentation Hierarchy

```
docs/
├── standards/          # WHY - Standards and decisions
├── implementation/     # HOW - Technical implementation guides
├── operations/        # WHAT - Day-to-day procedures
├── troubleshooting/   # WHEN - Problem resolution
├── project-management/# WHERE - Planning and tracking
└── diagrams/         # VISUAL - Architecture and flows

[service-directory]/
├── README.md         # Service-specific documentation only
├── .testing/        # Work in progress
└── .archive/        # Historical versions
```

### Placement Rules

1. **One README per directory** - Explains that directory's purpose
2. **Technical docs in docs/** - Never scatter .md files in code directories
3. **Service docs stay local** - Service-specific README in service directory
4. **Standards before implementation** - Document decisions before coding

### README Requirements

Every README must include:
- **Purpose** - Why this exists
- **Status** - Current state (Production/Testing/Planned)
- **Configuration** - Key settings
- **Usage** - How to deploy/operate
- **Troubleshooting** - Common issues

### Markdown Standards

```markdown
# Single H1 Title

## Clear Section Headers

- Lists with proper spacing
- Blank lines around blocks

```language
# Fenced code blocks with language
```

[Descriptive Links](relative/path.md) not [click here](path)
```

### TODO Tagging

Use consistent TODO tags for tracking tasks within documentation:

```markdown
[TODO]: Description of task to complete
[TODO]: Cross-reference with docs/other-file.md
[TODO]: Implement feature X after Y is complete
```

**Standards:**
- Format: `[TODO]: ` followed by clear action item
- Placement: At relevant location in document
- Searchable: Use `rg "\[TODO\]:"` to find all TODOs
- Examples:
  - `[TODO]: Add diagram for network architecture`
  - `[TODO]: Cross-reference with docs/troubleshooting/netdata-streaming-issues.md and combine the two documents`
  - `[TODO]: Update after Phase 2 implementation`

**Why TODO Tags?**
- **Visibility**: Easy to search across all documentation
- **Context**: TODOs stay near relevant content
- **Tracking**: Can generate TODO reports
- **Git-friendly**: Shows in diffs when added/resolved

## Rationale

### Why This Structure?
- **Discoverability**: Related docs are grouped together
- **Maintainability**: Clear ownership and placement rules
- **Scalability**: Structure works for 10 or 1000 documents
- **Git-friendly**: Changes are localized and reviewable

### Why Not Scatter Documentation?
- Hard to find related information
- Difficult to maintain consistency
- Increases cognitive load
- Makes refactoring painful

## Examples

### Good Example
```
nomad-jobs/
├── platform-services/
│   ├── README.md           # Documents PowerDNS deployment
│   ├── powerdns.nomad.hcl  # Single production file
│   └── .archive/           # Old versions

docs/
└── implementation/
    └── nomad-storage-configuration.md  # General storage guide
```

### Bad Example
```
nomad-jobs/
├── platform-services/
│   ├── README.md
│   ├── STORAGE.md         # ❌ General doc in service dir
│   ├── DEPLOYMENT.md      # ❌ Should be in README
│   ├── powerdns-v1.hcl    # ❌ Old versions visible
│   └── powerdns-test.hcl  # ❌ Test files in main dir
```

## Exceptions

- **Legal/Compliance docs** - May need specific placement
- **Third-party requirements** - Some tools expect docs in specific locations
- **Generated documentation** - API docs, schemas may auto-generate

## Migration

To meet these standards:

1. **Audit current docs** - Find all .md files
2. **Categorize** - Determine correct location
3. **Move systematically** - One category at a time
4. **Update references** - Fix all links
5. **Archive old locations** - Leave forwarding notes

## References

- [Repository Structure](../getting-started/repository-structure.md)
- [Project README](../../README.md)
- CommonMark Specification
- Write the Docs principles