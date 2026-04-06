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
- Check for a project CLAUDE.md and subdirectory CLAUDE.md files before starting work.

## Writing style
- Never use em dashes. Use commas, semicolons, parentheses, or separate sentences.
- Never use causal framing ("This is because..."). State the fact directly.
- No emojis in code, comments, commit messages, or prose unless requested.
- Commit messages: imperative mood, concise, no trailing period.

## Token efficiency
- Do not re-read files already in context.
- Use targeted reads (offset/limit) for files over 200 lines.
- Use Glob and Grep to narrow before Read. Do not read entire files speculatively.
- Chain independent read-only shell commands with && in a single Bash call.
- Be direct. Skip preamble ("Great question!", "Sure, I can help with that").

## Git workflow
- Task branches: `<base>--claude-<topic>` naming convention.
- Always create new commits. Never amend unless explicitly asked.
- Never force-push. Never skip hooks (--no-verify).
- Stage files by name, not `git add -A` or `git add .`.
