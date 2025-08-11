# Git Standards

## Purpose

Define version control practices that ensure clean history, meaningful commits, and effective collaboration using space-themed conventions that align with our Mission Control standards.

## Background

These git standards were developed to create a consistent, readable, and automated git workflow across all repositories in the basher83 ecosystem. They solve common problems like inconsistent commit messages, unclear branch purposes, and difficult-to-track project history. The space-themed approach makes git operations more engaging while maintaining professional standards.

## Standard

### Branch Naming Conventions

All branches follow a clear naming pattern that indicates their purpose and scope:

#### Feature Branches

- Pattern: `feature/<scope>-<description>`
- Example: `feature/auth-oauth-integration`
- Purpose: New functionality or capabilities

#### Fix Branches

- Pattern: `fix/<issue-number>-<description>`
- Example: `fix/123-login-timeout`
- Purpose: Bug fixes and corrections

#### Documentation Branches

- Pattern: `docs/<scope>-<description>`
- Example: `docs/api-endpoint-guide`
- Purpose: Documentation updates only

#### Chore Branches

- Pattern: `chore/<scope>-<description>`
- Example: `chore/deps-update-react`
- Purpose: Maintenance tasks, dependency updates

#### Experiment Branches

- Pattern: `experiment/<description>`
- Example: `experiment/new-caching-strategy`
- Purpose: Proof of concepts, not intended for direct merge

### Commit Message Format

All commits follow the space-themed conventional commit format:

```text
<emoji> <type>(<scope>): <description>

<body>

<footer>
```

**Required Components:**

- **Emoji**: Visual indicator for quick scanning
- **Type**: Category of change (feat, fix, docs, etc.)
- **Description**: Brief summary (50 characters or less)

**Optional Components:**

- **Scope**: Area of codebase affected
- **Body**: Detailed explanation (72 characters per line)
- **Footer**: Issue references, breaking changes

#### Commit Types and Emojis

**Primary Types:**

- `🎯 feat`: New features and capabilities
- `🐛 fix`: Bug fixes and corrections
- `📚 docs`: Documentation changes only
- `🎨 style`: Code style changes (formatting, etc.)
- `🔧 refactor`: Code refactoring without feature/bug changes
- `⚡ perf`: Performance improvements
- `✅ test`: Adding or modifying tests
- `🔨 build`: Build system or external dependencies
- `👷 ci`: CI/CD configuration changes
- `🧹 chore`: Maintenance tasks, no production code change

**Mission-Specific Types:**

- `🚀 deploy`: Deployment and release related
- `🛰️ config`: Configuration updates
- `🌟 enhance`: Improvements to existing features
- `🔒 security`: Security-related changes
- `🎨 design`: UI/UX specific changes
- `📊 analytics`: Tracking and analytics changes

### PR/MR Guidelines

**Pull Request Title Format:**

```text
🎯 feat(scope): Brief description of changes
```

**Pull Request Description Template:**

```markdown
## 🎯 Mission Objective
What problem does this PR solve?

## 🚀 Changes Made
- Change 1
- Change 2
- Change 3

## 🧪 Testing
How has this been tested?

## 📸 Screenshots (if applicable)
Visual evidence of changes

## 🔗 Related Issues
Closes: #123
Related: #456
```

**Review Requirements:**

- At least one approval required for main branch
- All CI checks must pass
- No merge conflicts
- Commits should be logically organized

### Merge Strategies

#### Feature Branches → Main

- Use **squash and merge** for features with many small commits
- Squashed commit message should follow commit format
- Include PR number in squashed commit

#### Release Branches → Main

- Use **merge commit** to preserve release history
- Ensure all commits in release branch follow standards

#### Hotfix Branches → Main

- Use **merge commit** for traceability
- Cherry-pick to other branches as needed

**Development Guidelines:**

- Rebase feature branches on main before creating PR
- Use interactive rebase to clean up commit history
- Never force push to main or shared branches

### Protected Branch Policies

**Main Branch Protection:**

- Require pull request reviews (minimum 1)
- Dismiss stale PR approvals on new commits
- Require status checks to pass:
  - CI/CD pipeline
  - Linting
  - Tests
  - Security scans
- Require branches to be up to date
- Include administrators in restrictions
- Prevent force pushes and deletions

**Additional Protected Branches:**

