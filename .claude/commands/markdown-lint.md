---
allowed-tools: Read, MultiEdit, Glob, Grep
argument-hint: [file-pattern]
description: Lint markdown files for formatting and style issues
---

# Markdown Linting

Analyze markdown files for formatting issues and fix them according to best practices.

## Scope

Files to lint: $ARGUMENTS (defaults to **/*.md if not specified)

## Linting Rules

I will check for and fix:

1. **Blank Lines**
   - Ensure fenced code blocks are surrounded by blank lines
   - Ensure lists are surrounded by blank lines
   - Remove multiple consecutive blank lines

2. **Code Blocks**
   - Ensure all fenced code blocks have a language specified
   - Fix indentation within code blocks

3. **Headings**
   - Ensure proper heading hierarchy (no skipping levels)
   - Add blank lines before headings
   - Use ATX-style headings (#) consistently

4. **Lists**
   - Consistent list markers (- for unordered, 1. for ordered)
   - Proper indentation for nested lists
   - Blank lines between list items with multiple paragraphs

5. **Line Length**
   - Warn about lines exceeding 120 characters (excluding code blocks)

6. **Trailing Spaces**
   - Remove trailing whitespace from all lines

## Process

1. Find all markdown files matching the pattern
2. Analyze each file for formatting issues
3. Report issues found with file paths and line numbers
4. Optionally fix issues automatically when confirmed
