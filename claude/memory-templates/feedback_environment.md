---
name: Environment Safety
description: Never modify dependencies without understanding the full environment setup first
type: feedback
---

Before modifying dependencies (Poetry, renv, pip), identify ALL virtual environments and their relationships.
**Why:** An aiohttp Dependabot fix cascaded into venv corruption because Claude didn't detect a dual-venv setup. User described Claude as "lost in the sauce."
**How to apply:** Run `poetry env info --path` and check `.python-version` before any dependency change. Never assume there is only one venv.
