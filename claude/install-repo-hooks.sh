#!/usr/bin/env bash
# install-repo-hooks.sh -- add standard hooks to the current git repo
#
# Run once from any project root after cloning on a new machine.
# Safe to re-run -- skips anything already in place.
#
# Usage:
#   cd /path/to/repo
#   bash ~/.claude/install-repo-hooks.sh

set -euo pipefail

HOOK_DIR="$(git rev-parse --git-dir 2>/dev/null)/hooks"
if [ $? -ne 0 ] || [ -z "$HOOK_DIR" ]; then
    echo "ERROR: not inside a git repository." >&2
    exit 1
fi

HOOK_FILE="$HOOK_DIR/pre-commit"
R_LINT_LINE='bash "$HOME/.claude/r-lint-staged.sh"'
RUFF_LINT_LINE='bash "$HOME/.claude/ruff-lint-staged.sh"'
SHEBANG='#!/usr/bin/env bash'

# --- Create or update pre-commit hook ---

if [ ! -f "$HOOK_FILE" ]; then
    # No existing hook -- create a fresh one
    cat > "$HOOK_FILE" << EOF
$SHEBANG
# Pre-commit hooks (managed by ~/.dotfiles)

$R_LINT_LINE
$RUFF_LINT_LINE
EOF
    chmod +x "$HOOK_FILE"
    echo "  created  $HOOK_FILE"
else
    # Hook exists -- check if R lint is already wired in
    if grep -qF 'r-lint-staged.sh' "$HOOK_FILE"; then
        echo "  ok       R lint already in $HOOK_FILE"
    else
        # Append after shebang line if it exists, otherwise append at end
        if head -1 "$HOOK_FILE" | grep -q '^#!'; then
            sed -i '' "1a\\
\\
# R style lint (added by install-repo-hooks.sh)\\
$R_LINT_LINE
" "$HOOK_FILE"
        else
            printf '\n# R style lint (added by install-repo-hooks.sh)\n%s\n' "$R_LINT_LINE" >> "$HOOK_FILE"
        fi
        echo "  updated  $HOOK_FILE (added R lint)"
    fi

    # Check if ruff lint is already wired in
    if grep -qF 'ruff-lint-staged.sh' "$HOOK_FILE"; then
        echo "  ok       ruff lint already in $HOOK_FILE"
    else
        printf '\n# Python ruff lint (added by install-repo-hooks.sh)\n%s\n' "$RUFF_LINT_LINE" >> "$HOOK_FILE"
        echo "  updated  $HOOK_FILE (added ruff lint)"
    fi
fi

echo ""
echo "Done. Pre-commit hook active for this repo."
echo "Bypass: SKIP_R_LINT=1 git commit ...  (R lint)  |  SKIP_RUFF=1 git commit ...  (Python)"
