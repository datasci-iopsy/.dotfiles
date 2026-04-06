#!/usr/bin/env bash
# ~/.dotfiles/claude/seed-memory.sh
# Seeds Claude memory files for the current project.
# Run from the project root after cloning on a new machine.
#
# Usage: bash ~/.dotfiles/claude/seed-memory.sh

set -euo pipefail

# Derive the Claude project directory name from the current working directory
# (matches Claude Code's path-encoding: slashes become hyphens, prefixed with -)
PROJECT_PATH="$(pwd)"
ENCODED="${PROJECT_PATH//\//-}"
MEMORY_DIR="$HOME/.claude/projects/${ENCODED}/memory"

if [ -d "$MEMORY_DIR" ]; then
    echo "Memory directory already exists: $MEMORY_DIR"
    echo "Skipping to avoid overwriting existing memory."
    exit 0
fi

mkdir -p "$MEMORY_DIR"

# --- MEMORY.md index ---
cat > "$MEMORY_DIR/MEMORY.md" << 'EOF'
# Memory Index

- [user_profile.md](user_profile.md) — PhD researcher role, interaction style, session preferences
- [feedback_environment.md](feedback_environment.md) — Never modify dependencies without mapping active environments first
- [feedback_plan_mode.md](feedback_plan_mode.md) — Plan mode usage: when to plan vs execute immediately
- [feedback_shell_config.md](feedback_shell_config.md) — Default shell config is ~/.bash_profile; ignore .zshrc and .bashrc
- [reference_global_config.md](reference_global_config.md) — Global settings.json and CLAUDE.md scope
- [project_current_phase.md](project_current_phase.md) — Current project phase (update manually)
EOF

# --- user_profile.md ---
cat > "$MEMORY_DIR/user_profile.md" << 'EOF'
---
name: User Profile
description: PhD researcher's role, expertise, and Claude Code interaction preferences
type: user
---

PhD candidate researching within-person fluctuation in burnout, need frustration, and turnover intentions.
Multi-language expertise: Python (GCP pipelines, Cloud Run), R (power analysis, multilevel modeling), Shell.
Deep infrastructure knowledge — manages Poetry, renv, Makefiles, GCP deploy scripts.

Works afternoons/evenings PT. Prefers tightly scoped sessions (~7 messages average).
Uses opusplan model. 97% goal achievement rate — current workflow patterns are effective.
Batches and reviews changes carefully before committing.
Holds Claude to precise stylistic standards in dissertation writing (no causal framing, no em dashes).
EOF

# --- feedback_environment.md ---
cat > "$MEMORY_DIR/feedback_environment.md" << 'EOF'
---
name: Environment Safety
description: Never modify dependencies without understanding the full environment setup first
type: feedback
---

Before modifying dependencies (Poetry, renv, pip), identify ALL virtual environments and their relationships.
**Why:** An aiohttp Dependabot fix cascaded into venv corruption because Claude didn't detect a dual-venv setup. User described Claude as "lost in the sauce."
**How to apply:** Run `poetry env info --path` and check `.python-version` before any dependency change. Never assume there is only one venv.
EOF

# --- feedback_plan_mode.md ---
cat > "$MEMORY_DIR/feedback_plan_mode.md" << 'EOF'
---
name: Plan Mode Usage
description: When to use plan mode vs execute immediately — user has interrupted both ways
type: feedback
---

Use Plan mode for multi-file or multi-step tasks. For simple, single-action tasks (git restore, quick lookups), execute directly.
**Why:** User interrupted Claude twice wanting to approve plans first, but also got frustrated when plan mode blocked simple git restore commands.
**How to apply:** If the task is < 3 steps and clearly scoped, execute. If it touches multiple files or has ambiguous scope, plan first.
EOF

# --- feedback_shell_config.md ---
cat > "$MEMORY_DIR/feedback_shell_config.md" << 'EOF'
---
name: Shell Config File
description: User's default shell config is .bash_profile — do not read .zshrc or .bashrc
type: feedback
---

Default shell configuration file is `~/.bash_profile`. Do not read or modify `.zshrc` or `.bashrc`.
**Why:** User uses bash, not zsh. Reading other shell configs is unnecessary overhead and potentially confusing.
**How to apply:** Any time shell prompt, aliases, env vars, or PATH changes are needed, go straight to `~/.bash_profile`.
EOF

# --- reference_global_config.md ---
cat > "$MEMORY_DIR/reference_global_config.md" << 'EOF'
---
name: Global Claude Config
description: Global settings.json and CLAUDE.md scope — set up via dotfiles
type: reference
---

Global config at `~/.claude/settings.json` and `~/.claude/CLAUDE.md` (symlinked from ~/.dotfiles/claude/).
**Why:** Avoids re-granting universal permissions per project and re-explaining preferences every session.
**How to apply:** Project settings.local.json only needs project-specific additions (e.g., poetry, project-specific scripts). Do not re-add globally permitted tools to project-local settings.

Key global permissions: Read, Write, git, python/python3, ls, tree, grep, find, cat, head, tail, wc, diff, sort, make, gh, jq, gcloud (read-only), WebSearch, WebFetch(docs.coderabbit.ai).
Global hook: PreToolUse guard blocks writes to *.lock, *.env, *credentials*, *secret*, *.pem, *.key.
EOF

# --- project_current_phase.md (stub — fill in manually) ---
cat > "$MEMORY_DIR/project_current_phase.md" << 'EOF'
---
name: Current Project Phase
description: Active project workstreams and state (update manually when milestones change)
type: project
---

[Update this file after seeding with current project state.]

**Why:** Knowing the active phase prevents Claude from suggesting work on completed milestones.
**How to apply:** Update when milestones are reached or focus shifts.
EOF

echo "Memory seeded at: $MEMORY_DIR"
echo "Edit project_current_phase.md to reflect the current project state."
