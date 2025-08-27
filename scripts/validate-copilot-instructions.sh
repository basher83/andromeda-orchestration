#!/usr/bin/env bash
# Validation script for GitHub Copilot Instructions
# Tests the key procedures documented in .github/copilot-instructions.md

set -euo pipefail

echo "🤖 GitHub Copilot Instructions Validation"
echo "========================================="
echo ""

# Check if we're in the right directory
if [ ! -f ".mise.toml" ] || [ ! -f ".github/copilot-instructions.md" ]; then
    echo "❌ Error: Run this from the project root directory"
    exit 1
fi

echo "1. Tool Management Validation"
echo "-----------------------------"

# Check .mise.toml exists and has tools
if [ -f ".mise.toml" ]; then
    echo "✅ .mise.toml configuration exists"
    tool_count=$(grep -c "^[a-z].*=" .mise.toml || echo "0")
    echo "   - Found $tool_count tools configured"
else
    echo "❌ .mise.toml not found"
    exit 1
fi

# Check no binaries are committed
if find . -name nomad -type f -executable 2>/dev/null | grep -v ".venv" | head -1 >/dev/null; then
    echo "❌ Warning: Found nomad binary that might be committed"
else
    echo "✅ No nomad binaries found in repository"
fi

echo ""
echo "2. Python Environment Validation"
echo "--------------------------------"

# Check uv is available
if command -v uv >/dev/null || [ -x ".venv/bin/uv" ]; then
    echo "✅ uv is available"
    if [ -d ".venv" ]; then
        echo "✅ Virtual environment exists"
    else
        echo "⚠️  Virtual environment not found - run 'mise run setup' or 'uv sync'"
    fi
else
    echo "⚠️  uv not found - install with mise or manually"
fi

echo ""
echo "3. Ansible Environment Validation"
echo "---------------------------------"

if [ -f ".venv/bin/ansible" ] || command -v ansible >/dev/null; then
    echo "✅ Ansible is available"
    
    # Check collections
    collection_count=$(find ~/.ansible/collections/ansible_collections -name "MANIFEST.json" 2>/dev/null | wc -l)
    echo "   - $collection_count collections installed"
    
    # Test simple syntax check
    if echo '---
- hosts: localhost
  tasks:
    - debug: msg="test"' | .venv/bin/ansible-playbook --syntax-check /dev/stdin >/dev/null 2>&1; then
        echo "✅ Ansible syntax validation works"
    else
        echo "⚠️  Ansible syntax validation has issues (expected due to inventory)"
    fi
else
    echo "⚠️  Ansible not found - run 'mise run setup'"
fi

echo ""
echo "4. Project Structure Validation" 
echo "-------------------------------"

required_dirs=("playbooks" "inventory" "nomad-jobs" "roles")
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir directory exists"
    else
        echo "❌ $dir directory missing"
    fi
done

echo ""
echo "5. Documentation Validation"
echo "---------------------------"

if [ -f ".github/copilot-instructions.md" ]; then
    echo "✅ GitHub Copilot instructions exist"
    word_count=$(wc -w < .github/copilot-instructions.md)
    echo "   - $word_count words of documentation"
else
    echo "❌ GitHub Copilot instructions not found"
fi

# Check for key sections
key_sections=("Tool Installation with Mise" "Ansible Playbook Execution" "Nomad Job Management" "Performance Expectations")
missing_sections=()
for section in "${key_sections[@]}"; do
    if grep -q "$section" .github/copilot-instructions.md 2>/dev/null; then
        echo "✅ Documentation includes: $section"
    else
        missing_sections+=("$section")
    fi
done

if [ ${#missing_sections[@]} -eq 0 ]; then
    echo "✅ All key sections present in documentation"
else
    echo "⚠️  Missing sections: ${missing_sections[*]}"
fi

echo ""
echo "6. Quick Setup Test"
echo "------------------"

if command -v mise >/dev/null 2>&1; then
    echo "✅ mise is available - full setup possible"
    echo "   Run: mise run setup"
elif [ -f ".venv/bin/ansible" ]; then
    echo "✅ Environment appears functional"
    echo "   Run: uv run ansible --version"
else
    echo "⚠️  Need initial setup"
    echo "   Install mise first, then: mise run setup"
fi

echo ""
echo "🎯 Validation Summary"
echo "===================="

if [ -f ".mise.toml" ] && [ -f ".github/copilot-instructions.md" ] && [ -d "playbooks" ]; then
    echo "✅ Core project structure validated"
    echo "   Ready for GitHub Copilot/automated agent use"
    echo ""
    echo "💡 Quick start for new users:"
    echo "   1. Install mise: curl https://mise.run | sh"
    echo "   2. Setup project: mise run setup"
    echo "   3. Check status: mise run env:status"
else
    echo "❌ Project structure issues found"
    exit 1
fi