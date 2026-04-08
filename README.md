# dotfiles

Personal dotfiles for Claude Code. Managed via symlinks -- `install.sh` sets everything up.

## Setup on a new machine

### 1. Clone the repo

```bash
git clone git@github.com:<your-username>/dotfiles.git ~/.dotfiles
```

### 2. Clear any pre-existing real files

`install.sh` skips files that already exist as real files (not symlinks). Remove them first so symlinks can be created. Back up anything you want to preserve.

```bash
# Example for Claude config
cp ~/.claude/settings.json ~/.claude/settings.json.bak   # optional backup
rm ~/.claude/settings.json
```

Repeat for any other files listed in `install.sh` that already exist on the machine.

### 3. Run the installer

```bash
bash ~/.dotfiles/install.sh
```

Each line prints `ok` (already linked), `link` (newly created), or `SKIP` (real file still exists -- go back to step 2 for those).

### 4. Seed Claude memory for each project

Memory is stored per project, keyed by the project's absolute path. Run this once from each project root before your first Claude session on that machine:

```bash
cd /path/to/project
bash ~/.dotfiles/claude/seed-memory.sh
```

Then edit `~/.claude/projects/<encoded-path>/memory/project_current_phase.md` to describe the current state of that project.

> Seeding is not needed for the dotfiles repo itself -- only for projects where you do active Claude-assisted work.

---

## What gets installed

```
claude/
  settings.json         → ~/.claude/settings.json          Global permissions, hooks, model, status line
  CLAUDE.md             → ~/.claude/CLAUDE.md              Global instructions loaded in every session
  keybindings.json      → ~/.claude/keybindings.json       Custom key bindings
  statusline-command.sh → ~/.claude/statusline-command.sh  Status bar script (see below)
  skills/               → ~/.claude/skills/                All custom skills (symlinked as a directory)
  cleanup-sessions.py   → ~/.local/bin/claude-cleanup      Interactive session cleanup CLI
  seed-memory.sh                                           Per-project memory bootstrapper (not symlinked)
```

---

## Skills

Custom skills live in `claude/skills/`. Each skill is a directory containing a `SKILL.md` file. Claude reads skill descriptions to decide when to activate them automatically.

See [`claude/skills/README.md`](claude/skills/README.md) for the full skill reference, trigger conditions, and instructions for adding new skills.

Current skills: `anaiis-agents`, `anaiis-duckdb`, `anaiis-litreview`, `anaiis-peerreview`, `anaiis-preflight`, `anaiis-changelog`, `anaiis-docaudit`, `graphify`

---

## Hooks

Hooks are configured in `claude/settings.json` under the `hooks` key. They run shell commands at specific points in Claude's lifecycle -- before tool execution, after writes, etc.

### Active hooks

**PreToolUse: Write|Edit -- sensitive file guard**
Blocks writes to files matching `*.lock`, `*.env`, `*credentials*`, `*secret*`, `*.pem`, `*.key`. Hard block (exit 2).

**PreToolUse: Bash -- jq over Python warning**
Fires when a Bash command contains `python`/`python3` AND `import json`, `json.loads`, or `json.dumps`. Emits a warning recommending `jq` instead. Soft warning (exit 1) -- not a hard block, since complex Python+JSON transforms are legitimate.

### Adding a hook

Use the `update-config` skill: describe the behavior you want and it will read the existing file, construct and test the command, then merge it in safely. Review the result in `/hooks`.

---

## Scripts

### `claude-cleanup`

Interactive session cleanup tool. Lists all Claude sessions across all projects, sorted by your chosen criteria, and lets you select which to delete.

```bash
claude-cleanup                     # sort by disk size (largest first)
claude-cleanup --sort age          # sort by age (oldest first)
claude-cleanup --sort tokens       # sort by last context window size
claude-cleanup --older-than 30     # only sessions unused for 30+ days
claude-cleanup --dry-run           # preview without deleting
```

**Columns in the output:**

