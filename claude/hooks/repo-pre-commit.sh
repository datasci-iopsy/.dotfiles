#!/usr/bin/env bash
# repo-pre-commit.sh -- stable dispatcher for repo pre-commit hooks
#
# Repos call this single file via their .git/hooks/pre-commit.
# When script paths change inside dotfiles, update only this file --
# all repos pick up the change automatically.
#
# Stable path (repos reference this; never rename it):
#   bash "$HOME/.claude/hooks/repo-pre-commit.sh"
#
# Bypass flags:
#   SKIP_R_LINT=1 git commit    -- skip R lint
#   SKIP_RUFF=1   git commit    -- skip Python lint

set -euo pipefail

SCRIPTS="$HOME/.claude/scripts"

bash "$SCRIPTS/r-lint-staged.sh"
bash "$SCRIPTS/ruff-lint-staged.sh"
