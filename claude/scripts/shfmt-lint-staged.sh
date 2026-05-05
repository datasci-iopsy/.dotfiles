#!/usr/bin/env bash
# shfmt-lint-staged.sh -- run shfmt format check on staged shell files
#
# Designed to be called from a repo's .git/hooks/pre-commit.
# Exits 1 (blocks commit) if any shfmt findings exist.
# Bypass: SKIP_SHFMT=1 git commit

set -euo pipefail

[ "${SKIP_SHFMT:-0}" = "1" ] && exit 0

SH_FILES=()
while IFS= read -r f; do
	[[ "$f" =~ \.(sh|bash)$ ]] && [ -f "$f" ] && SH_FILES+=("$f")
done < <(git diff --cached --name-only)

[ ${#SH_FILES[@]} -eq 0 ] && exit 0

if ! command -v shfmt &>/dev/null; then
	echo "[shfmt] shfmt not found -- skipping shell format check" >&2
	exit 0
fi

echo "[shfmt] Checking ${#SH_FILES[@]} staged shell file(s)..."

if ! shfmt -d -i 0 -bn -ci "${SH_FILES[@]}" 2>&1; then
	echo ""
	echo "[shfmt] Format issues found. Run: shfmt -w -i 0 -bn -ci ${SH_FILES[*]}"
	echo "        To bypass: SKIP_SHFMT=1 git commit ..."
	echo ""
	exit 1
fi

echo "[shfmt] No issues found."
exit 0
