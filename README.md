# dotfiles

Personal dotfiles for Claude Code. Managed via symlinks — `install.sh` sets everything up on any machine.

---

## Directory structure

```
.dotfiles/
├── install.sh                          Main installer (symlinks + template copies)
├── .lintr                              → ~/.lintr   Global R style config
├── .mcp.json                           → ~/.mcp.json  MCP server configs (GitHub + placeholders)
└── claude/
    ├── CLAUDE.md                       → ~/.claude/CLAUDE.md   Short index; rules live in rules/
    ├── CLAUDE.local.md.template        Template for machine-specific Claude overrides (gitignored when instantiated)
    ├── settings.json                   → ~/.claude/settings.json  Permissions, hooks, model, status line
    ├── settings.local.json.template    Template for machine-specific settings (gitignored when instantiated)
    ├── keybindings.json                → ~/.claude/keybindings.json  shift+enter / alt+enter = newline
    ├── rules/                          → ~/.claude/rules/   Modular rule files by topic
    │   ├── environment.md              macOS, Bash, direnv, pyenv, worktree safety
    │   ├── tools.md                    gh, jq, gcloud, make, structured output flags
    │   ├── code-style.md               Writing style, shell formatting, no emojis
    │   ├── git.md                      Branch naming, commit discipline, author identity
    │   ├── r-conventions.md            Vectorization, lapply/vapply, lintr style
    │   ├── python.md                   pyenv, ruff, uv
    │   ├── session.md                  Token efficiency, context thresholds, output prefs, compaction
    │   └── core.md                     Core principles, workflow, sub-agent usage
    ├── commands/                       → ~/.claude/commands/  Custom slash commands
    │   ├── seed-project.md             /seed-project — init memory for current project
    │   ├── install-hooks.md            /install-hooks — add pre-commit hooks to current repo
    │   └── coderabbit-fix.md           /coderabbit-fix — process deferred CodeRabbit findings, fix, and commit
    ├── skills/                         → ~/.claude/skills/  Auto-triggered skills (lazy-loaded)
    │   └── ...                         10 custom skills (see Skills section)
    ├── agents/                         → ~/.claude/agents/  Specialized sub-agents
    │   ├── code-reviewer.md            Code review agent (Sonnet, read-only tools)
    │   └── security-auditor.md         Security audit agent (Sonnet, read-only tools)
    ├── hooks/                          → ~/.claude/hooks/  Hook scripts (referenced in settings.json)
    │   ├── cost-guard.sh               PreToolUse: Agent/WebFetch cost transparency
    │   ├── post-edit-lint.sh           PostToolUse: Edit/Write lint (py/sh/R)
    │   ├── maintenance-check.sh        UserPromptSubmit: plan/session maintenance reminders
    │   ├── coderabbit-triage.sh        UserPromptSubmit: CodeRabbit review triage
    │   ├── stop-hook-git-check.sh      Stop: enforce clean git state before session end
    │   └── repo-pre-commit.sh          Stable dispatcher called by repo .git/hooks/pre-commit files
    ├── scripts/                        → ~/.claude/scripts/  Utility scripts
    │   ├── statusline-command.sh       Status bar generator (model, ctx%, tokens, cache, rate limits)
    │   ├── cleanup-sessions.py         → ~/.local/bin/claude-cleanup  Interactive session cleanup
    │   ├── clean-plans.sh              Interactive plan file cleanup
    │   ├── seed-memory.sh              Per-project memory bootstrapper
    │   ├── install-repo-hooks.sh       Pre-commit hook installer; migrates stale hooks automatically
    │   ├── audit-repo-hooks.sh         Finds repos with stale or missing dotfiles hook wiring
    │   ├── r-lint-staged.sh            Pre-commit R lint (called via repo-pre-commit.sh dispatcher)
    │   └── ruff-lint-staged.sh         Pre-commit Python lint/format (called via repo-pre-commit.sh dispatcher)
    └── memory-templates/               Template files for seed-memory.sh (not symlinked — copied per project)
        ├── MEMORY.md
        ├── user_profile.md
        ├── feedback_environment.md
        ├── feedback_plan_mode.md
        ├── feedback_shell_config.md
        ├── reference_global_config.md
        └── project_current_phase.md
```

