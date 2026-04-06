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

install.sh               Symlinks all dotfiles into place (safe to re-run)
```

## Adding new dotfiles

1. Move the file into `~/.dotfiles/<category>/`
2. Add a `symlink` line to `install.sh`
3. Commit and push
