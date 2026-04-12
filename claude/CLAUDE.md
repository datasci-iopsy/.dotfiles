# Global Claude Instructions

## Environment
- macOS, Bash shell. Config is exclusively `~/.bash_profile` (never .zshrc or .bashrc).
- `direnv` manages per-project env vars via `.envrc` — loads automatically on cd.
- `pyenv` manages Python versions. Check `.python-version` before assuming Python version.

## Tool preferences
- Use `gh` for all GitHub operations (PRs, issues, checks) — never raw curl to the API.
- Use `jq` for JSON processing in shell.
- Use `gcloud` for GCP operations (read-only unless user confirms).
- Prefer `make` targets over raw commands when a Makefile exists.
- Check for project and subdirectory CLAUDE.md files before starting work.
- When invoking CLIs that support structured output, always use their JSON or machine-readable flag. Never parse tabular stdout. Known flags: `gh` (`--json`), `gcloud` (`--format=json`), `bq` (`--format=json`), `dbt` (`--output json`), `duckdb` (`-json`). For any other CLI, check for a `--format`, `--output`, or `--json` flag before running and use it if available.

## Shell command formatting
- Multi-line commands with backslash continuations are fine for readability. Only split at argument or flag boundaries, never inside a quoted string. A backslash continuation must appear outside of all quotes -- breaking a quoted string across lines causes bash to treat the continuation lines as separate commands, not as part of the string. When in doubt, print the command on a single line rather than risk splitting inside a quote.
- In code blocks containing shell commands, do not indent the command itself. Keep it flush-left within the block.

## Writing style
- Never use em dashes. Use commas, semicolons, parentheses, or separate sentences.
- Never use causal framing ("This is because..."). State the fact directly.
- No emojis in code, comments, commit messages, or prose unless requested.
- Commit messages: imperative mood, concise, no trailing period.

## Token efficiency
- Do not re-read files already in context.
- Use targeted reads (offset/limit) for files over 200 lines.
- Use Glob and Grep to narrow before Read. Do not read entire files speculatively. Never use Bash(grep), Bash(rg), or Bash(find) for file or content search; use the Grep and Glob tools instead.
- Chain independent read-only shell commands with && in a single Bash call.
- Be direct. Skip preamble ("Great question!", "Sure, I can help with that").
- Prefer Read over Bash(cat) unless piping (e.g., cat file | jq).
- Never use head or tail via Bash; use Read with offset/limit instead.

## Session discipline
- One deliverable per session. If scope shifts (e.g., planning to implementation), ask whether to continue or start fresh.
- When context exceeds 60%, prefer file-based output and avoid spawning new agents.
- When context exceeds 80%, proactively suggest starting a new session.
- Do not re-explore what was already explored in this session. Summarize prior findings from context.

## Environment safety
- Before modifying Python venvs or dependencies, identify all venvs in the project and confirm which is active. Never modify venv contents without mapping the environment first.
- When working in projects with worktrees, confirm which worktree/directory you're in before running commands.

## Output preferences
- Write long-form content (proposals, reviews, reports) to a file, not terminal.
- Default to terse output for: confirmations, status updates, progress reports, summaries of completed work, and explanations of simple changes. One to three sentences unless the user asks for detail.
- This terse default does NOT apply when: executing a skill (/anaiis-*, /graphify), in plan mode, producing file-based deliverables, or when the user explicitly asks for explanation.
- When asked "what did you do?", summarize in 2-3 bullet points. Offer detail only if the change was non-obvious.

## Git workflow
- Task branches: `<base>--claude-<topic>` naming convention.
- Always create new commits. Never amend unless explicitly asked.
- Never force-push. Never skip hooks (--no-verify).
- Stage files by name, not `git add -A` or `git add .`.

## Workflow
- While in plan mode, if something goes sideways mid-task, stop and re-plan -- don't keep pushing.
- Use subagents liberally to keep the main context window clean. Offload research, exploration, and parallel analysis to subagents. One task per subagent for focused execution.
- Never mark a task complete without proving it works. Run tests, check logs, demonstrate correctness.
- For non-trivial changes, consider if there's a simpler approach. Skip for obvious fixes.
- For bugs, just fix them. Point at evidence, resolve.

## Core principles
- **Simplicity first**: Make every change as simple as possible. Minimal code impact.
- **Find root causes**: No temporary fixes. Senior developer standards.
- **Minimal impact**: Only touch what's necessary. Avoid introducing bugs.

## Compaction

When compacting, preserve:
- **Current task state**: what was being worked on, decisions made, files changed and why
- **Worktree and branch context**: which worktree or directory was active -- losing this causes recurring friction
- **Mid-session corrections**: any style or approach corrections the user made during the session (these take priority over CLAUDE.md defaults for the remainder of the session)
- **Active findings**: open errors, blockers, or unresolved items
- **Memory writes**: any memories written or updated during the session

Compress aggressively:
- Full file contents that were read -- note the file and the key finding only
- Tool output chains where only the conclusion matters
- Exploratory paths that were ruled out

User override: explicit instructions passed via `/compact <prompt>` take priority over these defaults.