| Column | Meaning |
|--------|---------|
| Size | On-disk file size of the full session transcript |
| Ctx | Effective input tokens at the last assistant turn (input + cache_read + cache_creation). Approximates how large the context window was at the end. Low Ctx on a large file means the session was compacted -- healthy. |
| Msgs | Number of user turns |
| Title | Custom session title, or first user message if untitled. `<local-command-caveat>` titles are IDE injection artifacts, not real titles. |

**Workflow:** the list appears, enter numbers like `1,3,5-8` or `all`, review the confirmation summary, type `y` to delete.

**Before deleting heavy sessions:** if a session contained important decisions not captured in git or code, run "Update memory with anything worth preserving from this session" in that project first. See the Memory section below.

---

### `seed-memory.sh`

Bootstraps a memory directory for a project at `~/.claude/projects/<encoded-path>/memory/`. Creates six starter files: user profile, environment feedback, plan mode feedback, shell config feedback, global config reference, and a current phase stub.

Run it once per project per machine. It is safe to re-run -- it exits immediately if the memory directory already exists.

After seeding, always fill in `project_current_phase.md` manually with the active workstream and current state.

---

### `statusline-command.sh`

Generates the rich status bar shown at the bottom of Claude Code sessions. Reads Claude session JSON from stdin and outputs a compact colored line.

**Segments displayed:**

| Segment | Color | Meaning |
|---------|-------|---------|
| `sonnet-4.6` | cyan | Active model (shortened from full model ID) |
| `ctx:42%` | green | Context window used percentage |
| `tok:18k+2k` | green dim | Input + output token counts for this turn |
| `cache:45k` | blue | Cache read tokens (shown when >= 1000) |
| `5h:31%` | magenta | 5-hour rate limit usage |
| `7d:85%` | magenta dim | 7-day rate limit usage |

Fails silently if `jq` is unavailable or the input is malformed.

---

## Memory system

Claude maintains persistent memory files per project at `~/.claude/projects/<encoded-path>/memory/`. These are loaded fresh at the start of every session and provide stable context without re-reading session history.

**Memory types:** `user` (who you are), `feedback` (corrections and confirmed approaches), `project` (active workstreams), `reference` (where to find things).

**Update process:**

- **Passive:** Claude saves memories during sessions when it encounters something non-obvious worth preserving.
- **End of session:** For substantive sessions, ask: "Update memory with anything worth preserving from this session." ~5-10k tokens.
- **Manual:** Update `project_current_phase.md` yourself when milestones shift.

Memory, session history, and compaction are independent. Compaction summarizes the current session for continuity within that session only. Memory persists across sessions. Session history persists on disk until deleted via `claude-cleanup`.

---

## Per-machine setup (Python CLI tools)

`install.sh` handles symlinks only. Python-based CLI tools must be installed per machine because they carry native compiled dependencies. Run these once after cloning and running `install.sh`.

**Prerequisites:** `pyenv` with Python 3.12.12 installed (`pyenv install 3.12.12`).

```bash
# Bootstrap pipx under the tools Python (3.12.12 is the designated tools version)
~/.pyenv/versions/3.12.12/bin/python -m pip install pipx

# graphify -- codebase knowledge graph generator (https://github.com/safishamsi/graphify)
~/.pyenv/versions/3.12.12/bin/python -m pipx install graphifyy \
  --python ~/.pyenv/versions/3.12.12/bin/python
```

The `graphify` binary lands in `~/.local/bin/graphify`, which is already on PATH. The skill file is tracked in the dotfiles repo and registered automatically via the `skills/` symlink. No `graphify install` needed.

> Use `~/.pyenv/versions/3.12.12/bin/python -m pipx install <pkg>` for any future Python CLI tools. This pins each tool to 3.12.12 and keeps them isolated from project virtualenvs (like dbt's 3.12.4).

---

## Adding new dotfiles

1. Move the file into `~/.dotfiles/<category>/`
2. Add a `symlink` line to `install.sh`
3. Commit and push
