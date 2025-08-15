# Linting Workflow Improvements Proposal

## Current State Analysis

### What Works Well

- **lint-master** coordinator effectively delegates to specialized agents
- **commit-craft** discovered and used `claude markdown-lint` command autonomously
- Specialized agents understand tool invocation patterns (uv run vs direct)
- Good separation of concerns between different linting domains

### Pain Points Observed

1. **Markdown linting gap**: No specialized markdown-linter agent, handled ad-hoc
2. **Discovery friction**: Agents had to discover `claude markdown-lint` exists
3. **Fix coordination**: Manual intervention needed between linting and committing
4. **Reporting inconsistency**: Different output formats across linters

## Proposed Improvements

### 1. Create markdown-linter Agent

```yaml
---
name: markdown-linter
description: Use for markdown documentation validation - runs markdownlint-cli2 and claude markdown-lint
tools: Bash, Read, Edit, MultiEdit, Glob
color: purple
---

# Purpose
Specialist for markdown documentation quality, formatting, and consistency.

## Capabilities
- Run markdownlint-cli2 via pre-commit
- Use claude markdown-lint for Claude-specific checks
- Auto-fix common violations
- Validate links and references
- Check code block languages
- Ensure consistent heading structure

## Tool Awareness
- `uv run pre-commit run markdownlint-cli2` - Python environment
- `claude markdown-lint` - Claude CLI built-in
- `markdownlint-cli2 --fix` - Direct if installed globally
```

### 2. Enhanced Slash Commands

#### /lint Command Suite

```bash
# Comprehensive linting with automatic fixes
/lint --fix

# Specific file type linting
/lint --python
/lint --ansible
/lint --markdown
/lint --yaml
/lint --shell
/lint --hcl

# Progressive profile testing
/lint --profile=moderate
/lint --profile=production

# Pre-commit simulation
/lint --pre-commit

# Generate linting report
/lint --report
```

#### Implementation in .claude/commands/lint.md

```markdown
---
name: lint
description: Run comprehensive or targeted linting with optional auto-fix
tools: Task
---

# Purpose
Streamline linting workflow with intelligent defaults and progressive fixes.

## Instructions

Parse user flags to determine scope:
- No flags: Run lint-master for comprehensive check
- --fix: Run with auto-fix enabled
- --[type]: Delegate to specific linter agent
- --profile: Test ansible-lint profile progression
- --report: Generate comprehensive linting report

## Smart Features
1. Auto-detect changed files since last commit
2. Prioritize fixing errors over warnings
3. Group similar violations for batch fixing
4. Create atomic commits for fixes if requested
```

### 3. Linting Pipeline Agent

```yaml
---
name: lint-pipeline
description: Orchestrates complete linting workflow from detection to commit
tools: Task, Bash, TodoWrite
---

# Purpose
End-to-end linting workflow automation with minimal user intervention.

## Workflow Stages
1. **Discovery**: Identify changed files
2. **Analysis**: Run appropriate linters
3. **Auto-fix**: Apply safe automatic fixes
4. **Validation**: Verify fixes don't break anything
5. **Commit**: Create atomic commits for fixes
6. **Report**: Summarize actions taken

## Intelligence Features
- Learn from previous fixes
- Suggest configuration improvements
- Track linting debt metrics
- Recommend profile progression timing
```

### 4. Integrated Linting Dashboard

Create a `/lint-status` command that shows:

```markdown
## Linting Status Dashboard

### Current Profile: moderate (Week 3 of progression)

### Violations by Type
| Type | Count | Auto-fixable | Priority |
|------|-------|--------------|----------|
| Ansible FQCN | 391 | Yes (350) | High |
| YAML formatting | 45 | Yes | Medium |
| Markdown style | 0 | - | Complete ✅ |
| Python style | 12 | Yes (10) | Low |
| Shell issues | 8 | No | High |

### Next Actions
1. Run `/lint --fix --ansible` to fix 350 FQCN issues
2. Review 41 manual FQCN fixes needed
3. Consider progression to 'safety' profile next week

### Recent Linting History
- 2025-08-15: Fixed 163 markdown violations ✅
- 2025-08-15: Created linting integration guide ✅
- 2025-08-14: Identified 391 ansible-lint violations
```

