# Global Claude Instructions

This file provides project context and author identity. Detailed rules live in `~/.claude/rules/`.

## Project context
Research and data science workflows (I-O Psychology). Primary languages: R, Python, SQL.
Cloud: GCP (BigQuery, gcloud). Version control: GitHub via `gh` CLI.

## Author identity
Git author is set via `GIT_AUTHOR_NAME` / `GIT_COMMITTER_NAME` in `~/.claude/settings.json`.
The `attribution.commit` field controls Co-Authored-By trailers only, not the commit author.

## Rules index
| File | Covers |
|---|---|
| `rules/environment.md` | macOS, Bash, direnv, pyenv, worktree safety |
| `rules/tools.md` | gh, jq, gcloud, make, structured CLI output |
| `rules/code-style.md` | Writing style, shell formatting, no emojis |
| `rules/git.md` | Branch naming, commit discipline, staging |
| `rules/r-conventions.md` | Vectorization, lapply/vapply, lintr style |
| `rules/python.md` | pyenv, ruff, uv |
| `rules/session.md` | Token efficiency, context thresholds, output prefs, compaction |
| `rules/core.md` | Simplicity, root causes, workflow, sub-agents |

## Machine-local overrides
`~/.claude/CLAUDE.local.md` (gitignored) — machine-specific environment notes.