---

## Setup on a new machine

### 1. Clone the repo

```bash
git clone git@github.com:datasci-iopsy/.dotfiles.git ~/.dotfiles
```

### 2. Clear any conflicting real files

`install.sh` skips files that exist as real files (not symlinks) and prints `SKIP`. Remove and back up any that conflict:

```bash
cp ~/.claude/settings.json ~/.claude/settings.json.bak
rm ~/.claude/settings.json
```

### 3. Run the installer

```bash
bash ~/.dotfiles/install.sh
```

Each line prints `ok` (already linked), `link` (newly created), or `SKIP` (real file present — remove it first).

After running, two files are **copied** (not symlinked) as machine-local config:
- `~/.claude/settings.local.json` — edit to set `GITHUB_TOKEN` and override model if needed
- `~/.claude/CLAUDE.local.md` — fill in machine-specific environment notes

These files are gitignored. They are created from templates on first install and never overwritten by subsequent `install.sh` runs.

### 4. Configure MCP

Edit `~/.mcp.json` (symlinked from `.dotfiles/.mcp.json`) to add your credentials, or set `GITHUB_TOKEN` in `~/.bash_profile` so the `${GITHUB_TOKEN}` expansion in `.mcp.json` resolves at runtime.

### 5. Seed Claude memory for each project

Run once from each project root:

```bash
cd /path/to/project
bash ~/.claude/scripts/seed-memory.sh
```

Then edit `~/.claude/projects/<encoded-path>/memory/project_current_phase.md` to describe the current state.

### 6. Install repo hooks for each project

Run once from each project root:

```bash
cd /path/to/project
bash ~/.claude/scripts/install-repo-hooks.sh
```

Stamps `.git/hooks/pre-commit` with a single call to the stable dispatcher (`repo-pre-commit.sh`). Safe to re-run — detects and migrates stale direct-path references automatically.

To find repos that still have stale or missing hooks across all project directories:

```bash
bash ~/.claude/scripts/audit-repo-hooks.sh
```

---

## Skills

Custom skills live in `claude/skills/`. Each skill is a directory with a `SKILL.md` file. Claude reads descriptions to decide when to activate them automatically (lazy-loaded, no context cost when not in use).

See [`claude/skills/README.md`](claude/skills/README.md) for trigger conditions and full skill reference.

Current skills: `anaiis-agents`, `anaiis-changelog`, `anaiis-copyedit`, `anaiis-docaudit`, `anaiis-duckdb`, `anaiis-gitpr`, `anaiis-litreview`, `anaiis-peerreview`, `anaiis-preflight`, `anaiis-gitrebase`, `graphify`

---

## Commands

Custom slash commands in `claude/commands/` are symlinked to `~/.claude/commands/`. Invoke with `/command-name` in Claude Code.

| Command | What it does |
|---|---|
| `/seed-project` | Init per-project memory files from templates |
| `/install-hooks` | Add R lint and Python ruff pre-commit hooks to a repo |
| `/coderabbit-fix` | Process deferred CodeRabbit findings, fix real defects, and commit by logical group. Pass `--review` to gate commits through the `code-reviewer` agent first |

---

## Rules

Rules live in `claude/rules/` and are symlinked to `~/.claude/rules/`. Claude Code loads `.md` files from this directory at session start. Each file covers a single topic, making them easy to override per-project by adding a matching file in the project's `.claude/rules/`.

| File | Covers |
|---|---|
| `environment.md` | macOS, Bash, direnv, pyenv, worktree safety |
| `tools.md` | gh, jq, gcloud, make, structured output |
| `code-style.md` | Writing style, shell formatting |
| `git.md` | Branch naming, commit discipline |
| `r-conventions.md` | Vectorization, lintr style |
| `python.md` | pyenv, ruff, uv |
| `session.md` | Token efficiency, context thresholds, output prefs |
| `core.md` | Core principles, workflow, sub-agents |

