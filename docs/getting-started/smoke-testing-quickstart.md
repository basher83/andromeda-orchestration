# Smoke Testing Quick Start Guide

## What Are Smoke Tests?

Smoke tests are **mandatory validation checks** that verify all infrastructure prerequisites before running any production operations. Think of them as pre-flight checks for your infrastructure - they catch problems early before they can cause deployment failures.

## Why Smoke Tests?

Without smoke tests, you might:

- ❌ Run a playbook that fails halfway through, leaving infrastructure partially configured
- ❌ Waste time debugging authentication issues that could have been detected upfront
- ❌ Deploy to the wrong environment due to connectivity issues
- ❌ Cause outages by running operations without proper permissions

With smoke tests, you:

- ✅ Know immediately if something is wrong before making any changes
- ✅ Get specific, actionable error messages telling you exactly what to fix
- ✅ Save time by catching issues early
- ✅ Maintain consistent, reliable deployments

## Your First Smoke Test

### Step 1: Ensure Environment is Ready

```bash
# Check mise is installed and configured
mise --version

# Trust the project configuration
mise trust

# Load environment variables
eval "$(mise env)"
```

### Step 2: Run Your First Smoke Test

Let's start with the Vault smoke test (currently the only implemented one):

```bash
# Run the smoke test
mise run smoke-vault
```

You should see output like this:

```text
🔥 Running Vault smoke tests...
✅ PASSED: Infisical environment variables loaded
✅ PASSED: Can resolve vault-master-lloyd hostname
✅ PASSED: Can connect to vault-master-lloyd via SSH
[... more tests ...]
🎯 SMOKE TEST COMPLETE
✅ 12/12 tests passed
🚀 Vault infrastructure is ready for operations
```

### Step 3: Understanding the Output

Each test provides clear feedback:

- **✅ PASSED**: This prerequisite is met
- **❌ FAILED**: This prerequisite is NOT met - includes specific fix instructions
- **⚠️ WARNING**: Non-critical issue - may proceed with caution
- **ℹ️ INFO**: Informational message

## When to Run Smoke Tests

### ALWAYS Run Before

1. **Production Deployments**

   ```bash
   mise run smoke-vault
   # If passes, then:
   uv run ansible-playbook playbooks/infrastructure/vault/production-deploy.yml
   ```

2. **After Infrastructure Changes**

   ```bash
   # After restarting services
   mise run smoke-consul
   mise run smoke-nomad
   ```

3. **Starting Development Work**

   ```bash
   # Morning standup routine
   mise run smoke-vault
   mise run smoke-consul
   mise run smoke-nomad
   ```

4. **Troubleshooting Issues**

   ```bash
   # Something's not working? Start here:
   mise run smoke-vault-verbose
   ```

## Common Scenarios

### Scenario 1: Failed Infisical Authentication

**What you see:**

```text
❌ FAILED: Infisical environment variables not found. Check .mise.local.toml
```

**How to fix:**

```bash
# 1. Check your local configuration
cat .mise.local.toml

# 2. If missing, create it:
cat > .mise.local.toml << 'EOF'
[env]
INFISICAL_UNIVERSAL_AUTH_CLIENT_ID = "your-client-id"
INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET = "your-client-secret"
EOF

# 3. Reload environment
mise trust && eval "$(mise env)"

# 4. Retry smoke test
mise run smoke-vault
```

### Scenario 2: SSH Connectivity Issues

**What you see:**

```text
❌ FAILED: Cannot connect to vault-master-lloyd via SSH
```

**How to fix:**

```bash
# 1. Check SSH key is loaded
ssh-add -l

# 2. If not, add it
ssh-add ~/.ssh/id_ed25519

# 3. Verify Tailscale VPN is connected
tailscale status

# 4. Test manual connection
ssh ubuntu@vault-master-lloyd

# 5. Retry smoke test
mise run smoke-vault
```

### Scenario 3: Service Not Running

**What you see:**

```text
❌ FAILED: Vault service is not running on vault-master-lloyd
```

**How to fix:**

```bash
# 1. SSH to the server
ssh ubuntu@vault-master-lloyd

# 2. Check service status
sudo systemctl status vault

# 3. Start if needed
sudo systemctl start vault

# 4. Exit and retry smoke test
exit
mise run smoke-vault
```

