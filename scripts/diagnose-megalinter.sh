#!/bin/bash
# MegaLinter Performance Diagnostics Script
# Analyzes MegaLinter performance and provides optimization recommendations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔍 MegaLinter Performance Diagnostics"
echo "======================================"
echo "Repository: $REPO_ROOT"
echo "Date: $(date)"
echo

cd "$REPO_ROOT"

# Check prerequisites
echo "📋 Prerequisites Check:"
echo "-----------------------"

# Docker check
if command -v docker &> /dev/null; then
    echo "✅ Docker: $(docker --version)"
else
    echo "❌ Docker: Not installed or not in PATH"
fi

# uv check
if command -v uv &> /dev/null; then
    echo "✅ uv: $(uv --version)"
else
    echo "❌ uv: Not installed"
fi

# Configuration files check
config_files=(".mega-linter.yml" ".yamllint" ".ansible-lint" ".markdownlint.json" "pyproject.toml")
for config in "${config_files[@]}"; do
    if [ -f "$config" ]; then
        echo "✅ $config: Found"
    else
        echo "❌ $config: Missing"
    fi
done

echo

# Repository statistics
echo "📊 Repository Statistics:"
echo "------------------------"

# File counts by type
echo "File counts:"
echo "  Ansible/YAML files: $(find . -name "*.yml" -o -name "*.yaml" | wc -l)"
echo "  Python files: $(find . -name "*.py" | wc -l)"
echo "  Markdown files: $(find . -name "*.md" | wc -l)"
echo "  Nomad files: $(find . -name "*.nomad" -o -name "*.hcl" | wc -l)"
echo "  Shell scripts: $(find . -name "*.sh" | wc -l)"
echo "  Total files: $(find . -type f | wc -l)"

echo

# Performance analysis
echo "⚡ Performance Analysis:"
echo "----------------------"

# Check current MegaLinter configuration
if [ -f ".mega-linter.yml" ]; then
    echo "Current configuration:"
    grep -E "^(PARALLEL|PARALLEL_PROCESS_COUNT|LOG_LEVEL|PRINT_ALL_FILES)" .mega-linter.yml || echo "  No performance settings found"

    echo
    echo "Enabled linters:"
    grep "ENABLE_LINTERS:" -A 10 .mega-linter.yml | grep "-" | sed 's/.*- //' | while read -r linter; do
        echo "  - $linter"
    done
fi

echo

# Recommendations
echo "💡 Recommendations:"
echo "------------------"

# File size analysis
large_files=$(find . \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) -print0 | xargs -0 wc -l | awk '$1 > 1000 {print $2 ": " $1 " lines"}')
if [ -n "$large_files" ]; then
    echo "⚠️  Large files detected (may slow down linting):"
    echo "$large_files"
    echo
fi

# Check for excluded paths
excluded_paths=$(grep "FILTER_REGEX_EXCLUDE" .mega-linter.yml | sed 's/.*FILTER_REGEX_EXCLUDE: //' | tr -d "'\"")
echo "📁 Current exclusions: $excluded_paths"

# Check for included paths
included_paths=$(grep "FILTER_REGEX_INCLUDE" .mega-linter.yml | sed 's/.*FILTER_REGEX_INCLUDE: //' | tr -d "'\"")
echo "🎯 Current inclusions: $included_paths"

echo

# Performance tips
echo "🚀 Performance Optimization Tips:"
echo "----------------------------------"
echo "1. Use conditional fast mode: Skip slow linters on dev branches"
echo "2. Enable parallel processing: PARALLEL_PROCESS_COUNT: 4"
echo "3. Use smart filtering: Only lint relevant file types"
echo "4. Cache dependencies: Ansible collections and Python packages"
echo "5. Monitor timeouts: Set appropriate timeout limits per linter"
echo "6. Use LOG_LEVEL: INFO to reduce verbose output"
echo "7. Consider file size limits for very large files"

echo

# Branch-specific recommendations
echo "🌿 Branch-Specific Recommendations:"
echo "-----------------------------------"
echo "Main branch: Run all linters for production quality"
echo "Dev branches: Skip slow linters (TRIVY, GITLEAKS) for faster feedback"
echo "Feature branches: Use fast mode with relaxed error handling"

echo

# Test run simulation
echo "🧪 Test Run Simulation:"
echo "----------------------"

if command -v docker &> /dev/null && [ -f ".mega-linter.yml" ]; then
    echo "Running quick validation test..."
    timeout 30 docker run --rm \
        -v "$PWD:/tmp/lint" \
        -w "/tmp/lint" \
        oxsecurity/megalinter:v8 \
        --config-file .mega-linter.yml \
        --linters-filter ANSIBLE_ANSIBLE_LINT,YAML_YAMLLINT \
        --files-only \
        2>/dev/null | grep -E "(SUCCESS|FAILED|Error)" | head -5 || echo "Quick test completed"

    echo
    echo "For full performance analysis, run:"
    echo "  time ./scripts/test-megalinter.sh"
else
    echo "Prerequisites not met for test run"
fi

echo
echo "✅ Diagnostics complete!"
echo
echo "💡 Run 'time ./scripts/test-megalinter.sh' to measure actual performance"
