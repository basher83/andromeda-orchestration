#!/bin/bash
# MegaLinter Auto-Fix Script with Backup System
# Safely applies MegaLinter auto-fixes with backup and rollback capabilities

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
BACKUP_DIR="$REPO_ROOT/.megalinter-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

echo "🔧 MegaLinter Auto-Fix with Backup"
echo "==================================="
echo "Repository: $REPO_ROOT"
echo "Backup location: $BACKUP_PATH"
echo

cd "$REPO_ROOT"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to create backup
create_backup() {
    echo "📦 Creating backup of current state..."

    # Find files that will be modified by MegaLinter auto-fix
    # This includes YAML and Markdown files
    FILES_TO_BACKUP=$(find . -name "*.yml" -o -name "*.yaml" -o -name "*.md" | grep -v ".megalinter-backups" | head -20)

    if [ -n "$FILES_TO_BACKUP" ]; then
        mkdir -p "$BACKUP_PATH"

        # Copy files to backup
        echo "$FILES_TO_BACKUP" | while read -r file; do
            if [ -f "$file" ]; then
                backup_file="$BACKUP_PATH/${file#./}"
                mkdir -p "$(dirname "$backup_file")"
                cp "$file" "$backup_file"
                echo "  Backed up: $file"
            fi
        done

        echo "✅ Backup created successfully"
        echo "   To restore: cp -r $BACKUP_PATH/* ./"
        echo
    else
        echo "ℹ️  No files found that would be modified by auto-fix"
        echo
    fi
}

# Function to run MegaLinter fix
run_fix() {
    echo "🔧 Running MegaLinter auto-fix..."

    # Run only the formatters that can auto-fix
    docker run --rm \
        -v "$PWD:/tmp/lint" \
        -w "/tmp/lint" \
        oxsecurity/megalinter:v8 \
        --config-file .mega-linter.yml \
        --linters-filter YAML_PRETTIER,MARKDOWN_MARKDOWNLINT \
        --fix
}

# Function to show changes
show_changes() {
    echo "📋 Changes applied:"
    echo "-------------------"

    if [ -d "$BACKUP_PATH" ]; then
        # Compare backed up files with current state
        find "$BACKUP_PATH" -type f | while read -r backup_file; do
            original_file="${backup_file#$BACKUP_PATH/}"
            if [ -f "$original_file" ]; then
                if ! diff -q "$backup_file" "$original_file" >/dev/null 2>&1; then
                    echo "  Modified: $original_file"
                fi
            fi
        done
    fi

    echo
}

# Function to cleanup old backups
cleanup_old_backups() {
    echo "🧹 Cleaning up old backups..."

    # Keep only last 10 backups
    ls -t "$BACKUP_DIR" | tail -n +11 | while read -r old_backup; do
        rm -rf "${BACKUP_DIR:?}/$old_backup"
        echo "  Removed: $old_backup"
    done

    echo "✅ Cleanup completed"
    echo
}

# Main execution
echo "Starting auto-fix process..."
echo

# Step 1: Create backup
create_backup

# Step 2: Run auto-fix
run_fix

# Step 3: Show changes
show_changes

# Step 4: Cleanup
cleanup_old_backups

echo "✅ Auto-fix completed!"
echo
echo "💡 Tips:"
echo "   - Review the changes before committing"
echo "   - Test your changes to ensure they work correctly"
echo "   - If issues occur, restore from backup: cp -r $BACKUP_PATH/* ./"
echo "   - Run full linting to check remaining issues: ./scripts/test-megalinter.sh"
echo
echo "📂 Backup location: $BACKUP_PATH"
