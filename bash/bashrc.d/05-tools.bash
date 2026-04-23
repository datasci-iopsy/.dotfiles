# ==============================================================================
# 05-tools.bash — Shell tool integrations
# ==============================================================================

# thefuck — corrects previous console commands
if command -v thefuck >/dev/null 2>&1; then
    eval "$(thefuck --alias)"
    eval "$(thefuck --alias FUCK)"
fi

# direnv — per-directory environment variables
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi

# claude — wrapper that intercepts CodeRabbit "fix all" batches at the shell
# level, before the temp file can be deleted by the trailing "&& rm" in the
# CodeRabbit-generated command. When two or more "Verify each finding" lines
# are detected in the first argument, the batch is staged to
# ~/.claude/coderabbit-staged-batch.md and Claude starts interactively so
# the user can run /coderabbit-fix to process findings through triage.
# On a CodeRabbit retry (file already deleted, empty argument), count=0 and
# the wrapper passes through normally — staged content is already safe.
claude() {
    local arg="${1:-}"
    local count=0
    if [[ -n "$arg" ]]; then
        count=$(printf '%s' "$arg" | grep -c 'Verify each finding against the current code' 2>/dev/null || true)
    fi
    if [[ "$count" -ge 2 ]]; then
        {
            printf '# CodeRabbit Staged Batch\n'
            printf '# Staged: %s\n' "$(date '+%Y-%m-%d %H:%M')"
            printf '# Findings: %s\n' "$count"
            printf '\n'
            printf '%s\n' "$arg"
        } > "$HOME/.claude/coderabbit-staged-batch.md"
        printf '[CodeRabbit] %s finding(s) staged to ~/.claude/coderabbit-staged-batch.md\n' "$count"
        printf '[CodeRabbit] Run /coderabbit-fix inside Claude to process through triage.\n'
        shift
        command claude "$@"
        return
    fi
    command claude "$@"
}
