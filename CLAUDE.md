# CLAUDE.md

---

## Core Philosophy

You are Claude Code. I use specialized agents and skills for complex tasks.

**Key Principles:**
1. **Agent-First**: Delegate to specialized agents even for a small job
2. **Parallel Execution**: Use Task tool with multiple agents when possible
3. **Plan Before Execute**: Use Plan Mode for complex operations
4. **Test-Driven**: Write tests before implementation
5. **Security-First**: Never compromise on security

---

## Modular Rules

Detailed guidelines are in `~/.claude/rules/`:

| Rule File | Contents |
|-----------|----------|
| security.md | Security checks, secret management |
| coding-style.md | Immutability, file organization, error handling |
| testing.md | TDD workflow, 80% coverage requirement |
| git-workflow.md | Commit format, PR workflow |
| agents.md | Agent orchestration, when to use which agent |
| patterns.md | API response, repository patterns |
| performance.md | Model selection, context management |

---

## Available Agents

Located in `~/.claude/agents/`:

| Agent | Purpose |
|-------|---------|
| planner | Feature implementation planning |
| architect | System design and architecture |
| tdd-guide | Test-driven development |
| code-reviewer | Code review for quality/security |
| security-reviewer | Security vulnerability analysis |
| build-error-resolver | Build error resolution |
| refactor-cleaner | Dead code cleanup |
| doc-updater | Documentation updates |

---

## Response Guidelines

- Keep documentation, README, and code comments in English
- Always ask for the user's explicit confirmation before you start a bunch of jobs
- Be direct about problems
- Quantify when possible ("this adds ~200ms latency" not "this might be slower")
- When stuck, say so and describe what you've tried
- Don't hide uncertainty behind confident language

---

## Personal Preferences

### Making Changes
- When implementing new APIs or constructors, always update existing test files to use them unless the user says otherwise
- When the user interrupts or redirects, stop immediately and follow the new direction
- When proposing a design or adding new structs/classes, do not add objects to parent structs or reference types that don't exist without checking

### System
- Prefer absolute paths rather than relative paths
- The default user directory for documents is `$HOME/문서` (Korean locale) or `$HOME/Documents` (English locale)

### Git
- Keep commit messages a compact single line representing changes the best
- Always test locally before committing
- Small, focused commits

### MCPs
- Always use Context7 MCP for library/API documentation, code generation, setup or configuration steps without asking explicitly

---

**Philosophy**: Agent-first design, parallel execution, plan before action, test before code, security always.
