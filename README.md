# dotfiles

Personal dotfiles. Managed via symlinks — `install.sh` sets everything up.

## Setup on a new machine

```bash
git clone git@github.com:<your-username>/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/install.sh
```

Then seed Claude memory for each project:

```bash
cd /path/to/project
bash ~/.dotfiles/claude/seed-memory.sh
```

## Contents

```
claude/
  settings.json          → ~/.claude/settings.json
  CLAUDE.md              → ~/.claude/CLAUDE.md
  statusline-command.sh  → ~/.claude/statusline-command.sh
  keybindings.json       → ~/.claude/keybindings.json
  seed-memory.sh         Seeds ~/.claude/projects/<project>/memory/ for a project
  cleanup-session.py	 → ~/.claude/cleanup-session.py

install.sh               Symlinks all dotfiles into place (safe to re-run)
```

To run a cleanup process for Claude sessions:

```bash
claude-cleanup                  # sort by size (largest first)
claude-cleanup --sort age       # sort by age (oldest first)
claude-cleanup --older-than 30  # only sessions unused for 30+ days
claude-cleanup --dry-run        # preview without deleting
```

The workflow: list appears → enter numbers like 1,3,5-8 or all → confirmation summary → type y to delete.
A few things worth noting -- some sessions may have `<local-command-caveat>` as their title (that's the IDE injection text, not a real title).

## Adding new dotfiles

1. Move the file into `~/.dotfiles/<category>/`
2. Add a `symlink` line to `install.sh`
3. Commit and push
