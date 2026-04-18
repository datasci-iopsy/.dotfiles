#!/usr/bin/env bash
# ruff-lint-staged.sh -- run ruff lint and format check on staged Python files
#
# Designed to be called from a repo's .git/hooks/pre-commit.
# Exits 1 (blocks commit) if any ruff findings exist.
# Bypass: SKIP_RUFF=1 git commit
#
# Usage in pre-commit hook:
#   bash "$HOME/.claude/scripts/ruff-lint-staged.sh"

set -euo pipefail

[ "${SKIP_RUFF:-0}" = "1" ] && exit 0

# Collect staged Python files that exist on disk
PY_FILES=()
while IFS= read -r f; do
    [[ "$f" =~ \.py$ ]] && [ -f "$f" ] && PY_FILES+=("$f")
done < <(git diff --cached --name-only)

[ ${#PY_FILES[@]} -eq 0 ] && exit 0

if ! command -v ruff &>/dev/null; then
    echo "[ruff] ruff not found -- skipping Python lint" >&2
    exit 0
fi

echo "[ruff] Checking ${#PY_FILES[@]} staged Python file(s)..."

FAILED=0

# Lint check
if ! ruff check "${PY_FILES[@]}" 2>&1; then
    echo ""
    echo "[ruff] Fix lint issues above before committing."
    FAILED=1
fi

# Format check (does not auto-fix -- keeps staged state clean)
if ! ruff format --check "${PY_FILES[@]}" 2>&1; then
    echo ""
    echo "[ruff] Format issues found. Run: ruff format ${PY_FILES[*]}"
    FAILED=1
fi

if [ "$FAILED" -eq 1 ]; then
    echo ""
    echo "       To bypass: SKIP_RUFF=1 git commit ..."
    echo ""
    exit 1
fi

echo "[ruff] No issues found."
exit 0
