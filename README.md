# dotfiles

Personal dotfiles. Managed via symlinks — `install.sh` sets everything up.

## Setup on a new machine or profile

### 1. Clone the repo

```bash
git clone git@github.com:<your-username>/dotfiles.git ~/.dotfiles
```

### 2. Clear any pre-existing real files

`install.sh` will skip files that already exist as real files (not symlinks). Remove them first so the symlinks can be created. Back up anything you want to preserve.

```bash
# Example for Claude config — check install.sh for the full list of targets
cp ~/.claude/settings.json ~/.claude/settings.json.bak   # optional backup
rm ~/.claude/settings.json
```

Repeat for any other files listed in `install.sh` that already exist on the machine.

### 3. Run the installer

```bash
bash ~/.dotfiles/install.sh
```

Each line will print `ok` (already linked), `link` (newly created), or `SKIP` (real file still exists — go back to step 2 for those).

### 4. Seed Claude memory for each project

Memory is stored per project, keyed by the project's absolute path. Run this once from each project root before your first Claude session on this machine:

```bash
cd /path/to/project
bash ~/.dotfiles/claude/seed-memory.sh
```

Then edit `~/.claude/projects/<encoded-path>/memory/project_current_phase.md` to reflect the current state of that project.

> Note: seeding is safe to skip for the dotfiles repo itself — you only need it for projects where you'll be doing active Claude-assisted work.

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
