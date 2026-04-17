# Git Workflow

- Task branches: `<base>--claude-<topic>` naming convention.
- Always create new commits. Never amend unless explicitly asked.
- Never force-push. Never skip hooks (--no-verify).
- Stage files by name, not `git add -A` or `git add .`.
- Git author identity is enforced via `GIT_AUTHOR_NAME`/`GIT_COMMITTER_NAME` in the harness `env` block (`~/.claude/settings.json`). The `attribution.commit` setting controls only `Co-Authored-By` trailers, not the author name.
