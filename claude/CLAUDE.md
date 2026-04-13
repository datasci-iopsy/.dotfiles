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
- Git author identity is enforced via `GIT_AUTHOR_NAME`/`GIT_COMMITTER_NAME` in the harness `env` block (`~/.claude/settings.json`). The `attribution.commit` setting controls only `Co-Authored-By` trailers, not the author name.

## Workflow
- Before starting: if a request has multiple valid interpretations, surface them and ask -- don't pick silently. If something is unclear, name what's confusing before proceeding.
- Before starting non-trivial tasks: state the verifiable success criteria (what "done" looks like and how it will be confirmed), not just the steps.
- While in plan mode, if something goes sideways mid-task, stop and re-plan -- don't keep pushing.
- Use subagents liberally to keep the main context window clean. Offload research, exploration, and parallel analysis to subagents. One task per subagent for focused execution.
- Never mark a task complete without proving it works. Run tests, check logs, demonstrate correctness.
- For non-trivial changes, consider if there's a simpler approach. Skip for obvious fixes.
- For bugs, just fix them. Point at evidence, resolve.

## R programming

**Default to vectorization over for-loops.** R's built-in vectorized operations run in compiled C/Fortran and are substantially faster than R-level loops at any meaningful data size.

**Vectorization preference hierarchy (highest to lowest):**
1. Built-in vectorized functions: `+`, `*`, `sqrt()`, `sum()`, `rowSums()`, `colMeans()`, `paste0()`, etc.
2. `lapply()` / `vapply()` over lists -- these dispatch via C, not R-level loops. Prefer `vapply()` over `sapply()` in performance-sensitive code (pre-specified output type, faster).
3. Pre-allocated for-loop when vectorization is impossible: always initialize output before the loop (`out <- numeric(length(x))`), never grow inside the loop.
4. Rcpp for sequential-dependent or compute-intensive logic that exceeds R-level vectorization.

**Do NOT use a for-loop when:** the operation is element-wise arithmetic, a math function, or a simple transformation on a vector -- use the vectorized built-in instead.

**Use a for-loop (or Rcpp) when:**
- Each iteration depends on the previous result (sequential dependency -- vectorization is structurally impossible).
- Early exit via `break` or `next` is needed (vectorized operations evaluate all elements).
- Multi-branch conditional logic per row is complex enough that nested `ifelse()` is harder to read and debug than an explicit loop.

**Avoid `apply()` on data frames.** It coerces to matrix and uses an R-level loop internally. Use `lapply()`, `vapply()`, or column-wise vectorized functions instead. `rowSums()` / `colMeans()` are faster than `apply(df, 1/2, sum/mean)`.

**Profile before optimizing.** For small `n` (< ~1,000) or when each iteration is expensive (model fit, I/O), the loop vs. vectorization distinction is negligible. Don't vectorize for its own sake when correctness and readability are clearer in a loop.

## Core principles
- **Simplicity first**: Make every change as simple as possible. Minimal code impact.
- **Find root causes**: No temporary fixes. Senior developer standards.
- **Minimal impact**: Only touch what's necessary. Avoid introducing bugs. Remove imports, variables, or functions YOUR changes made unused -- but don't remove pre-existing dead code unless asked.

## Compaction

Preserve: current task state (decisions, files changed, why), active worktree/branch, mid-session corrections (override CLAUDE.md for remainder of session), open errors/blockers, memory writes.

Compress: file contents (key finding only), tool output chains (conclusion only), ruled-out paths.

`/compact <prompt>` overrides these defaults.
