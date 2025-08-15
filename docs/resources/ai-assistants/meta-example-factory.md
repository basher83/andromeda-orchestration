---
allowed-tools: Write, Read, LS, Grep
argument-hint: <command-name> <purpose> [sub-generators]
description: Example meta command factory that creates command generators
---

# Meta Example Factory

This command was created by `/slash-meta` and demonstrates true meta capabilities by creating commands that can themselves generate more commands.

## What Makes This Meta?

This factory can create:

1. End-user commands (like `/lint`, `/test`)
2. Generator commands that create more commands
3. Sub-factories that create domain-specific generators

## Usage

`/meta-example-factory <command-name> <purpose> [sub-generators]`

Examples:

- `/meta-example-factory test-generator "creates testing commands" true`
- `/meta-example-factory lint-factory "creates linting commands" true`
- `/meta-example-factory simple-command "runs a specific task" false`

## Implementation for: $ARGUMENTS

Based on your request, I will:

1. Parse the command name, purpose, and sub-generator flag
2. Determine the appropriate command type:
   - If sub-generators=true: Create a command with Write permissions that can create more commands
   - If sub-generators=false: Create a simple task-specific command

3. Generate the command with:

   ```markdown
   ---
   allowed-tools: ${sub-generators ? 'Write, Read, LS' : 'Read, Grep, MultiEdit'}
   argument-hint: ${appropriate-hint}
   description: ${purpose}
   ---

   # ${command-name}

   ${sub-generators ? 'This generator creates commands for: ' + purpose : purpose}

   ## Implementation
   ${sub-generators ? generation-logic : task-logic}
   ```

4. Save to `.claude/commands/${command-name}.md`

This demonstrates the recursive nature of meta commands - this factory was created by a meta command and can create more factories!
