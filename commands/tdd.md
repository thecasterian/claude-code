---
description: Enforce test-driven development workflow. Scaffold interfaces, generate tests FIRST, then implement minimal code to pass.
---

# TDD Command

This command invokes the **tdd-guide** agent to enforce test-driven development methodology.

## When to Use

- Implementing new features
- Fixing bugs (write test that reproduces bug first)
- Refactoring existing code
- Building critical business logic

## TDD Cycle

```
RED → GREEN → REFACTOR → REPEAT
```

## Integration with Other Agents

- Use `planner` agent first to understand what to build
- Use `build-error-resolver` agent if build errors occur
- Use `code-reviewer` agent to review implementation

## References

- **Agent**: `tdd-guide` (`~/.claude/agents/tdd-guide.md`)
- **Skill**: `tdd-workflow` — full TDD steps, patterns, and examples
