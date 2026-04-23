#!/usr/bin/env bash
# ~/.dotfiles/install.sh
# Run once on a new machine to symlink dotfiles into place.
# Safe to re-run — skips anything already correctly linked.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Flag parsing
SKIP_BASH=false
for _arg in "$@"; do
    case "$_arg" in
        --skip-bash) SKIP_BASH=true ;;
    esac
done
unset _arg

symlink() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "  ok   $dst"
    elif [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "  SKIP $dst (real file exists — back it up and remove it first)"
    else
        ln -sf "$src" "$dst"
        echo "  link $dst -> $src"
    fi
}

copy_template() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ]; then
        echo "  ok   $dst (already exists)"
    else
        cp "$src" "$dst"
        echo "  copy $dst (from template)"
    fi
}

echo "=== Claude Code: Config files ==="
symlink "$DOTFILES/claude/settings.json"    "$HOME/.claude/settings.json"
symlink "$DOTFILES/claude/CLAUDE.md"        "$HOME/.claude/CLAUDE.md"
symlink "$DOTFILES/claude/keybindings.json" "$HOME/.claude/keybindings.json"

echo ""
echo "=== Claude Code: Directories ==="
symlink "$DOTFILES/claude/rules"    "$HOME/.claude/rules"
symlink "$DOTFILES/claude/commands" "$HOME/.claude/commands"
symlink "$DOTFILES/claude/skills"   "$HOME/.claude/skills"
symlink "$DOTFILES/claude/agents"   "$HOME/.claude/agents"
symlink "$DOTFILES/claude/hooks"    "$HOME/.claude/hooks"
symlink "$DOTFILES/claude/scripts"  "$HOME/.claude/scripts"

echo ""
echo "=== Claude Code: Machine-local config (copy-once, then edit) ==="
copy_template "$DOTFILES/claude/settings.local.json.template" \
              "$HOME/.claude/settings.local.json"
copy_template "$DOTFILES/claude/CLAUDE.local.md.template" \
              "$HOME/.claude/CLAUDE.local.md"

echo ""
echo "=== Claude Code: CLI tools ==="
symlink "$DOTFILES/claude/scripts/cleanup-sessions.py" "$HOME/.local/bin/claude-cleanup"

echo ""
echo "=== MCP ==="
symlink "$DOTFILES/.mcp.json" "$HOME/.mcp.json"

echo ""
echo "=== R Style ==="
symlink "$DOTFILES/.lintr" "$HOME/.lintr"

if ! $SKIP_BASH; then
    echo ""
    echo "=== Bash: Config files ==="
    symlink "$DOTFILES/bash/bash_profile" "$HOME/.bash_profile"
    symlink "$DOTFILES/bash/bashrc"       "$HOME/.bashrc"

    echo ""
    echo "=== Bash: Machine-local config (copy-once, then edit) ==="
    copy_template "$DOTFILES/bash/bashrc.local.template" "$HOME/.bashrc.local"
fi

echo ""
echo "Done."
echo ""
echo "Next steps:"
echo "  1. Edit ~/.bashrc.local                — set GOOGLE_CLOUD_PROJECT and machine-local vars"
echo "  2. Edit ~/.claude/settings.local.json  — set GITHUB_TOKEN and model"
echo "  3. Edit ~/.claude/CLAUDE.local.md      — note machine-specific environment"
echo "  4. Run ~/.claude/scripts/seed-memory.sh from any project root to init memory"
echo "  5. Run ~/.claude/scripts/install-repo-hooks.sh in repos that need lint hooks"
echo ""
echo "To skip bash config on machines with an existing shell setup:"
echo "  bash install.sh --skip-bash"
