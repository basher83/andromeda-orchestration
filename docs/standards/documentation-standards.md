# Documentation Standards

## Purpose

Establish consistent documentation practices that ensure knowledge is preserved, discoverable, and actionable.

## Background

Documentation is not an afterthought—it's a first-class citizen in this repository. We've learned that undocumented systems become unmaintainable, and scattered documentation becomes useless.

## Standard

### Documentation Hierarchy

```text
docs/
├── standards/          # WHY - Standards, decisions, patterns
├── implementation/     # HOW - Technical setup and configuration
│   ├── consul/        # Service-specific implementation
│   ├── nomad/         # guides grouped by service
│   ├── vault/
│   └── dns-ipam/
├── operations/        # WHAT - Day-to-day procedures and runbooks
│   ├── runbooks/      # Step-by-step operational procedures
│   └── maintenance/   # Routine maintenance tasks
├── troubleshooting/   # WHEN - Problem resolution guides
├── project-management/# WHERE - Planning, tracking, decisions
│   ├── phases/        # Implementation phase documentation
│   ├── completed/     # Completed work records
│   └── archive/       # Historical project artifacts
├── diagrams/         # VISUAL - Architecture and flows
├── getting-started/   # NEW USER - Onboarding and basics
```

### Placement Rules

1. **One README per directory** - Explains that directory's purpose
2. **Technical docs in docs/** - Never scatter .md files in code directories
3. **Service docs stay local** - Service-specific README in service directory
4. **Standards before implementation** - Document decisions before coding
5. **AI/Assistant docs belong in resources/** - Tool-specific context files
6. **Implementation-specific guides in implementation/{service}/** - Group by service

### Content Placement Guidelines

**docs/standards/** - Principles and patterns

- Architecture standards
- Development workflows
- Documentation standards
- Security policies

**docs/implementation/** - Technical how-to guides

- Service setup procedures
- Configuration examples
- Integration patterns
- Deployment guides

**docs/operations/** - Day-to-day procedures

- Runbooks and SOPs
- Maintenance procedures
- Monitoring guides
- Backup/restore procedures

**docs/troubleshooting/** - Problem resolution

- Common issues and solutions
- Debug procedures
- Error code references

**docs/project-management/** - Project tracking

- Phase documentation
- Task lists and progress
- Decision records
- Meeting notes

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

```text
# Fenced code blocks with language
```

[Descriptive Links](relative/path.md) not [go to documentation](path)

#### Linting Exceptions

When markdown linting rules need to be bypassed for legitimate reasons (e.g., raw terminal output, intentional formatting), use inline disable comments:

```markdown
<!-- markdownlint-disable-next-line MD040 -->
```

Some raw terminal output without language

```text
<command output omitted>
```

<!-- markdownlint-disable-next-line MD013 -->
This line is intentionally longer than 80 characters because it contains a very important URL that should not be broken: [https://example.com/very/long/path](https://example.com/very/long/path)

<!-- markdownlint-disable MD033 -->
<details>
  <summary>HTML details are sometimes necessary</summary>
  Content here
</details>
<!-- markdownlint-enable MD033 -->

**Rules for linting exceptions:**

- Use sparingly - fix the content first if possible
- Always include a comment explaining why the exception is needed
- Use `disable-next-line` for single line exceptions
- Use `disable`/`enable` pairs for multi-line exceptions
- Common scenarios:
  - `MD040`: Terminal output or intentionally unlabeled code blocks
  - `MD013`: Long URLs that shouldn't be broken
  - `MD033`: HTML elements when markdown syntax is insufficient
  - `MD046`: Mixed code fence styles in examples

### Tagging Standards

Use consistent tags for tracking tasks, issues, and important notes across both documentation and code.

#### Tag Types and Usage

| Tag | Purpose | Priority | Example |
|-----|---------|----------|---------|
| `TODO` | Future tasks or improvements | Medium | "Add error handling for edge cases" |
| `FIXME` | Broken code that needs fixing | High | "This breaks when input is null" |
| `BUG` | Known bugs that need resolution | High | "Returns incorrect value for negative numbers" |
| `HACK` | Temporary workaround that needs proper solution | Medium | "Using sleep() until proper event system is ready" |
| `WARNING` | Important cautions for other developers | Info | "Do not modify - external system dependency" |
| `NOTE` | Important information or context | Info | "This follows RFC-2119 specification" |
| `DEPRECATED` | Code/docs scheduled for removal | Low | "Use new_function() instead - removal in v2.0" |
| `SECURITY` | Security-related concerns | Critical | "Validate input to prevent SQL injection" |

#### Format Standards

**In Documentation (Markdown):**

```markdown
[TODO]: Description of task to complete
[FIXME]: This section has incorrect information about X
[WARNING]: Do not use this approach in production
[NOTE]: This follows the pattern established in RFC-2119
```

**In Code (Comments):**

```python
# TODO: Add retry logic for network failures
# FIXME: This breaks when count > 100
# WARNING: Do not modify - external dependency
# NOTE: Algorithm based on Dijkstra's shortest path
```

```yaml
# TODO: Add production configuration after testing
# HACK: Using hardcoded values until Vault integration is complete
```

#### Standards and Rules

**Format Requirements:**

- Documentation: `[TAG]:` (brackets, colon)
- Code: `# TAG:` (hash, space optional before tag, colon)
- Always include descriptive text after the tag
- Keep descriptions concise but complete
- Include ticket/issue numbers when applicable: `[TODO]: (PROJ-123) Implement feature`

**Placement:**

- Place tags at the relevant location in code/docs
- For multi-line issues, place tag on first line
- Group related tags together when possible

**Priority Guidelines:**

- `SECURITY` - Address immediately
- `FIXME`, `BUG` - Address in current sprint
- `TODO`, `HACK` - Address in next refactor
- `WARNING`, `NOTE` - Informational only
- `DEPRECATED` - Remove by stated deadline

#### Searching and Tracking

**Find all tags:**

```bash
# In documentation
rg '\[(TODO|FIXME|BUG|HACK|WARNING|NOTE|DEPRECATED|SECURITY)\]:'

# In code
rg '# (TODO|FIXME|BUG|HACK|WARNING|NOTE|DEPRECATED|SECURITY):'

# All tags project-wide
rg '(\[|# )(TODO|FIXME|BUG|HACK|WARNING|NOTE|DEPRECATED|SECURITY):'

# Specific tag type
rg '\[FIXME\]:|# FIXME:'
```

**Generate reports:**

```bash
# Count by type
rg '(\[|# )(TODO|FIXME|BUG|WARNING)' --no-filename | \
  sed -E 's/.*(\[|# )(TODO|FIXME|BUG|WARNING).*/\2/' | \
  sort | uniq -c

