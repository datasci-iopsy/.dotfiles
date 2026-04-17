---
name: Shell Config File
description: User's default shell config is .bash_profile — do not read .zshrc or .bashrc
type: feedback
---

Default shell configuration file is `~/.bash_profile`. Do not read or modify `.zshrc` or `.bashrc`.
**Why:** User uses bash, not zsh. Reading other shell configs is unnecessary overhead and potentially confusing.
**How to apply:** Any time shell prompt, aliases, env vars, or PATH changes are needed, go straight to `~/.bash_profile`.
