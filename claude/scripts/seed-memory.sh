#!/usr/bin/env bash
# Seeds Claude memory files for the current project from templates.
# Run from the project root after cloning on a new machine.
#
# Usage: bash ~/.claude/scripts/seed-memory.sh

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATES="$DOTFILES/claude/memory-templates"

PROJECT_PATH="$(pwd)"
ENCODED="${PROJECT_PATH//\//-}"
MEMORY_DIR="$HOME/.claude/projects/${ENCODED}/memory"

if [ -d "$MEMORY_DIR" ]; then
    echo "Memory directory already exists: $MEMORY_DIR"
    echo "Skipping to avoid overwriting existing memory."
    exit 0
fi

mkdir -p "$MEMORY_DIR"

for template in "$TEMPLATES"/*.md; do
    filename="$(basename "$template")"
    cp "$template" "$MEMORY_DIR/$filename"
    echo "  seeded  $filename"
done

echo ""
echo "Memory seeded at: $MEMORY_DIR"
echo "Edit project_current_phase.md to reflect the current project state."
