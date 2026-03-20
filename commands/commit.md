# Commit Command

Stage and commit changes with a well-crafted message.

## Usage

`/commit [message]`

## Workflow

### 1. Analyze Changes

Run these in parallel:
- `git status` (never use `-uall`)
- `git diff` and `git diff --cached` to see all staged and unstaged changes
- `git log --oneline -5` to see recent commit style

### 2. Evaluate Scope

Review the changes and determine if they are **related or unrelated**:
- If all changes serve a single purpose → proceed as one commit
- If changes are unrelated → split into multiple commits, each grouping related files
- If changes include both source files and docs/config (*.md, settings.json, CLAUDE.md, etc.) → don't commit docs/config

### 3. Security Check

Before committing, verify:
- No secrets, API keys, passwords, or tokens in the diff
- No `.env`, `credentials.json`, or similar files staged
- Warn the user and STOP if any are found

### 4. Draft Commit Message

If `$ARGUMENTS` is provided, use it as the commit message directly.

If no message is provided, draft one following these rules:
- Prefer **single compact line** (under 72 characters)
- **Imperative mood**, starts with an uppercase letter (e.g., "Add", "Fix", "Refactor")
- **No Conventional Commits** prefix (no `feat:`, `fix:`, etc.)
- **No co-author** line
- Focus on the **why**, not the what

Present the drafted message to the user and wait for confirmation before committing.

### 5. Commit

- Stage relevant files by name (avoid `git add -A` or `git add .`)
- Commit using a HEREDOC for the message
- Run `git status` after to verify success

### 6. Report

After committing, show:
- The commit hash (short)
- The commit message
- Number of files changed

## Arguments

$ARGUMENTS - Optional commit message. If omitted, one will be drafted from the diff.
