# Pull Request Template

## PR #X: [Title]

**Branch**: `feat/[branch-name]`
**Epic**: #[epic-number]
**Related Issues**: #[issue-numbers]

---

## Summary

[Brief, clear description of what this PR accomplishes and why it's needed]

---

## What's In Scope ✅

### 1. [Primary Feature/Category]

- [Key change or implementation detail]
- [Key change or implementation detail]
- [Key change or implementation detail]

### 2. [Secondary Feature/Category]

- [Key change or implementation detail]
- [Key change or implementation detail]
- [Key change or implementation detail]

### 3. [Documentation/Standards]

- [Documentation updates or standards changes]
- [Documentation updates or standards changes]
- [Documentation updates or standards changes]

---

## What's NOT In Scope ❌

### Not Addressed in This PR

- **[Future work item]** - [Brief explanation why]
- **[Future work item]** - [Brief explanation why]
- **[Future work item]** - [Brief explanation why]

### Future Work Needed

1. [High-level future task]
2. [High-level future task]
3. [High-level future task]

---

## Testing

### Validation Results

```bash
# Test command 1
[command output or expected results]

# Test command 2
[command output or expected results]
```

### Linting & Quality Gates

```bash
# Lint validation
[linting command and results]

# Syntax validation
[syntax check command and results]
```

---

## Breaking Changes

⚠️ **Breaking Change Warning**: [Clear description of breaking changes]

**Migration Required:**

```yaml
# Before (old pattern)
[old code/example]

# After (new pattern)
[new code/example]
```

---

## Review Checklist

- [ ] **Code Quality**: Changes follow established patterns and standards
- [ ] **Testing**: All tests pass and new functionality is validated
- [ ] **Documentation**: README/docs updated with changes
- [ ] **Security**: No secrets or sensitive data exposed
- [ ] **Secrets Hygiene (Ansible)**: All sensitive tasks use `no_log: true`; no secrets in logs/artifacts
- [ ] **Secret Retrieval**: Centralized lookup tasks used; fallbacks validated; no inline lookups added
- [ ] **Performance**: Changes don't negatively impact performance
- [ ] **Breaking Changes**: Migration path documented if applicable

---

## Operational Impact & Risk

- Blast radius:
- Failure modes and mitigations:
- Change window/maintenance notice:

## Rollback Plan

- Trigger conditions:
- Rollback steps:
- Data/config implications:

---
---

## Dependencies

- **Requires**: PR #[X] to be merged first
- **Blocks**: PR #[Y]
- **Related**: #[issue-numbers]

---

## Screenshots/Evidence

[Include any relevant screenshots, command outputs, or evidence of testing]

---

## Notes for Reviewers

- **Pay special attention to**: [specific areas of concern]
- **Test on**: [specific environments or configurations]
- **Known issue**: [any known limitations or follow-ups]
- **Additional context**: [any other relevant information]

---

## Reviewer Checklist

- [ ] Code changes reviewed and approved
- [ ] Testing evidence verified
- [ ] Security implications assessed
- [ ] Documentation accuracy confirmed
- [ ] Breaking changes properly communicated

---

**Template Version**: 1.0 | **Last Updated**: 2025-09-18
