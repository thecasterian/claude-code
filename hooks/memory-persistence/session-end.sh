#!/bin/bash
# Stop Hook (Session End) - Persist learnings when session ends
#
# Runs when Claude session ends. Extracts a meaningful summary from
# the session transcript (via stdin JSON transcript_path) and saves it
# to a session file for cross-session continuity.
#
# Hook config (in ~/.claude/settings.json):
# {
#   "hooks": {
#     "Stop": [{
#       "matcher": "*",
#       "hooks": [{
#         "type": "command",
#         "command": "~/.claude/hooks/memory-persistence/session-end.sh"
#       }]
#     }]
#   }
# }

SESSIONS_DIR="${HOME}/.claude/sessions"
TODAY=$(date '+%Y-%m-%d')
CURRENT_TIME=$(date '+%H:%M')

# Per-session unique ID: last 8 chars of CLAUDE_SESSION_ID, or fallback to timestamp
if [ -n "$CLAUDE_SESSION_ID" ]; then
  SHORT_ID="${CLAUDE_SESSION_ID: -8}"
else
  SHORT_ID="$(date +%s)"
fi

SESSION_FILE="${SESSIONS_DIR}/${TODAY}-${SHORT_ID}-session.tmp"

mkdir -p "$SESSIONS_DIR"

# --- Read transcript_path from stdin JSON ---
STDIN_DATA=$(timeout 2 cat 2>/dev/null || true)

TRANSCRIPT_PATH=""
if [ -n "$STDIN_DATA" ] && command -v jq >/dev/null 2>&1; then
  TRANSCRIPT_PATH=$(echo "$STDIN_DATA" | jq -r '.transcript_path // empty' 2>/dev/null)
fi

# Fallback to env var
if [ -z "$TRANSCRIPT_PATH" ] && [ -n "$CLAUDE_TRANSCRIPT_PATH" ]; then
  TRANSCRIPT_PATH="$CLAUDE_TRANSCRIPT_PATH"
fi

# --- Extract session summary from transcript ---
extract_summary() {
  local transcript="$1"

  if [ ! -f "$transcript" ]; then
    echo "[SessionEnd] Transcript not found: $transcript" >&2
    return 1
  fi

  # Extract user messages (last 10, truncated to 200 chars)
  # Handles both direct content strings and nested message.content arrays
  local user_messages
  user_messages=$(jq -r '
    # Direct user messages with string content
    (select(.type == "user" or .role == "user" or .message?.role == "user") |
      (.message?.content // .content) |
      if type == "string" then .
      elif type == "array" then [.[] | .text // ""] | join(" ")
      else ""
      end |
      gsub("\n"; " ") |
      if length > 200 then .[:200] + "..." else . end |
      select(length > 0)
    )
  ' "$transcript" 2>/dev/null | tail -10)

  # Extract tool names from both top-level tool_use and nested assistant content blocks
  local tools_used
  tools_used=$(jq -r '
    # Top-level tool_use entries
    (select(.type == "tool_use" or .tool_name != null) | .tool_name // .name // empty),
    # Nested in assistant message content blocks
    (select(.type == "assistant") | .message?.content[]? | select(.type == "tool_use") | .name // empty)
  ' "$transcript" 2>/dev/null | sort -u | head -20 | paste -sd ',' - | sed 's/,/, /g')

  # Extract modified files (from Edit/Write tool inputs)
  local files_modified
  files_modified=$(jq -r '
    # Top-level tool_use with file_path
    (select((.type == "tool_use" or .tool_name != null) and ((.tool_name // .name) == "Edit" or (.tool_name // .name) == "Write")) |
      .tool_input?.file_path // .input?.file_path // empty),
    # Nested in assistant content blocks
    (select(.type == "assistant") | .message?.content[]? |
      select(.type == "tool_use" and (.name == "Edit" or .name == "Write")) |
      .input?.file_path // empty)
  ' "$transcript" 2>/dev/null | sort -u | head -30)

  # Count total user messages
  local total_messages
  total_messages=$(jq -c 'select(.type == "user" or .role == "user" or .message?.role == "user")' "$transcript" 2>/dev/null | wc -l | tr -d ' ')

  # Only return summary if we have user messages
  if [ -z "$user_messages" ] || [ "${total_messages:-0}" -eq 0 ]; then
    return 1
  fi

  # Build summary section
  echo "## Session Summary"
  echo ""
  echo "### Tasks"
  echo "$user_messages" | while IFS= read -r msg; do
    # Escape backticks to prevent markdown breaks
    msg=$(echo "$msg" | sed 's/`/\\`/g')
    echo "- $msg"
  done
  echo ""

  if [ -n "$files_modified" ]; then
    echo "### Files Modified"
    echo "$files_modified" | while IFS= read -r f; do
      echo "- $f"
    done
    echo ""
  fi

  if [ -n "$tools_used" ]; then
    echo "### Tools Used"
    echo "$tools_used"
    echo ""
  fi

  echo "### Stats"
  echo "- Total user messages: $total_messages"
}

# --- Build or update session file ---
SUMMARY=""
if [ -n "$TRANSCRIPT_PATH" ] && command -v jq >/dev/null 2>&1; then
  SUMMARY=$(extract_summary "$TRANSCRIPT_PATH")
fi

BLANK_TEMPLATE='## Current State

[Session context goes here]

### Completed
- [ ]

### In Progress
- [ ]

### Notes for Next Session
-

### Context to Load
```
[relevant files]
```'

if [ -f "$SESSION_FILE" ]; then
  # Update existing session file: refresh timestamp
  sed -i "s/\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* ${CURRENT_TIME}/" "$SESSION_FILE" 2>/dev/null

  # If we have a summary and the file still has the blank template, replace it
  if [ -n "$SUMMARY" ] && grep -q '\[Session context goes here\]' "$SESSION_FILE"; then
    # Replace everything from "## Current State" to the end of the template block
    # Use ENVIRON to avoid awk -v backslash interpretation
    export SUMMARY
    tmpfile=$(mktemp "${SESSION_FILE}.XXXXXX")
    awk '
      /^## Current State/ { found=1; ticks=0; print ENVIRON["SUMMARY"]; next }
      found && /^```$/ { ticks++; if (ticks >= 2) found=0; next }
      !found { print }
    ' "$SESSION_FILE" > "$tmpfile" && mv "$tmpfile" "$SESSION_FILE"
  fi

  echo "[SessionEnd] Updated session file: $SESSION_FILE" >&2
else
  # Create new session file
  if [ -n "$SUMMARY" ]; then
    BODY="$SUMMARY"
  else
    BODY="$BLANK_TEMPLATE"
  fi

  cat > "$SESSION_FILE" << ENDTEMPLATE
# Session: ${TODAY}
**Date:** ${TODAY}
**Started:** ${CURRENT_TIME}
**Last Updated:** ${CURRENT_TIME}

---

${BODY}
ENDTEMPLATE

  echo "[SessionEnd] Created session file: $SESSION_FILE" >&2
fi
