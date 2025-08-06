---
allowed-tools: Write, Read, LS
argument-hint: <command-name> <command-purpose>
description: Simple slash command generator (non-meta)
---

# Slash Command Generator

This is a simple command generator that creates end-point slash commands for specific tasks.

## Usage

`/slash-generator <command-name> <command-purpose>`

Examples:

- `/slash-generator markdown-lint "lint markdown files"`
- `/slash-generator security-scan "scan for vulnerabilities"`
- `/slash-generator test-runner "run and fix tests"`

## Difference from /slash-meta

- **This generator**: Creates task-specific commands (endpoints)
- **/slash-meta**: Creates command generators (recursive capability)

## Command Generation

For: $ARGUMENTS

I will create a slash command that:

1. Performs a specific task
2. Has appropriate tool permissions for that task
3. Cannot create other commands

The generated command will be optimized for its specific purpose with minimal tool permissions.