---

## Agents

Specialized sub-agents in `claude/agents/` are available to spawn as focused workers with restricted tools and a cost-efficient model (Sonnet):

- `code-reviewer.md` — reviews diffs for correctness, style, and security. Read/Grep/Glob only.
- `security-auditor.md` — checks for credential exposure, injection risks, insecure patterns. Read/Grep/Glob only.
- `code-surgeon.md` — applies surgical fixes from CodeRabbit triage (rated 4-5). Read/Grep/Glob/Edit only. Spawned per finding with description `Fix CR-<N>: ...`; passes cost-guard automatically.

---

## Git author identity

Git commit authorship for Claude-driven commits is set via environment variables in `claude/settings.json`:

```json
"env": {
  "GIT_AUTHOR_NAME": "datasci-iopsy",
  "GIT_COMMITTER_NAME": "datasci-iopsy"
}
```

Git env vars take precedence over all `git config` settings. The `attribution.commit` field in settings.json controls `Co-Authored-By` trailers only — it does not affect the author name.

---

## Hooks

Hooks are configured in `claude/settings.json`. Scripts live in `claude/hooks/` and are symlinked to `~/.claude/hooks/`.

| Event | Matcher | Script | Behavior |
|---|---|---|---|
| `UserPromptSubmit` | — | `maintenance-check.sh` | Weekly plan check (>10 files or >14 days old); monthly session storage check (>50 MB) |
| `UserPromptSubmit` | — | `coderabbit-triage.sh` | CodeRabbit review triage |
| `PostToolUse` | `Edit\|Write` | `post-edit-lint.sh` | `.py`: ruff check + ruff format; `.sh`: shellcheck; `.sql`: sqlfmt; `.R/.r`: lintr |
| `PreToolUse` | `Write\|Edit` | inline | Blocks writes to `*.lock`, `*.env`, `*credentials*`, `*secret*`, `*.pem`, `*.key` |
| `PreToolUse` | `Bash` | inline | Blocks destructive bq/gcloud/uv commands; warns on Python JSON parsing |
| `PreToolUse` | `Agent\|WebFetch` | `cost-guard.sh` | Cost tiers MEDIUM/HIGH/VERY HIGH; informational for Explore/Plan, gated for general agents |
| `Stop` | — | `stop-hook-git-check.sh` | Blocks session end if uncommitted changes or unpushed commits exist |

All hooks exit 0 unless noted (sensitive file guard and destructive command guard exit 2 to block).

### Repo pre-commit hooks

Repos do not call lint scripts directly. Instead, `.git/hooks/pre-commit` calls a single stable dispatcher:

```bash
bash "$HOME/.claude/hooks/repo-pre-commit.sh"
```

The dispatcher (`claude/hooks/repo-pre-commit.sh`) delegates to `r-lint-staged.sh` and `ruff-lint-staged.sh`. When script paths change inside dotfiles, only the dispatcher needs updating — all repos pick up the change automatically without re-running the installer.

**Maintenance pattern:** after any dotfiles restructuring that moves or renames scripts, update `repo-pre-commit.sh`, then run `audit-repo-hooks.sh` to confirm nothing is stale.

### Adding a hook

Use the `update-config` skill to merge new hooks safely into `settings.json`.

---

## R Style Enforcement

| When | Tool | What it does |
|---|---|---|
| While typing in VS Code | `languageserver` + `lintr` | Inline squiggly underlines |
| On save | `styler` via `formatOnSave` | Auto-fixes mechanical formatting |
| Claude edits a `.R` file | `post-edit-lint.sh` | Reports violations to Claude |
| `git commit` | `repo-pre-commit.sh` dispatcher → `r-lint-staged.sh` | Blocks commit if violations exist |
| PR | CodeRabbit | Reviews against R conventions in CLAUDE.md |

**Config:** `~/.lintr` (symlinked from `.dotfiles/.lintr`) — 17 enabled linters (3 disabled via `= NULL`; 20 total definitions), including native `|>` pipe enforcement via `pipe_consistency_linter`.