# List with file locations
rg '(\[|# )(TODO|FIXME|BUG)' --vimgrep
```

#### Examples

**Good Examples:**

```markdown
[TODO]: Add monitoring dashboard after Netdata deployment is complete
[FIXME]: This link is broken - should point to /docs/operations/runbooks.md
[WARNING]: Do not run this playbook in production without backup
```

```python
# TODO: (INFRA-456) Replace with dynamic configuration from Consul
# FIXME: Memory leak when processing > 1000 items - see issue #234
# HACK: Using subprocess because native library has threading bug
# NOTE: Keep in sync with Ansible role defaults in roles/consul/defaults/main.yml
```

**Bad Examples:**

```markdown
[TODO]: Fix this            # Too vague
TODO: Add tests             # Missing brackets
[TODO] Missing colon        # Wrong format
```

```python
# TODO                      # No description
# todo: lowercase           # Wrong case
#TODO: No space             # Missing space
```

#### Why Unified Tagging?

- **Consistency**: Same patterns in code and docs
- **Searchability**: Easy to find all issues project-wide
- **Prioritization**: Clear severity levels
- **Maintenance**: Systematic debt tracking
- **Onboarding**: New developers understand codebase state
- **Automation**: Can generate reports and metrics

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

```text
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

```text
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
1. **Categorize** - Determine correct location
1. **Move systematically** - One category at a time
1. **Update references** - Fix all links
1. **Archive old locations** - Leave forwarding notes

## References

- [Repository Structure](../getting-started/repository-structure.md)
- [Project README](../../README.md)
- CommonMark Specification
- Write the Docs principles
