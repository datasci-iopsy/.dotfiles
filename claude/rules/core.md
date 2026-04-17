# Core Principles and Workflow

## Core principles
- **Simplicity first**: Make every change as simple as possible. Minimal code impact.
- **Find root causes**: No temporary fixes. Senior developer standards.
- **Minimal impact**: Only touch what's necessary. Avoid introducing bugs. Remove imports, variables, or functions YOUR changes made unused — but don't remove pre-existing dead code unless asked.

## Workflow
- Before starting: if a request has multiple valid interpretations, surface them and ask — don't pick silently. If something is unclear, name what's confusing before proceeding.
- Before starting non-trivial tasks: state the verifiable success criteria (what "done" looks like and how it will be confirmed), not just the steps.
- While in plan mode, if something goes sideways mid-task, stop and re-plan — don't keep pushing.
- Use subagents liberally to keep the main context window clean. Offload research, exploration, and parallel analysis to subagents. One task per subagent for focused execution.
- Never mark a task complete without proving it works. Run tests, check logs, demonstrate correctness.
- For non-trivial changes, consider if there's a simpler approach. Skip for obvious fixes.
- For bugs, just fix them. Point at evidence, resolve.