**Per-project override:** add `.lintr` in the project root; lintr walks up to find the nearest config.

**Bypass:** `SKIP_R_LINT=1 git commit ...`

---

## SQL Style Enforcement

| When | Tool | What it does |
|---|---|---|
| Claude edits a `.sql` file | `post-edit-lint.sh` | Auto-applies sqlfmt in-place |

**Style:** sqlfmt with `line_length=120`, no jinja formatting. sqlfmt is jinja-aware and preserves Jinja expressions without reformatting them — correct behavior for both dbt and non-dbt SQL.

**Config:** in dbt projects, `[tool.sqlfmt]` in `pyproject.toml` takes precedence. For projects without that config block, the hook defaults to `--line-length 120`.

**Availability:** installed globally via uv. The hook checks PATH then `~/.local/bin/sqlfmt`. Skips silently if not found.

**Install:** `uv tool install shandy-sqlfmt` (no `[jinjafmt]` extra — jinja expressions are preserved as-is). In dbt projects that pin sqlfmt as a dev dependency, the project venv version takes precedence via PATH when the venv is active.

**Bypass:** no bypass flag — sqlfmt auto-fixes and never blocks.

---

## Python Style Enforcement

| When | Tool | What it does |
|---|---|---|
| Claude edits a `.py` file | `post-edit-lint.sh` | `ruff check` (reported) + `ruff format` (auto-applied) |
| `git commit` | `repo-pre-commit.sh` dispatcher → `ruff-lint-staged.sh` | Blocks if lint errors or format drift exists |

**Per-project config:** `[tool.ruff]` in `pyproject.toml` or `ruff.toml`.

**Bypass:** `SKIP_RUFF=1 git commit ...`

---

## Memory system

Per-project memory at `~/.claude/projects/<encoded-path>/memory/`. Seeded from `claude/memory-templates/` via `seed-memory.sh`. Templates are committed to the repo; actual memory directories are machine-local and not tracked.

**Memory types:** `user` (who you are), `feedback` (corrections), `project` (active workstreams), `reference` (where to find things).

**Update process:**
- Passive: Claude saves memories during sessions when it finds something worth preserving.
- End of session: "Update memory with anything worth preserving from this session."
- Manual: Update `project_current_phase.md` when milestones shift.

---

## Per-machine setup (global CLI tools)

`install.sh` handles symlinks only. The following tools must be installed per machine. All hooks, scripts, and skills depend on them being available on PATH or at their standard install locations.

### Homebrew tools

```bash
brew install gh jq shellcheck pyenv ruff
```

| Tool | Used for |
|---|---|
| `gh` | GitHub operations (PRs, issues, checks) |
| `jq` | JSON processing in hooks and scripts |
| `shellcheck` | Shell lint in post-edit hook |
| `pyenv` | Python version management |
| `ruff` | Python lint/format in post-edit hook and pre-commit |

### uv (Python toolchain)

uv is used for Python-only tools not available in Homebrew. Install via Homebrew:

```bash
brew install uv
```

Then install global Python tools via uv. These land at `~/.local/bin/`:

```bash
uv tool install shandy-sqlfmt
```

| Tool | Used for |
|---|---|
| `sqlfmt` | SQL format in post-edit hook (line_length=120, no jinja reformatting) |

### Python CLI tools (pipx)

```bash
# Bootstrap pipx under the tools Python
~/.pyenv/versions/3.12.12/bin/python -m pip install pipx

# graphify (PyPI name is "graphifyy" — double y)
~/.pyenv/versions/3.12.12/bin/python -m pipx install graphifyy \
  --python ~/.pyenv/versions/3.12.12/bin/python
```

---

## Per-machine setup (R tools)

```r
install.packages(c("lintr", "styler", "languageserver"))
```

These are global installs (not renv-managed) so they are available across all repos.

---

## Adding new dotfiles

1. Move the file into `~/.dotfiles/<category>/`
2. Add a `symlink` line to `install.sh`
3. Create the symlink manually: `ln -sf ~/.dotfiles/<category>/<file> <dst>`
4. Commit and push
