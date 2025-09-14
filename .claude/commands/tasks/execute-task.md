---
description: Execute the task for a given feature
argument-hint: [Task file]
---

# Execute Task

Implement a feature using using the task file.

## Task File

- @$ARGUMENTS

## Specialized Sub-agents

`.claude/agents/ansible-research.md`

- Specialist for discovering official and community Ansible collections, assessing quality metrics, analyzing repository health, and providing integration recommendations for technologies like NetBox, Proxmox, Nomad, Consul, Vault, and DNS/IPAM systems.

`.claude/agents/github-implementation-research.md`

- Specialist designed to find high-quality code examples, patterns, and implementation strategies from GitHub repositories.

## Execution Process

1. **Load Task**

   - Read the specified task file @$ARGUMENTS
   - Understand all context and requirements
   - Follow all instructions in the task file and extend the research if needed
   - Ensure you have all needed context to implement the task fully
   - Do more web searches and codebase exploration as needed

2. **ULTRATHINK**

   - Think hard before you execute the plan. Create a comprehensive plan addressing all requirements.
   - Break down complex tasks into smaller, manageable steps using your todos tools.
   - Use the TodoWrite tool to create and track your implementation plan.
   - Identify implementation patterns from existing code to follow.

3. **Execute the plan**

   - Update the task status to In Progress in `docs/project-management/tasks/README.md`
   - Execute the task @$ARGUMENTS
   - Implement all the code

4. **Validate**

   - Run each validation command
   - Fix any failures
   - Re-run until all pass

5. **Complete**

   - Ensure all checklist items done
   - Run final validation suite
   - Report completion status
   - Read the task again to ensure you have implemented everything
   - Update the task status to <Blocked/Complete/Failed> in `docs/project-management/tasks/README.md`

6. **Reference the Task**
   - You can always reference the task again if needed

Note: If validation fails, use error patterns in task to fix and retry.
