#!/usr/bin/env bash
# json-lint-staged.sh -- check staged JSON files are formatted with 4-space indent
#
# Designed to be called from a repo's .git/hooks/pre-commit.
# Exits 1 (blocks commit) if any JSON file differs from jq --indent 4 output.
# Does not auto-fix -- keeps staged state clean.
# Bypass: SKIP_JSON_LINT=1 git commit

set -euo pipefail

[ "${SKIP_JSON_LINT:-0}" = "1" ] && exit 0

# Collect staged JSON files that exist on disk
JSON_FILES=()
while IFS= read -r f; do
    [[ "$f" =~ \.json$ ]] && [ -f "$f" ] && JSON_FILES+=("$f")
done < <(git diff --cached --name-only)

[ ${#JSON_FILES[@]} -eq 0 ] && exit 0

if ! command -v jq &>/dev/null; then
    echo "[json] jq not found -- skipping JSON format check" >&2
    exit 0
fi

echo "[json] Checking ${#JSON_FILES[@]} staged JSON file(s)..."

FAILED=0

for f in "${JSON_FILES[@]}"; do
    expected=$(jq --indent 4 . "$f" 2>&1) || {
        echo "[json] Parse error in $f -- $expected"
        FAILED=1
        continue
    }
    actual=$(cat "$f")
    if [ "$expected" != "$actual" ]; then
        echo "[json] $f is not formatted with 4-space indent."
        echo "       Fix: jq --indent 4 . \"$f\" > /tmp/fix.json && mv /tmp/fix.json \"$f\""
        FAILED=1
    fi
done

if [ "$FAILED" -eq 1 ]; then
    echo ""
    echo "       To bypass: SKIP_JSON_LINT=1 git commit ..."
    echo ""
    exit 1
fi

echo "[json] No issues found."
exit 0
