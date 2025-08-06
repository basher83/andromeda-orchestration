---
allowed-tools: Write, Read, LS, Grep
argument-hint: <generator-type> <domain> [recursive]
description: Create meta slash commands that can generate other commands
---

# Meta Slash Command Generator

This is a TRUE meta command that creates slash commands capable of generating other slash commands, enabling recursive command creation.

## Usage

`/slash-meta <generator-type> <domain> [recursive]`

Examples:
- `/slash-meta factory "testing commands" recursive` - Creates a testing command factory
- `/slash-meta generator "infrastructure" recursive` - Creates an infrastructure command generator
- `/slash-meta builder "documentation"` - Creates a documentation command builder

## Meta Command Types

1. **factory**: Creates a domain-specific command factory
2. **generator**: Creates a flexible command generator for a domain
3. **builder**: Creates a command builder with templates

## What Makes This Meta?

Unlike simple command generators, this creates commands that:
- Have Write permissions to create more commands
- Include command generation logic
- Can create commands that themselves create commands (if recursive)
- Enable infinite command generation chains

## Your Request

Create a meta command for: $ARGUMENTS

## Implementation

I'll parse your arguments to determine:
1. Generator type (factory/generator/builder)
2. Domain focus
3. Whether to enable recursive capabilities

Then create a slash command that:
- Has full command creation capabilities
- Includes appropriate generation logic
- Can spawn more generators if recursive flag is set
- Follows the pattern: `/meta-<domain>-<type>`

The generated command will be saved to `.claude/commands/` with:
- Write, Read, LS tools enabled
- Command generation template
- Domain-specific logic
- Optional recursive generation capability
