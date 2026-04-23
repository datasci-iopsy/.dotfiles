# Environment

- macOS, Bash shell. Config lives in `~/.dotfiles/bash/bashrc.d/` modules, loaded via `~/.bashrc` (symlinked from dotfiles). `~/.bash_profile` is a thin loader that delegates to `~/.bashrc`. Never modify `.zshrc`. Machine-local vars (GCP project, API keys) go in `~/.bashrc.local`, which is not tracked in git.
- `direnv` manages per-project env vars via `.envrc` — loads automatically on cd.
- `pyenv` manages Python versions. Check `.python-version` before assuming Python version.
- Before modifying Python venvs or dependencies, identify all venvs in the project and confirm which is active. Never modify venv contents without mapping the environment first.
- When working in projects with worktrees, confirm which worktree/directory you're in before running commands.
