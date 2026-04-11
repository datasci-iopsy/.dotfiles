#!/usr/bin/env bash
# ~/.dotfiles/install.sh
# Run once on a new machine to symlink dotfiles into place.
# Safe to re-run — skips anything already correctly linked.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

symlink() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "  ok  $dst"
    elif [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "  SKIP $dst (exists as real file — back it up and remove it first)"
    else
        ln -sf "$src" "$dst"
        echo "  link $dst -> $src"
    fi
}

echo "=== Claude Code ==="
symlink "$DOTFILES/claude/settings.json"          "$HOME/.claude/settings.json"
symlink "$DOTFILES/claude/CLAUDE.md"              "$HOME/.claude/CLAUDE.md"
symlink "$DOTFILES/claude/statusline-command.sh"  "$HOME/.claude/statusline-command.sh"
symlink "$DOTFILES/claude/keybindings.json"       "$HOME/.claude/keybindings.json"
symlink "$DOTFILES/claude/skills"               "$HOME/.claude/skills"
symlink "$DOTFILES/claude/cleanup-sessions.py"  "$HOME/.local/bin/claude-cleanup"
symlink "$DOTFILES/claude/cost-guard.sh"        "$HOME/.claude/cost-guard.sh"
symlink "$DOTFILES/claude/post-edit-lint.sh"    "$HOME/.claude/post-edit-lint.sh"
symlink "$DOTFILES/claude/r-lint-staged.sh"      "$HOME/.claude/r-lint-staged.sh"
symlink "$DOTFILES/claude/ruff-lint-staged.sh"   "$HOME/.claude/ruff-lint-staged.sh"
symlink "$DOTFILES/claude/install-repo-hooks.sh" "$HOME/.claude/install-repo-hooks.sh"
symlink "$DOTFILES/claude/clean-plans.sh"        "$HOME/.claude/clean-plans.sh"
symlink "$DOTFILES/claude/maintenance-check.sh"  "$HOME/.claude/maintenance-check.sh"

echo "=== R Style ==="
symlink "$DOTFILES/.lintr"                      "$HOME/.lintr"

echo ""
echo "Done. Run seed-memory.sh to initialize Claude memory files for a project."
