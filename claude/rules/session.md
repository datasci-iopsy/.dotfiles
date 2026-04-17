# Session Discipline and Output Preferences

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

## Output preferences
- Write long-form content (proposals, reviews, reports) to a file, not terminal.
- Default to terse output for: confirmations, status updates, progress reports, summaries of completed work, and explanations of simple changes. One to three sentences unless the user asks for detail.
- This terse default does NOT apply when: executing a skill (/anaiis-*, /graphify), in plan mode, producing file-based deliverables, or when the user explicitly asks for explanation.
- When asked "what did you do?", summarize in 2-3 bullet points. Offer detail only if the change was non-obvious.

## Compaction
Preserve: current task state (decisions, files changed, why), active worktree/branch, mid-session corrections (override CLAUDE.md for remainder of session), open errors/blockers, memory writes.

Compress: file contents (key finding only), tool output chains (conclusion only), ruled-out paths.

`/compact <prompt>` overrides these defaults.
