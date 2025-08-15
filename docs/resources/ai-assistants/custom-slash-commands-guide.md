# Custom Slash Commands Guide

This guide documents the custom slash commands available in the andromeda-orchestration project, including meta commands, generators, and task-specific commands.

## Overview

Custom slash commands are reusable prompts stored as Markdown files in `.claude/commands/`. They enable consistent, efficient workflows and can be shared across teams.

## Command Hierarchy

```
/slash-meta (creates meta commands)
    ├── /meta-*-factory (creates generators)
    │   └── /*-generator (creates task commands)
    │       └── /task-command (performs specific tasks)
    └── /slash-generator (creates task commands directly)
```

## Available Commands

### 1. `/slash-meta` - True Meta Command Generator

**Purpose**: Creates slash commands that can themselves generate other commands, enabling recursive command creation.

**Syntax**: `/slash-meta <generator-type> <domain> [recursive]`

**Parameters**:

- `generator-type`: Type of meta command to create (`factory`, `generator`, `builder`)
- `domain`: The domain or focus area for the generator
- `recursive`: Optional flag to enable recursive generation capabilities

**Usage Examples**:

```bash
# Create a testing command factory with recursive capabilities
> /slash-meta factory "testing commands" recursive

# Create an infrastructure command generator
> /slash-meta generator "infrastructure automation" recursive

# Create a documentation builder (non-recursive)
> /slash-meta builder "documentation"
```

**What it creates**:

- Commands with Write, Read, LS permissions
- Built-in command generation logic
- Optional recursive generation capability
- Follows pattern: `/meta-<domain>-<type>`

### 2. `/meta-example-factory` - Example Meta Factory

**Purpose**: Demonstrates meta command capabilities by creating commands that can generate more commands.

**Syntax**: `/meta-example-factory <command-name> <purpose> [sub-generators]`

**Parameters**:

- `command-name`: Name for the new command
- `purpose`: Description of what the command does
- `sub-generators`: Boolean flag for recursive capability

**Usage Examples**:

```bash
# Create a test generator that can create more generators
> /meta-example-factory test-generator "creates testing commands" true

# Create a linting command factory
> /meta-example-factory lint-factory "creates linting commands" true

# Create a simple task command
> /meta-example-factory deploy-check "validates deployment readiness" false
```

### 3. `/slash-generator` - Simple Command Generator

**Purpose**: Creates end-point slash commands for specific tasks (non-meta).

**Syntax**: `/slash-generator <command-name> <command-purpose>`

**Parameters**:

- `command-name`: Name for the new command
- `command-purpose`: Description of the command's function

**Usage Examples**:

```bash
# Create a markdown linting command
> /slash-generator markdown-lint "lint markdown files for formatting issues"

# Create a security scanning command
> /slash-generator security-scan "scan code for security vulnerabilities"

# Create a test runner command
> /slash-generator test-runner "run tests and fix failures"
```

**What it creates**:

- Task-specific commands with minimal permissions
- Cannot create other commands
- Optimized for single-purpose tasks

### 4. `/markdown-lint` - Markdown Linting Command

**Purpose**: Analyzes and fixes markdown formatting issues.

**Syntax**: `/markdown-lint [file-pattern]`

**Parameters**:

