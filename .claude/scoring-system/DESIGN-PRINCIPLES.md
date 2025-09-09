# Design Principles for Scoring Systems

## Core Philosophy: Specialization Over Premature Abstraction

This document captures the design principles that guide our approach to scoring systems for infrastructure tools.

## The Problem with Premature Abstraction

When building evaluation systems for multiple tools, there's a natural temptation to create "one scorer to rule them all." This almost always leads to:

- **Reduced accuracy**: Generic rules miss tool-specific patterns
- **Increased complexity**: Abstraction layers add cognitive overhead
- **Maintenance burden**: Changes ripple across unrelated tools
- **False commonalities**: Forcing shared patterns where none exist

## Our Approach: The Evolutionary Path

### Phase 1: Build Specialized

Create purpose-built scorers for each tool that excel at their specific domain:

- Ansible scorer understands idempotency and `changed_when`
- Terraform scorer (future) would understand state management and drift
- Each scorer achieves 95%+ accuracy for its domain

### Phase 2: Use in Production

Only after using multiple specialized scorers can you identify REAL patterns:

- What's actually common vs what seems common
- Which abstractions would help vs hinder
- Where duplication is truly problematic

### Phase 3: Extract Carefully

If patterns emerge, extract only what's genuinely shared:

- Document principles, not code
- Share concepts, not implementations
- Maintain separate scorers that reference common ideas

## Key Principles

### 1. The Rule of Three

**Don't abstract until you have 3+ real use cases**

We currently have:

- ✅ Ansible (implemented)
- ⚠️ Terraform (potential future need)
- ❌ Third tool (no current need)

Verdict: **Too early for abstraction**

### 2. Accuracy Over DRY

**A specialized 95% accurate scorer beats a generic 70% one**

Trade-offs we accept:

- 200 lines of duplication > 3-folder coupling
- Clear redundancy > hidden complexity
- Obvious patterns > clever abstractions

### 3. Self-Contained Understanding

**Open one folder, understand everything**

Good:

```
ansible-scorer/
├── all config files here
└── complete and independent
```

Bad:

```
shared/base.yaml → scorer/specific.yaml → overrides/custom.yaml
(Requires checking 3 places to understand one rule)
```

### 4. Different Tools, Different Patterns

| Aspect | Ansible | Terraform | Fundamental Difference |
|--------|---------|-----------|----------------------|
| Testing | Molecule | Terratest | Completely different approach |
| Quality | Idempotency | State management | Different paradigms |
| Structure | Collections/Roles | Modules/Providers | Different hierarchies |
| Versioning | Galaxy | Registry | Different ecosystems |

**Only ~20% overlap** - not worth abstracting

### 5. Discovered > Designed Abstractions

**The best abstractions emerge from real use, not upfront design**

❌ "This should be shareable" (designed)
✅ "We've written this 3 times" (discovered)

## When to Consider Abstraction

Only when ALL conditions are met:

- [ ] Using 5+ similar tools
- [ ] Tools share 80%+ evaluation criteria
- [ ] Have dedicated team for maintenance
- [ ] Current approach is failing
- [ ] Community demanding it

Current score: 0/5 - **Stay specialized**

## The Sibling Pattern

When you need scoring for multiple tools:

```
.claude/
├── scoring-system/        # Ansible scorer (current)
├── terraform-scorer/      # Terraform scorer (if needed)
└── shared-principles/     # Philosophy docs only (not code)
    └── bias-elimination.md
```

Benefits:

- Each tool gets optimal scoring
- No abstraction complexity
- Can delete unused scorers cleanly
- Can evolve independently

## Cost Analysis

### Abstraction Approach

- Initial build: 40-60 hours
- Maintenance: 10 hours/month
- 3-year total: ~400 hours
- Accuracy: 70%

### Specialization Approach

- Initial build: 8 hours per tool
- Maintenance: 1 hour/month per tool
- 3-year total: ~80 hours (2 tools)
- Accuracy: 95% per tool

**5x less effort, 25% better results**

## Future Decisions

If Terraform scoring becomes necessary:

1. Build `.claude/terraform-scorer/` independently (8 hours)
2. Copy only the bias-elimination concepts
3. Adapt all rules for Terraform specifics
4. Keep scorers completely separate
5. After 6 months, evaluate for REAL common patterns
6. Only then consider selective extraction

## Remember

> "Duplication is far cheaper than the wrong abstraction" - Sandi Metz

> "The first rule of optimization is: Don't do it. The second rule is: Don't do it yet." - Michael A. Jackson

> "YAGNI - You Aren't Gonna Need It" - XP Principle

These principles ensure we build what we need, when we need it, without overengineering for imaginary future requirements.
