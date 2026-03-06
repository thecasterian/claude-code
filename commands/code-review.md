---
description: Review code for quality, security, and maintainability. Flags issues by severity and provides actionable fixes.
---

# Code Review Command

This command invokes the **code-reviewer** agent to review recent changes.

## When to Use

- After writing or modifying code
- Before committing or creating a PR
- Reviewing unfamiliar code for quality issues

## Review Severity Levels

```
CRITICAL  →  Security vulnerabilities, data loss risks
HIGH      →  Code quality issues, missing error handling
MEDIUM    →  Performance concerns, unnecessary copies
LOW       →  Naming, style, documentation gaps
```

## Integration with Other Agents

- Use `tdd-guide` agent to implement with tests first
- Use `build-error-resolver` agent if build errors occur
- Use `security-reviewer` agent for deep security analysis

## References

- **Agent**: `code-reviewer` (`~/.claude/agents/code-reviewer.md`)
- **Skill**: `coding-standards` — full coding patterns and best practices
- **Skill**: `security-review` — detailed security checklist and examples