- `release/*` - Pre-production releases
- `hotfix/*` - Emergency fixes

## Rationale

These git practices were chosen over alternatives for several reasons:

1. **Space-themed emojis** provide instant visual recognition of commit types
2. **Conventional commits** enable automated changelog generation
3. **Branch naming patterns** make repository navigation intuitive
4. **Squash merging** keeps main branch history clean while preserving detail in PRs
5. **Protected branches** prevent accidental damage to critical code

## Examples

### Good Examples

**Feature Development:**

```bash
# Create feature branch
git checkout -b feature/user-profile-avatar

# Make commits
git commit -m "🎯 feat(profile): add avatar upload component"
git commit -m "✅ test(profile): add avatar upload tests"
git commit -m "📚 docs(profile): document avatar requirements"

# Clean up before PR
git rebase -i main
```

**Bug Fix with Investigation:**

```text
git commit -m "🐛 fix(auth): resolve session timeout on mobile

Investigation revealed token refresh logic was not triggering
on mobile browsers due to visibility API differences.

Implemented fallback timer for mobile devices and added
comprehensive test coverage for various browser scenarios.

Fixes: #234
Tested-on: iOS Safari, Android Chrome"
```

**Documentation Update:**

```text
git commit -m "📚 docs(api): add webhook endpoint documentation

- Document all webhook event types
- Add authentication requirements
- Include request/response examples
- Add rate limiting information

Co-authored-by: Jane Doe <jane@example.com>"
```

### Bad Examples

**What to Avoid:**

```bash
# Too vague
git commit -m "fix bug"

# Missing emoji and type
git commit -m "updated authentication"

# Too long first line
git commit -m "🎯 feat(dashboard): implement real-time updates with websockets and add status monitoring"

# Wrong emoji for type
git commit -m "🚀 fix(api): correct endpoint path"

# Multiple changes in one commit
git commit -m "🎯 feat(app): add login, fix navigation, update styles"
```

## Exceptions

These standards may be relaxed in the following scenarios:

1. **Personal experimental branches** - Not intended for merge
2. **Emergency hotfixes** - When immediate deployment is critical
3. **Third-party integrations** - When working with external repositories
4. **Generated commits** - From tools like Renovate or Dependabot (though they should be configured to follow standards where possible)

## Migration

### Cleaning Up Existing Git History

**For Recent Commits (not yet pushed):**

```bash
# Interactive rebase to clean up last 5 commits
git rebase -i HEAD~5

# Amend the most recent commit
git commit --amend -m "🎯 feat(scope): proper commit message"
```

**For Existing Branches:**

```bash
# Create clean branch from current work
git checkout -b feature/clean-history
git merge --squash feature/messy-branch
git commit -m "🎯 feat(scope): consolidated feature implementation"
```

**Repository-Wide Cleanup:**

1. Document existing commit patterns
2. Create migration plan for active branches
3. Update CI/CD to enforce new standards
4. Train team on new conventions
5. Use git hooks for automatic validation

### Git Configuration

**Set up commit template:**

```bash
# Copy template from Mission Control
cp /path/to/mission-control/boilerplate/gitmessage-template .gitmessage

# Configure git to use template
git config commit.template .gitmessage
```

**Install commit validation hook:**

```bash
# Create pre-commit hook
cat > .git/hooks/commit-msg << 'EOF'
#!/bin/sh
commit_regex='^(🎯|🐛|📚|🎨|🔧|⚡|✅|🔨|👷|🧹|🚀|🛰️|🌟|🔒|📊)\s(feat|fix|docs|style|refactor|perf|test|build|ci|chore|deploy|config|enhance|security|design|analytics)(\(.+\))?:\s.+$'

if ! grep -qE "$commit_regex" "$1"; then
    echo "❌ Invalid commit message format!"
    echo "Expected: <emoji> <type>(<scope>): <description>"
    echo "Example: 🎯 feat(auth): add user authentication"
    exit 1
fi
EOF

chmod +x .git/hooks/commit-msg
```

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Best Practices](https://git-scm.com/book/en/v2)
- [Mission Control Standards](https://github.com/basher83/docs/tree/main/mission-control)
- [Space-Themed Commit Conventions](https://github.com/basher83/docs/blob/main/flight-manuals/gitops/commit-conventions.md)
