#!/bin/bash
# Test script for validating act setup for Andromeda IaC repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔍 Testing act setup for Andromeda IaC repository"
echo "================================================"
echo

cd "$REPO_ROOT"

# Check if act is available
echo "📋 Prerequisites Check:"
echo "-----------------------"

if command -v act &> /dev/null; then
    echo "✅ act: $(act --version)"
else
    echo "❌ act: Not installed"
    echo "   Install with: mise install act"
    echo "   Or visit: https://github.com/nektos/act"
    exit 1
fi

# Check Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker: $(docker --version)"
else
    echo "❌ Docker: Not available"
    echo "   Docker is required for act to run"
    exit 1
fi

echo

# Check configuration files
echo "📁 Configuration Files:"
echo "----------------------"

config_files=(".actrc" ".env.act" ".github/workflows/event.json")
for config in "${config_files[@]}"; do
    if [ -f "$config" ]; then
        echo "✅ $config: Found"
    else
        echo "❌ $config: Missing"
    fi
done

echo

# Check workflows
echo "🔄 Available Workflows:"
echo "----------------------"

if [ -d ".github/workflows" ]; then
    workflows=$(find .github/workflows -name "*.yml" -o -name "*.yaml" | sort)
    if [ -n "$workflows" ]; then
        echo "$workflows" | while read -r workflow; do
            echo "✅ $(basename "$workflow")"
        done
    else
        echo "❌ No workflow files found"
    fi
else
    echo "❌ .github/workflows directory not found"
fi

echo

# Test basic act functionality
echo "🧪 Basic act Test:"
echo "-----------------"

echo "Testing act --list..."
if act --list >/dev/null 2>&1; then
    echo "✅ act --list: Working"
else
    echo "❌ act --list: Failed"
fi

echo

# Show available jobs for CI workflow
echo "📋 Available Jobs in CI Workflow:"
echo "---------------------------------"

if act --list | grep -A 20 "Job name:" | head -20; then
    echo
else
    echo "❌ Could not list workflow jobs"
fi

echo "💡 Usage Examples:"
echo "=================="
echo
echo "# Test MegaLinter only"
echo "act -j lint-and-quality"
echo
echo "# Test with pull request event"
echo "act pull_request"
echo
echo "# Test with push to main"
echo "act push -e .github/workflows/event.json"
echo
echo "# Test with specific workflow"
echo "act -W .github/workflows/ci.yml"
echo
echo "# Test with verbose output"
echo "act -v"
echo
echo "# Use mise tasks instead (recommended)"
echo "mise run act-quick    # Fast MegaLinter test"
echo "mise run act-full     # Full MegaLinter test"
echo "mise run act-ansible  # Test Ansible linters only"
echo

echo "✅ act setup test completed!"
