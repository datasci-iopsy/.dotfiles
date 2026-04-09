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

### 5. Install repo hooks for each project

Each project needs its pre-commit hook wired up. Run this once from each project root:

```bash
cd /path/to/project
bash ~/.claude/install-repo-hooks.sh
```

This adds R lint enforcement to the pre-commit hook. Safe to re-run -- skips if already in place. See the [R Style Enforcement](#r-style-enforcement) section for the full picture.

---

## What gets installed

```
claude/
  settings.json           → ~/.claude/settings.json          Global permissions, hooks, model, status line
  CLAUDE.md               → ~/.claude/CLAUDE.md              Global instructions loaded in every session
  keybindings.json        → ~/.claude/keybindings.json       Custom key bindings
  statusline-command.sh   → ~/.claude/statusline-command.sh  Status bar script
  cost-guard.sh           → ~/.claude/cost-guard.sh          Agent cost transparency hook
  post-edit-lint.sh       → ~/.claude/post-edit-lint.sh      PostToolUse lint hook (py/sh/R)
  r-lint-staged.sh        → ~/.claude/r-lint-staged.sh       Pre-commit R lint for any repo
  install-repo-hooks.sh   → ~/.claude/install-repo-hooks.sh  One-command hook installer for new repos
  skills/                 → ~/.claude/skills/                All custom skills (symlinked as a directory)
  cleanup-sessions.py     → ~/.local/bin/claude-cleanup      Interactive session cleanup CLI
  seed-memory.sh                                             Per-project memory bootstrapper (not symlinked)

.lintr                    → ~/.lintr                         Global R style config (tidyverse + native pipe)
```

---

## Skills

Custom skills live in `claude/skills/`. Each skill is a directory containing a `SKILL.md` file. Claude reads skill descriptions to decide when to activate them automatically.

See [`claude/skills/README.md`](claude/skills/README.md) for the full skill reference, trigger conditions, and instructions for adding new skills.

Current skills: `anaiis-agents`, `anaiis-changelog`, `anaiis-copyedit`, `anaiis-docaudit`, `anaiis-duckdb`, `anaiis-litreview`, `anaiis-peerreview`, `anaiis-preflight`, `graphify`

---

## Hooks

Hooks are configured in `claude/settings.json` under the `hooks` key. They run shell commands at specific points in Claude's lifecycle.

### Active hooks

**PostToolUse: Edit|Write -- lint on save (`post-edit-lint.sh`)**
Runs after every file edit or write. Lints by file type:
- `.py` -- `ruff check` (first 5 findings)
- `.sh` -- `shellcheck --severity=warning` (first 5 findings)
- `.R` / `.r` -- `lintr::lint()` using `~/.lintr` config (first 10 findings)

Always exits 0 -- informational only, never blocks Claude. Uses `--no-init-file` for R to bypass `renv`'s `.Rprofile` and use the global lintr installation.

**PreToolUse: Write|Edit -- sensitive file guard**
Hard-blocks (exit 2) writes to files matching `*.lock`, `*.env`, `*credentials*`, `*secret*`, `*.pem`, `*.key`.

**PreToolUse: Bash -- jq over Python warning**
Fires when a Bash command contains Python JSON parsing (`import json`, `json.loads`, `json.dumps`). Emits a soft warning (exit 1) recommending `jq` instead.

**PreToolUse: Agent|WebFetch -- cost guard (`cost-guard.sh`)**
Shows estimated token cost before agent spawns or WebFetch calls. Explore/Plan agents: informational only (exit 0). General-purpose agents: soft gate requiring user confirmation (exit 1) with a cost tier (MEDIUM/HIGH/VERY HIGH) and token range estimate.

### Adding a hook

Use the `update-config` skill: describe the behavior you want and it will read the existing file, construct and test the command, then merge it in safely.

---

## R Style Enforcement

R files are held to the [tidyverse style guide](https://style.tidyverse.org) using the native `|>` pipe. Enforcement is automatic at every layer -- nothing needs to be in your working memory.

### Enforcement chain

| When | Tool | What it does |
|------|------|-------------|
| While typing in VS Code | `languageserver` + `lintr` | Inline squiggly underlines on violations |
| On save (Cmd+S) | `styler` via `formatOnSave` | Auto-fixes mechanical formatting |
| Claude edits a `.R`/`.r` file | `post-edit-lint.sh` hook | Reports remaining violations to Claude |
| `git commit` | `r-lint-staged.sh` pre-commit | Blocks commit, lists all violations |
| PR open/push | CodeRabbit | Reviews against project CLAUDE.md R conventions |

**styler** fixes: spacing, indentation, brace placement, comma spacing, infix operators.
**lintr** reports: `=` vs `<-`, camelCase names, `%>%` vs `|>`, `T`/`F`, explicit `return()`, `&`/`|` in conditions.

### Style config (`~/.lintr`)

The global `~/.lintr` config (symlinked from `.dotfiles/.lintr`) applies to every R project on this machine. It encodes 17 rules:

- `object_name_linter("snake_case")` -- snake_case names only
- `assignment_linter()` -- use `<-`, never `=`
- `line_length_linter(80L)` -- 80-character max
- `indentation_linter(2L)` -- 2-space indent
- `commas_linter()` -- space after commas
- `infix_spaces_linter()` -- spaces around operators
- `spaces_inside_linter()` -- no spaces inside `()` or `[]`
- `brace_linter()` -- `{` at end of line, `}` on its own line
- `pipe_continuation_linter()` -- `|>` continuation on a new line
- `pipe_consistency_linter(pipe = "|>")` -- flag `%>%`
- `quotes_linter()` -- double quotes only
- `semicolon_linter()` -- no semicolons
- `trailing_whitespace_linter()` -- no trailing whitespace
- `vector_logic_linter()` -- `&&`/`||` in `if`, not `&`/`|`
- `function_return_linter()` -- no unnecessary explicit `return()`
- `implicit_assignment_linter()` -- no assignment inside function args
- `T_and_F_symbol_linter()` -- `TRUE`/`FALSE` not `T`/`F`

**Per-project overrides:** add a `.lintr` file in the project root. lintr walks up from the file to find the nearest config. Use `# nolint` inline to suppress individual findings.

### Adding R lint to a new repo

```bash
cd /path/to/repo
bash ~/.claude/install-repo-hooks.sh
```

If you forget, the `anaiis-preflight` skill will flag it when you run a health check.

### Bypass when needed

```bash
SKIP_R_LINT=1 git commit -m "..."
```

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

Run it once per project per machine. Safe to re-run -- exits immediately if the memory directory already exists.

After seeding, always fill in `project_current_phase.md` manually with the active workstream and current state.

---

### `install-repo-hooks.sh`

Adds standard pre-commit hooks to the current git repo. Creates `.git/hooks/pre-commit` if it does not exist, or appends to it if it does. Checks if each hook is already present before adding it.

Currently installs: R lint via `r-lint-staged.sh`.

Run once per repo per machine:

```bash
cd /path/to/repo
bash ~/.claude/install-repo-hooks.sh
```

---

### `r-lint-staged.sh`

Shared R lint script for pre-commit hooks. Runs `lintr` on all staged `.R`/`.r` files using the global `~/.lintr` config. Uses `Rscript --no-init-file` to bypass `renv`'s `.Rprofile`, ensuring the global lintr installation is used regardless of which project you are in.

Exits 1 (blocks commit) if any findings exist. Exits 0 (passes) if the files are clean or no R files are staged.

Bypass: `SKIP_R_LINT=1 git commit ...`

Not called directly -- invoked by each repo's `.git/hooks/pre-commit` via `install-repo-hooks.sh`.

---

### `post-edit-lint.sh`

PostToolUse hook called automatically by Claude after every `Edit` or `Write` tool call. Dispatches by file extension to the appropriate linter and surfaces findings back to Claude.

Not called directly -- configured in `claude/settings.json` under `hooks.PostToolUse`.

---

### `cost-guard.sh`

PreToolUse hook for `Agent` and `WebFetch` tool calls. Estimates token cost and either informs (Explore/Plan agents, WebFetch) or gates (general-purpose agents) before proceeding.

Cost tiers: MEDIUM (5k-25k), HIGH (15k-80k), VERY HIGH (50k-150k).

Not called directly -- configured in `claude/settings.json` under `hooks.PreToolUse`.

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

**What belongs in memory vs not:**

| Save | Skip |
|------|------|
| Hard-won lessons (e.g., "never modify venvs without mapping all environments first") | Anything derivable from code or `git log` |
| User preferences and working style | Completed task artifacts (copyedit reports, session summaries) |
| External resource pointers (Linear project IDs, dashboards) | Design notes for work that is already shipped |
| Non-obvious project state (pipeline status, active workstreams) | Git history summaries |

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

> Use `~/.pyenv/versions/3.12.12/bin/python -m pipx install <pkg>` for any future Python CLI tools. This pins each tool to 3.12.12 and keeps them isolated from project virtualenvs.

---

## Per-machine setup (R tools)

R packages (`lintr`, `styler`, `languageserver`) are installed per machine. Run once after cloning:

```r
install.packages(c("lintr", "styler", "languageserver"))
```

These are global packages (not project-isolated via renv) so they are available across all repos for linting and language server features.

VS Code format-on-save is configured in the user-level `settings.json` (already set globally, not per-project).

---

## Adding new dotfiles

1. Move the file into `~/.dotfiles/<category>/`
2. Add a `symlink` line to `install.sh`
3. Create the symlink manually (`ln -sf`) without waiting for a full re-run
4. Commit and push
