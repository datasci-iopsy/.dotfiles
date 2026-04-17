#!/usr/bin/env bash
# r-lint-staged.sh -- run lintr on staged R files
#
# Designed to be called from a repo's .git/hooks/pre-commit.
# Exits 1 (blocks commit) if any lintr findings exist.
# Bypass: SKIP_R_LINT=1 git commit
#
# Usage in pre-commit hook:
#   bash "$HOME/.claude/r-lint-staged.sh"

set -euo pipefail

[ "${SKIP_R_LINT:-0}" = "1" ] && exit 0

# Collect staged R files that exist on disk
R_FILES=()
while IFS= read -r f; do
    [[ "$f" =~ \.[Rr]$ ]] && [ -f "$f" ] && R_FILES+=("$f")
done < <(git diff --cached --name-only)

[ ${#R_FILES[@]} -eq 0 ] && exit 0

if ! command -v Rscript &>/dev/null; then
    echo "[r-lint] Rscript not found -- skipping R lint" >&2
    exit 0
fi

if ! Rscript --no-init-file --quiet -e "if (!requireNamespace('lintr', quietly=TRUE)) quit(status=1)" &>/dev/null; then
    echo "[r-lint] lintr not installed -- skipping (run: install.packages('lintr'))" >&2
    exit 0
fi

echo "[r-lint] Checking ${#R_FILES[@]} staged R file(s)..."

# --no-init-file: bypass renv/.Rprofile so global lintr is used, not project-isolated one
# Use `if !` to capture both output and non-zero exit under set -e
FINDINGS=""
if ! FINDINGS=$(Rscript --no-init-file --quiet -e "
  files <- commandArgs(trailingOnly = TRUE)
  results <- lapply(files, lintr::lint)
  all_results <- do.call(c, results)
  if (length(all_results) > 0) {
    print(all_results)
    quit(status = 1)
  }
" "${R_FILES[@]}" 2>&1); then
    echo ""
    echo "$FINDINGS"
    echo ""
    echo "[r-lint] Fix the above before committing."
    echo "         To bypass: SKIP_R_LINT=1 git commit ..."
    echo ""
    exit 1
fi

echo "[r-lint] No issues found."
exit 0
