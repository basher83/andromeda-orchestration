# Task Completion Checklist

When completing any development task in this project, follow these steps:

## 1. Code Quality Checks
```bash
# Run all linters
task lint

# Fix any auto-fixable issues
task fix

# Ensure no linting errors remain
```

## 2. Test Your Changes
```bash
# Check playbook syntax
ansible-playbook <your-playbook>.yml --syntax-check

# Test with --check mode first
./bin/ansible-connect playbook <your-playbook>.yml --check

# Run the playbook in a test environment if possible
```

## 3. Security Verification
```bash
# Run security scan
task security

# Ensure no secrets are hardcoded
rg -i "password|token|secret" --glob "!*.md" --glob "!*example*"
```

## 4. Documentation Updates
- Update relevant documentation in `docs/`
- Update CLAUDE.md if the project focus changes
- Add/update playbook comments and examples
- Update the implementation plan checklist if working on DNS/IPAM

## 5. Pre-commit Hooks
```bash
# Run all pre-commit hooks
task hooks
```

## 6. Git Workflow
```bash
# Check your changes
git status
git diff

# Commit with descriptive message
git add .
git commit -m "feat: add consul health check playbook for phase 0 assessment"

# Push to feature branch (not directly to main)
git push origin feature/dns-ipam-phase-0
```

## 7. Validation
- Verify the playbook runs successfully
- Check that the output/reports are generated as expected
- Test rollback procedures if applicable
- Document any issues or gotchas discovered