- `file-pattern`: Optional glob pattern for files to lint (defaults to **/*.md)

**Usage Examples**:

```bash
# Lint all markdown files
> /markdown-lint

# Lint specific directory
> /markdown-lint docs/**/*.md

# Lint single file
> /markdown-lint README.md
```

**What it checks**:

- Blank lines around code blocks and lists
- Language specifiers in code blocks
- Heading hierarchy
- Trailing spaces
- Line length warnings

### 5. `/prime` - Context Loading Command

**Purpose**: Loads essential project context by examining codebase structure and documentation.

**Syntax**: `/prime`

**Usage Example**:

```bash
# Load project context at start of session
> /prime
```

**What it does**:

- Runs `git ls-files` to understand structure
- Reads README.md and key documentation
- Provides concise project overview

### 6. `/all-tools` - Tool Listing Command

**Purpose**: Lists all available tools in TypeScript function signature format.

**Syntax**: `/all-tools`

**Usage Example**:

```bash
# List all available tools
> /all-tools
```

## Creating New Commands

### Method 1: Using Meta Commands (Recursive)

```bash
# Step 1: Create a domain-specific factory
> /slash-meta factory "ansible playbooks" recursive

# Step 2: Use the factory to create generators
> /meta-ansible-playbooks-factory playbook-generator "creates ansible playbooks" true

# Step 3: Use generators to create specific commands
> /ansible-playbook-generator deploy-nomad "deploy nomad jobs via ansible"
```

### Method 2: Using Simple Generator (Direct)

```bash
# Create a single-purpose command directly
> /slash-generator ansible-lint "lint ansible playbooks for best practices"
```

### Method 3: Manual Creation

```bash
# Create command file manually
echo '---
allowed-tools: Read, Grep
description: Find TODO comments
---

Find all TODO comments in the codebase and organize by priority.' > .claude/commands/find-todos.md

# Use the command
> /find-todos
```

## Best Practices

### 1. Naming Conventions

- Use descriptive, action-oriented names
- Follow patterns:
  - Meta commands: `/meta-<domain>-<type>`
  - Generators: `/<domain>-generator`
  - Task commands: `/<action>-<target>`

### 2. Tool Permissions

- **Meta commands**: Need Write, Read, LS minimum
- **Generators**: Usually Write, Read, LS
- **Task commands**: Minimal permissions needed
- **Never** give unnecessary permissions

### 3. Documentation

Always include in your commands:

- Clear usage examples
- Parameter descriptions
- Expected outputs
- Error handling

### 4. Arguments

- Use `$ARGUMENTS` placeholder for dynamic input
- Provide `argument-hint` in frontmatter
- Include examples of valid arguments

### 5. Organization

```
.claude/commands/
├── slash-meta.md           # Meta command generator
├── slash-generator.md      # Simple generator
├── meta-*/                 # Meta-generated commands
├── domain/                 # Domain-specific commands
│   ├── ansible/
│   ├── docker/
│   └── testing/
└── tasks/                  # Task-specific commands
```

## Advanced Usage

### Recursive Command Chains

Create an entire command ecosystem:

```bash
# Create testing framework
> /slash-meta factory testing recursive
> /meta-testing-factory unit-test-generator "creates unit test commands" true
> /unit-test-generator jest-runner "run jest tests with coverage"
> /unit-test-generator pytest-runner "run pytest with fixtures"
```

### Domain-Specific Factories

Create specialized command sets:

```bash
# Infrastructure automation suite
> /slash-meta factory infrastructure recursive
> /meta-infrastructure-factory terraform-generator "terraform commands" true
> /meta-infrastructure-factory ansible-generator "ansible commands" true
> /meta-infrastructure-factory nomad-generator "nomad job commands" true
```

### Conditional Logic in Commands

Commands can include bash execution for context:

```markdown
---
allowed-tools: Bash(git status), Write
description: Create context-aware commits
---

Current changes: !`git status --short`

Based on the changes above, I'll create an appropriate commit.
```

## Troubleshooting

### Command Not Found

- Ensure file exists in `.claude/commands/`
- Check filename matches command name
- Verify no syntax errors in frontmatter

### Permission Errors

- Check `allowed-tools` includes required tools
- Verify tool usage matches permissions
- Remember: inherited permissions from conversation

### Arguments Not Working

- Ensure `$ARGUMENTS` is properly placed
- Check `argument-hint` provides clear guidance
- Test with simple arguments first

## Summary

The slash command system in this project provides:

1. **True Meta Commands**: `/slash-meta` creates recursive generators
2. **Simple Generators**: `/slash-generator` for direct task commands
3. **Organized Structure**: Clear hierarchy and naming patterns
4. **Flexibility**: From simple tasks to complex command ecosystems
5. **Team Collaboration**: Project commands shared via repository

Use meta commands when you need recursive generation capabilities, and simple generators for straightforward task automation.
