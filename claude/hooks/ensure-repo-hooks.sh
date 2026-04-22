#!/usr/bin/env bash
# ensure-repo-hooks.sh -- silently install pre-commit hook in the current repo
#
# Triggered by UserPromptSubmit. Exits 0 always (non-blocking).
# No output on success -- zero context cost.

set -euo pipefail

repo=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

hook="$repo/.git/hooks/pre-commit"

# Already wired up -- nothing to do
grep -qF -- 'repo-pre-commit.sh' "$hook" 2>/dev/null && exit 0

# Install silently; warn to stderr on failure
if ! (cd "$repo" && bash "$HOME/.claude/scripts/install-repo-hooks.sh" > /dev/null 2>&1); then
    echo "[hooks] Failed to install pre-commit hook in $repo" >&2
fi

exit 0
