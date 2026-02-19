# Hooks System

## Hook Types

- **SessionStart**: When a session begins
- **Stop**: When session ends
- **PreCompact**: Before context compaction
- **UserPromptSubmit**: When user submits a prompt

## Current Hooks (in ~/.claude/settings.json)

### SessionStart
- **memory-persistence**: Loads persistent memory from previous sessions

### Stop
- **memory-persistence**: Saves session memory for future use
- **continuous-learning**: Evaluates session for reusable patterns

### PreCompact
- **memory-persistence**: Persists memory before context window compaction

### UserPromptSubmit
- **english-correction**: Corrects English in user prompts (timeout: 300ms)

## Auto-Accept Permissions

Use with caution:
- Enable for trusted, well-defined plans
- Disable for exploratory work
- Never use dangerously-skip-permissions flag
- Configure `allowedTools` in `~/.claude.json` instead

## TodoWrite Best Practices

Use TodoWrite tool to:
- Track progress on multi-step tasks
- Verify understanding of instructions
- Enable real-time steering
- Show granular implementation steps

Todo list reveals:
- Out of order steps
- Missing items
- Extra unnecessary items
- Wrong granularity
- Misinterpreted requirements
