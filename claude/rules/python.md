# Python Conventions

- Use `pyenv` to manage versions. Check `.python-version` before assuming the active version.
- Formatting and linting are enforced by `ruff`. Run `ruff check` then `ruff format` after edits. The pre-commit hook catches remaining drift.
- Per-project overrides live in `pyproject.toml` or `ruff.toml`; global defaults apply otherwise.
- Use `uv` for dependency management and virtual environments. Map all venvs before modifying.