## Developer Workflow Integration

### Pre-Commit Workflow

```bash
# Before committing infrastructure changes
mise run smoke-vault
git add .
git commit -m "feat: update vault configuration"
git push
```

### Pull Request Workflow

```yaml
# .github/workflows/pr-validation.yml
name: PR Validation
on: pull_request

jobs:
  smoke-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run smoke tests
        run: |
          mise run smoke-vault
          mise run smoke-consul
```

### Daily Development Routine

```bash
# Morning setup
cd ~/dev/andromeda-orchestration
git pull origin main
mise trust && eval "$(mise env)"
mise run smoke-vault

# Before lunch - quick validation
mise run smoke-vault

# End of day - ensure clean state
mise run smoke-vault
mise run smoke-consul
mise run smoke-nomad
```

## Creating Your Own Smoke Tests

If you're adding a new infrastructure component, you MUST create a smoke test:

### 1. Copy the Template

```bash
cp playbooks/infrastructure/vault/smoke-test.yml \
   playbooks/infrastructure/mycomponent/smoke-test.yml
```

### 2. Identify Test Categories

Your smoke test must include at least 10 categories:

- [ ] Environment variables loaded
- [ ] Network connectivity
- [ ] SSH access
- [ ] Service running
- [ ] API accessibility
- [ ] Authentication working
- [ ] Permissions verified
- [ ] Write operations possible
- [ ] Dependencies available
- [ ] Resource availability

### 3. Add mise Task

Edit `.mise.toml`:

```toml
[tasks.smoke-mycomponent]
description = "Run smoke tests for MyComponent"
run = '''
echo "🔥 Running MyComponent smoke tests..."
uv run ansible-playbook playbooks/infrastructure/mycomponent/smoke-test.yml \
      -i inventory/environments/mycomponent/production.yaml
'''
```

### 4. Test Your Test

```bash
# Run it
mise run smoke-mycomponent

# Run with verbosity
ANSIBLE_VERBOSITY=4 mise run smoke-mycomponent
```

### 5. Document It

Update:

- Component README
- This guide (if needed)
- Testing standards tracker

## Tips and Tricks

### Speed Up Tests

```bash
# Run only connectivity tests
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
      --tags connectivity

# Skip slow tests
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
      --skip-tags slow
```

### Debug Failures

```bash
# Maximum verbosity
ANSIBLE_VERBOSITY=4 mise run smoke-vault

# With extra variables
mise run smoke-vault-verbose
```

### Parallel Testing

```bash
# Test all components at once
parallel -j 3 ::: \
  "mise run smoke-vault" \
  "mise run smoke-consul" \
  "mise run smoke-nomad"
```

## Getting Help

### Quick Commands

```bash
# List all smoke test tasks
mise tasks | grep smoke

# Show help for a specific task
mise help smoke-vault

# Show available test tags
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml --list-tags
```

### Documentation

- [Testing Standards](../standards/testing-standards.md) - Why we require smoke tests
- [Operations Guide](../operations/smoke-testing-procedures.md) - Detailed procedures
- [Vault Smoke Test](../../playbooks/infrastructure/vault/smoke-test.yml) - Reference implementation

### Common Questions

**Q: How long should smoke tests take?**
A: Typically 30-60 seconds. If longer, consider optimizing or splitting tests.

**Q: Can I skip smoke tests?**
A: No. They're mandatory for production operations. You can skip for local development experimentation only.

**Q: What if a test fails but I know it's okay?**
A: Fix the test to handle your scenario properly. Never ignore failing tests.

**Q: Should I run smoke tests in CI/CD?**
A: Yes! They should be the first step in any deployment pipeline.

## Next Steps

1. ✅ Run your first smoke test: `mise run smoke-vault`
2. 📖 Read the [Testing Standards](../standards/testing-standards.md)
3. 🔧 Learn troubleshooting in the [Operations Guide](../operations/smoke-testing-procedures.md)
4. 🚀 Integrate smoke tests into your daily workflow
5. 📝 Help implement smoke tests for other components

Remember: **Always smoke test before production operations!**
