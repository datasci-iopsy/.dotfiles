# Preflight Environment Check

Run a non-destructive environment health check before starting work.

## Checks to perform

1. **Working directory**: Confirm `pwd` matches expected project root. If in a git worktree, note it.
2. **Python environment** (if `pyproject.toml` or `requirements.txt` exists):
   - `.python-version` vs `python --version` — do they match?
   - `poetry env info --path` (if Poetry) or `which python` — is the venv active and valid?
   - `poetry check --lock` (if Poetry) — is the lock file consistent?
3. **R environment** (if `renv.lock` exists):
   - `Rscript -e "renv::status()"` — any out-of-sync packages?
4. **Git state**: `git status --short` — any uncommitted changes or untracked files?
5. **Auth tokens** (if applicable):
   - `gh auth status` — GitHub CLI authenticated?
   - `gcloud auth list` — GCP auth valid? (only if project uses GCP)

## Output format

Report as a checklist. Flag issues with recommended fixes. Example:

- [x] Working directory: `/path/to/project` (main branch)
- [x] Python 3.12.11 via pyenv, Poetry venv active at `/path/to/venv`
- [ ] **poetry.lock inconsistent** — run `poetry lock` to resolve
- [x] R renv: all packages in sync
- [x] Git: clean working tree
- [x] GitHub CLI: authenticated as user
- [n/a] GCP: not applicable to this project

Do NOT make any changes. Report only.