### 5. Smart Fix Strategies

#### Batch Processing Mode

```python
# Pseudo-code for intelligent batch fixing
class SmartLintFixer:
    def fix_by_pattern(self):
        """Group similar violations and fix in batches"""
        violations = self.analyze_all()

        # Group by fix pattern
        patterns = {
            'fqcn': [],
            'spacing': [],
            'quotes': [],
            'deprecated': []
        }

        # Apply fixes in order of safety
        for pattern in ['spacing', 'quotes', 'fqcn', 'deprecated']:
            if self.apply_pattern_fix(pattern):
                self.validate_changes()
                self.create_commit(pattern)
```

#### Progressive Fix Mode

```bash
#!/bin/bash
# progressive-lint-fix.sh

# Stage 1: Format-only fixes (safest)
echo "Stage 1: Formatting fixes..."
/lint --fix --formatting-only

# Stage 2: FQCN and naming
echo "Stage 2: Naming convention fixes..."
/lint --fix --naming

# Stage 3: Best practices
echo "Stage 3: Best practice fixes..."
/lint --fix --best-practices

# Stage 4: Security and safety
echo "Stage 4: Security fixes..."
/lint --fix --security
```

### 6. Lint Configuration Generator

```yaml
---
name: lint-config-generator
description: Generate optimal linting configuration based on codebase analysis
tools: Read, Write, Grep, Glob
---

# Purpose
Analyze codebase and generate tailored linting configurations.

## Capabilities
- Detect current code patterns
- Suggest appropriate starting profile
- Generate ignore files for legacy code
- Create migration timeline
- Propose custom rules based on patterns
```

### 7. Integration with Mise

Since we're migrating to Mise (Issue #62), integrate linting into task definitions:

```toml
# .mise.toml
[tasks.lint]
description = "Run comprehensive linting"
run = "claude lint"

[tasks."lint:fix"]
description = "Lint with auto-fix"
run = "claude lint --fix"

[tasks."lint:ci"]
description = "CI-compatible linting"
run = """
  claude lint --profile=production --no-fix || exit 1
  echo "All linting checks passed!"
"""

[tasks."lint:report"]
description = "Generate linting report"
run = "claude lint --report > reports/linting-$(date +%Y%m%d).md"
```

## Implementation Priority

### Phase 1: Quick Wins (Week 1)

1. ✅ Create markdown-linter agent
2. ✅ Add /lint slash command
3. ✅ Integrate with Mise tasks

### Phase 2: Automation (Week 2)

1. ⏳ Implement lint-pipeline agent
2. ⏳ Add smart fix strategies
3. ⏳ Create /lint-status dashboard

### Phase 3: Intelligence (Week 3)

1. ⏳ Build lint-config-generator
2. ⏳ Add learning capabilities
3. ⏳ Implement progressive fixing

## Success Metrics

- **Time to fix**: Reduce from 30min to 5min for common violations
- **Auto-fix rate**: Increase from 60% to 90%
- **Profile progression**: Move from none to production in 8 weeks
- **Developer satisfaction**: Less context switching, more automation
- **CI pass rate**: Increase from 60% to 100%

## Example Workflow

```bash
# Developer workflow
$ git pull origin main
$ claude lint-status  # Quick check
> 45 new violations detected in changed files

$ claude lint --fix  # Auto-fix everything possible
> Fixed 42/45 violations automatically
> Created 3 commits for fixes

$ claude lint --report  # See what's left
> 3 manual fixes required in security-critical sections

# Ready for PR
$ git push origin feature-branch
```

## Conclusion

The key improvements focus on:

1. **Closing gaps** - Adding markdown-linter agent
2. **Reducing friction** - Slash commands for common workflows
3. **Increasing automation** - Pipeline agent for end-to-end workflow
4. **Adding intelligence** - Smart fixing strategies and learning
5. **Improving visibility** - Dashboard and reporting

This creates a more cohesive, automated, and intelligent linting workflow that reduces developer burden while improving code quality.
