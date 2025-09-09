#!/bin/bash

# MegaLinter Diagnostic Script
# Helps identify which linter is causing hanging or slow performance

echo "🔬 MegaLinter Diagnostic Tool"
echo "============================="

# Check prerequisites
if ! command -v mega-linter-runner &> /dev/null; then
    echo "❌ mega-linter-runner not found. Install with: npm install -g mega-linter-runner"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker not running. Please start Docker first."
    exit 1
fi

echo "✅ Prerequisites met"
echo ""

# Test individual linter groups
declare -a tests=(
    "MARKDOWN:docs/**/*.md:Markdown files"
    "YAML:ansible/**/*.yml:Ansible YAML files"
    "JSON:ansible/**/*.json:JSON files"
    "TERRAFORM:infrastructure/**/*.tf:Terraform files"
    "BASH:scripts/**/*.sh:Shell scripts"
)

echo "🧪 Running diagnostic tests..."
echo "Each test targets a specific file type and linter group"
echo ""

for test in "${tests[@]}"; do
    IFS=':' read -r linter files description <<< "$test"

    echo "🔍 Testing $description ($linter)..."
    echo "   Files: $files"

    start_time=$(date +%s)

    # Run with 5-minute timeout per test
    timeout 300 mega-linter-runner \
        --flavor terraform \
        --remove-container \
        --enable-linters "$linter" \
        --files "$files" \
        2>&1 | grep -E "(ERROR|WARNING|✅|❌|completed)" | tail -3

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    if [ $duration -gt 120 ]; then
        echo "   ⚠️  SLOW: ${duration}s (might be the culprit)"
    elif [ $duration -gt 30 ]; then
        echo "   🟡 MODERATE: ${duration}s"
    else
        echo "   ✅ FAST: ${duration}s"
    fi

    echo ""
done

echo "📊 Diagnostic Summary:"
echo "======================"
echo "• Fast tests (< 30s): Likely not causing hangs"
echo "• Moderate tests (30-120s): Could contribute to slowdown"
echo "• Slow tests (> 120s): Likely causing the hanging"
echo ""
echo "💡 Recommendations:"
echo "• Skip slow linters temporarily: --disable-linters SHELLCHECK,TERRAFORM_TERRASCAN"
echo "• Test file subsets: --files \"docs/**/*.md\""
echo "• Check Docker resources and network connectivity"
echo "• Consider increasing Docker memory allocation"
