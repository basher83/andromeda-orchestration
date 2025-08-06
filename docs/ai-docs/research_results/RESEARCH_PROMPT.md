# Research-Vault Evaluation Prompt

## Task: HashiCorp Vault + Ansible + Nomad Research

I'd like help finding solid references and sample open source code that shows how to deploy HashiCorp Vault via Ansible to a Nomad cluster. Use your available MCP tools for research.

### Workspace Setup & Context

**Working Directory**: `evaluations/cross-platform/research-vault/subjects/{platform-name}/`
**Current Platform**: {PLATFORM_NAME}
**Model**: {MODEL_NAME}
**Session Context**: Fresh evaluation session (no prior research context)

**File Organization**:

- Create research notes in the current subject directory
- Use clear file naming: `{mcp-server}-findings.md`, `synthesis-notes.md`, etc.
- All documentation should be saved as markdown files for consistent evaluation

### Available MCP Servers

- **deepwiki** - GitHub repository documentation tool
- **docker-mcp** - Docker and containerization tools
- **Github** - GitHub repository search and access
- **grep** - Code search and pattern matching

### Important: Context Isolation

**For Fair Evaluation**:

- This should be a fresh research session with no prior knowledge of this task
- Do not reference previous research on Vault/Ansible/Nomad from workspace cache
- Rely only on MCP tool findings during this evaluation session
- Save all findings to files in the current directory for evaluation review

### Research Approach: Two-Phase Evaluation

#### Phase 1: Guided Exploration (20 minutes)

**Objective**: Test systematic tool usage with light constraints

**Instructions**:

1. **Start with DeepWiki**: Research HashiCorp's official repositories and related projects
2. **Use Github/grep tools**: Search for specific patterns:
   - "vault ansible nomad"
   - "nomad job vault"
   - "ansible-playbook vault" + "nomad"
3. **Explore Docker-MCP**: Look for containerization aspects and deployment patterns

**Documentation Approach** (Choose based on your natural workflow):

- **Option A - Progressive Documentation**: Document findings after each MCP server
- **Option B - Running Notes**: Keep brief notes and synthesize at the end
- **Option C - Memory-Based**: Rely on context retention and document comprehensively at completion

_Note: Your documentation approach will be evaluated as part of research methodology assessment_

#### Phase 2: Open Innovation (15 minutes)

**Objective**: Test creative tool selection and synthesis

**Instructions**:

1. **Choose your own approach**: Select which MCP tools to use and how to combine them
2. **Fill knowledge gaps**: Address anything missing from Phase 1
3. **Synthesize findings**: Create actionable deployment recommendations

### Documentation Requirements

**Flexibility Note**: You may document progressively (after each tool) or comprehensively at the end. Your approach will be evaluated as part of methodology assessment.

For each MCP server used, provide:

```markdown
## MCP Server: {SERVER_NAME}

### Tools Available

- [List all tools you see available in this server]

### Tools Selected & Reasoning

- [Which tools you chose and why]

### Search Strategy

- [Your approach and methodology]

### Results Quality Ratings

- **Relevance** (1-5): How relevant to Vault+Ansible+Nomad
- **Depth** (1-5): Level of technical detail provided
- **Actionability** (1-5): How implementable the findings are

### Key Discoveries

- **Repositories Found**: [Specific GitHub repos with working examples]
- **Configuration Patterns**: [Common deployment patterns discovered]
- **Best Practices**: [Security, performance, operational insights]

### Tool Effectiveness Assessment

- **Strengths**: What this tool excelled at
- **Limitations**: Where it fell short
- **Future Use**: Would you use this tool again for similar research?
```

### Success Criteria

- **Must find**: 3+ high-quality, actionable Vault+Ansible+Nomad examples
- **Must use**: All 4 MCP servers in meaningful ways
- **Must deliver**: Practical deployment recommendations with specific examples

### Final Deliverable

End with a **synthesized recommendation** that combines insights from all tools, including:

1. **Best Example Repository**: Your top pick with justification
2. **Deployment Strategy**: Step-by-step approach based on research
3. **Tool Combination Insights**: Which MCP tools worked best together
4. **Platform-Specific Observations**: How this platform handled the multi-tool research task

---

**Evaluation Note**: This task tests both your ability to systematically use specified tools AND your capacity for creative tool selection and synthesis. Document your process thoroughly - the methodology is as important as the results.
