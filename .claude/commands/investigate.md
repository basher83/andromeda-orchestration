---
description: Create structured investigation for complex infrastructure issues
argument-hint: [issue-name]
---

# Create Investigation

Generate systematic investigation documentation for complex issues.

## Investigation Name

Issue: `$ARGUMENTS`

## Process

1. **Initialize**

`cp docs/troubleshooting/investigations/template.md docs/troubleshooting/investigations/$(date +%Y-%m-%d)-$ARGUMENTS.md`

Update tracking index: `docs/troubleshooting/investigations/INDEX.md`

1. **Document Issue**
   - Problem statement (clear, concise)
   - Initial symptoms (observed behaviors)
   - Affected components (primary/secondary)
   - Business impact (why it matters)

1. **Research Phase**
   - Initial investigation commands
   - Literature review (internal/external docs)
   - Form hypotheses with evidence
   - Design test plans

1. **Diagnosis Phase**
   - Systematic testing (validate hypotheses)
   - Document each test: objective, procedure, results
   - Root cause analysis
   - Identify contributing factors

1. **Resolution Phase**
   - Solution design with components
   - Risk assessment (HIGH/MEDIUM/LOW)
   - Implementation steps with commands
   - Rollback plans for each step

1. **Validation**
   - Functional testing (verify fix works)
   - Regression testing (verify nothing broke)
   - Document test results (PASSED/FAILED)

1. **Documentation**
   - Files created/modified
   - Lessons learned
   - Prevention measures
   - Target permanent doc location

## Status Tracking

Update status as progressing:

- 🆕 NEW → 🔍 INVESTIGATING → 🎯 DIAGNOSED → ✅ RESOLVED → 📚 DOCUMENTED

## Completion

When resolved, create permanent guide:

`docs/troubleshooting/[category]/[issue]-guide.md`
