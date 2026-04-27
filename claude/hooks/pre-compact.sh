#!/bin/bash
# pre-compact.sh — capture session state before context compaction
#
# Fires on both triggers:
#   trigger=manual  — user ran /compact
#   trigger=auto    — context threshold hit automatically
#
# Writes a structured handoff file to the project memory directory and
# updates MEMORY.md so future sessions load it automatically.
#
# Output file: ~/.claude/projects/<project>/memory/handoff_<date>_<id>.md
# Exit 0 always — never block compaction.

set -euo pipefail

# ── Parse hook input ──────────────────────────────────────────────────────────
INPUT=$(cat)

if ! command -v jq &>/dev/null; then
    echo "[pre-compact] jq not found — skipping handoff" >&2
    exit 0
fi

TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

if [ -z "$CWD" ]; then
    echo "[pre-compact] cwd missing from hook input — skipping" >&2
    exit 0
fi

# ── Derive paths ──────────────────────────────────────────────────────────────
# Claude Code sanitizes CWD to a project key by replacing / and . with -
PROJECT_KEY=$(echo "$CWD" | tr '/.' '-')
MEMORY_DIR="$HOME/.claude/projects/$PROJECT_KEY/memory"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DATE=$(date +"%Y-%m-%d")
SESSION_SHORT="${SESSION_ID:0:8}"
HANDOFF_FILE="$MEMORY_DIR/handoff_${DATE}_${SESSION_SHORT}.md"
MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"

mkdir -p "$MEMORY_DIR"

# ── Locate transcript JSONL ───────────────────────────────────────────────────
# Prefer transcript_path from hook input (provided by Claude Code directly)
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    TRANSCRIPT="$TRANSCRIPT_PATH"
else
    # Fallback: derive from session ID, then most recent JSONL
    TRANSCRIPT="$HOME/.claude/projects/$PROJECT_KEY/${SESSION_ID}.jsonl"
    if [ ! -f "$TRANSCRIPT" ]; then
        TRANSCRIPT=$(ls -t "$HOME/.claude/projects/$PROJECT_KEY/"*.jsonl 2>/dev/null | head -1 || echo "")
    fi
fi

# ── Extract file activity from transcript ─────────────────────────────────────
FILE_READS=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    FILE_READS=$(jq -r '
        # Assistant messages contain tool_use blocks
        select(.type == "assistant") |
        (.message.content // .content // [])[] |
        select(.type == "tool_use") |
        select(.name | test("^(Read|Write|Edit)$")) |
        "\(.name): \(.input.file_path // .input.path // "")"
    ' "$TRANSCRIPT" 2>/dev/null \
        | grep -v ': $' \
        | sort -u \
        | head -60 \
        || echo "")
fi

if [ -z "$FILE_READS" ]; then
    FILE_READS="(no file reads detected in transcript)"
fi

# ── Git state ─────────────────────────────────────────────────────────────────
BRANCH="(not a git repo)"
GIT_STATUS="(not a git repo)"
RECENT_COMMITS="(not a git repo)"
CHANGED_FILES="(no changes)"

if git -C "$CWD" rev-parse --git-dir &>/dev/null 2>&1; then
    BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null || echo "detached HEAD")
    GIT_STATUS=$(git -C "$CWD" status --short 2>/dev/null || echo "")
    RECENT_COMMITS=$(git -C "$CWD" log --oneline -5 2>/dev/null || echo "(no commits)")
    CHANGED_FILES=$(git -C "$CWD" diff --stat HEAD 2>/dev/null || echo "(no staged changes)")
    [ -z "$GIT_STATUS" ] && GIT_STATUS="(clean)"
    [ -z "$CHANGED_FILES" ] && CHANGED_FILES="(no staged changes)"
fi

# ── Write handoff file ────────────────────────────────────────────────────────
cat > "$HANDOFF_FILE" << HANDOFF
---
name: Session handoff ${DATE}
description: Pre-compact snapshot — ${TRIGGER} trigger, branch ${BRANCH}
type: project
---

**Trigger:** ${TRIGGER}
**Session:** ${SESSION_ID}
**Branch:** ${BRANCH}
**Project:** ${CWD}
**Timestamp:** ${TIMESTAMP}

## Files active this session

Do not re-read these files — their content was in context before compaction:

\`\`\`
${FILE_READS}
\`\`\`

## Git state

\`\`\`
${GIT_STATUS}
\`\`\`

## Recent commits

\`\`\`
${RECENT_COMMITS}
\`\`\`

## Files changed (git diff)

\`\`\`
${CHANGED_FILES}
\`\`\`
HANDOFF

# ── Update MEMORY.md index ────────────────────────────────────────────────────
HANDOFF_BASENAME=$(basename "$HANDOFF_FILE")

# Remove any existing entry for this date to avoid duplicates from multiple
# compactions in one day, then re-add the current one.
TEMP=$(mktemp)
if [ -f "$MEMORY_INDEX" ]; then
    grep -v "handoff_${DATE}" "$MEMORY_INDEX" > "$TEMP" || true
else
    touch "$TEMP"
fi

# Keep at most 4 existing handoff lines (oldest drops off at 5+this one)
NON_HANDOFF=$(grep -v '\[Session handoff' "$TEMP" || true)
HANDOFF_LINES=$(grep '\[Session handoff' "$TEMP" | tail -4 || true)
{
    echo "$NON_HANDOFF"
    echo "$HANDOFF_LINES"
    echo "- [Session handoff ${DATE}](${HANDOFF_BASENAME}) — ${TRIGGER} compact, branch ${BRANCH}"
} | grep -v '^$' > "$MEMORY_INDEX"

rm -f "$TEMP"

echo "[pre-compact] handoff written: $HANDOFF_FILE" >&2
exit 0
