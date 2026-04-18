#!/usr/bin/env bash
# coderabbit-triage.sh -- inject triage rubric when a CodeRabbit review prompt is detected
#
# Triggered by UserPromptSubmit hook. Detects CodeRabbit finding patterns and
# prints the triage rubric to stdout so it lands in session context. Non-blocking
# (always exits 0).
#
# Detection patterns:
#   - "Verify each finding against the current code" (direct paste format)
#   - coderabbit-instructions (file-based format piped via cat)
#
# Rating 3 deferred findings accumulate in ~/.claude/coderabbit-deferred.md
# for the current session only. On first detection per session the file is
# truncated and a session header is written; subsequent prompts append.
# The stop hook prints a reminder if deferred items exist at session end.

set -euo pipefail

DEFERRED="$HOME/.claude/coderabbit-deferred.md"
STAMP_DIR="$HOME/.claude"

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

if echo "$prompt" | grep -qE 'Verify each finding against the current code|coderabbit-instructions'; then
    # On first CodeRabbit prompt in this session, reset the deferred file
    stamp="$STAMP_DIR/.coderabbit-session"
    last_session=$(cat "$stamp" 2>/dev/null || echo "")
    if [[ "$last_session" != "$session_id" ]]; then
        echo "$session_id" > "$stamp"
        {
            echo "# CodeRabbit Deferred Findings"
            echo "# Session: $session_id"
            echo "# $(date '+%Y-%m-%d %H:%M')"
            echo ""
        } > "$DEFERRED"
    fi

    cat <<'EOF'
[CodeRabbit triage active]
Before acting, rate this finding 1-5:
  1-2  False positive or nitpick -- dismiss, one-line rationale, no edit.
  3    Judgment call -- do NOT fix; append finding + your assessment to
       ~/.claude/coderabbit-deferred.md; report "Deferred: <one-line summary>".
  4-5  Real defect -- spawn the code-surgeon agent to apply the fix.
       Use subagent_type "general-purpose", description "Fix CR-<N>: <one-line summary>",
       and pass the finding location and expected fix in the prompt.
       Do not fix inline. Do not spawn any other agent type.
EOF
fi

exit 0
