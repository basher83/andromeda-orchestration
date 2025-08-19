# Domain Migration PR Template

## PR #X: [Title]

**Branch**: `feat/[branch-name]`
**Epic**: #18
**Related Issues**: #[issue-numbers]

### Description

[Brief description of what this PR accomplishes]

### Changes Made

- [ ] File 1: [Description of change]
- [ ] File 2: [Description of change]
- [ ] File 3: [Description of change]

### Testing Performed

```bash
# Command 1
[output]

# Command 2
[output]
```

### Validation Checklist

- [ ] No .local references introduced
- [ ] Variables properly parameterized
- [ ] Tested from macOS client (if applicable)
- [ ] Backward compatible with existing setup
- [ ] Documentation updated

### Rollback Plan

[How to revert if issues arise]

### Dependencies

- Requires PR #[X] to be merged first
- Blocks PR #[Y]

### Screenshots/Evidence

[Include any relevant screenshots or command outputs]

### Notes for Reviewers

- Pay special attention to [specific area]
- Test on [specific environment]
- Known issue: [if any]

---

**Reviewer Checklist**:
- [ ] Code changes reviewed
- [ ] Testing evidence verified
- [ ] No .local references added
- [ ] Rollback plan adequate
- [ ] Dependencies resolved
