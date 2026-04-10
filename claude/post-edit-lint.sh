#!/usr/bin/env bash
# post-edit-lint.sh -- PostToolUse lint hook
#
# Runs linters after Claude edits Python, Shell, or R files.
# Always exits 0 (informational only -- never blocks Claude).
#
# Triggered by: PostToolUse on Edit|Write
# Reads: JSON from stdin (tool_name, tool_input.file_path, ...)

INPUT=$(cat)
FILE=$(jq -r '.tool_input.file_path // empty' 2>/dev/null <<< "$INPUT")

[ -z "$FILE" ] && exit 0

case "$FILE" in

  *.py)
    if command -v ruff &>/dev/null; then
      echo "[lint] ruff check: $FILE" >&2
      ruff check --quiet "$FILE" 2>&1 | head -5
      echo "[lint] ruff format: $FILE" >&2
      ruff format --quiet "$FILE" 2>&1
    fi
    ;;

  *.sh)
    if command -v shellcheck &>/dev/null; then
      echo "[lint] shellcheck: $FILE" >&2
      shellcheck --severity=warning "$FILE" 2>&1 | head -5
    fi
    ;;

  *.R|*.r)
    if ! command -v Rscript &>/dev/null; then
      exit 0
    fi
    if ! Rscript --no-init-file --quiet -e "if (!requireNamespace('lintr', quietly=TRUE)) quit(status=1)" &>/dev/null; then
      echo "[lint] lintr not installed -- run: install.packages('lintr')" >&2
      exit 0
    fi
    echo "[lint] lintr: $FILE" >&2
    # --no-init-file: bypass renv/.Rprofile so global lintr is used
    # Pass path via env var to handle spaces and special characters safely
    LINTR_FILE="$FILE" Rscript --no-init-file --quiet \
      -e "lintr::lint(Sys.getenv('LINTR_FILE'))" 2>&1 | head -10
    ;;

esac

exit 0
