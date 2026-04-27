# Session Discipline and Output Preferences

## Token efficiency

### Before reading any file
Check whether that file path already appears in a prior Read result in this session. If it does, use that content — do not call Read again. A prior Read result is sufficient even if you did not retain every line; reference what you have and state what is missing if needed.

### Read scope
- **Config and settings files:** read only the section relevant to the current task. Use offset/limit to target it. Read the full file only when understanding the file's full structure is the explicit task.
- **Files over 200 lines:** always use offset/limit. Estimate the relevant section before reading. If uncertain, use Grep first to locate the line range.
- **New files (never read this session):** use Glob or Grep to confirm existence and locate the relevant section before calling Read.

### Tool discipline
- Use Grep (not Bash grep/rg) and Glob (not Bash find/ls) for all search. Never use Bash(grep), Bash(rg), Bash(find).
- Never use Bash(cat), Bash(head), or Bash(tail) — use Read with offset/limit.
- Chain independent read-only shell commands with `&&` in a single Bash call.
- Prefer Read over Bash(cat) unless piping to another command (e.g., `cat file | jq`).

## Session discipline
- One deliverable per session. If scope shifts (e.g., planning to implementation), ask whether to continue or start fresh.
- Compaction is managed manually by the user. Do not suggest `/compact` or starting a new session based on context thresholds.
- When context is high, prefer writing output to a file over long in-context responses.
- Do not re-explore what was already explored in this session. Summarize prior findings from context.

## Output preferences
- Write long-form content (proposals, reviews, reports) to a file, not terminal.
- Default to terse output for: confirmations, status updates, progress reports, summaries of completed work, and explanations of simple changes. One to three sentences unless the user asks for detail.
- This terse default does NOT apply when: executing a skill (/anaiis-*, /graphify), in plan mode, producing file-based deliverables, or when the user explicitly asks for explanation.
- When asked "what did you do?", summarize in 2-3 bullet points. Offer detail only if the change was non-obvious.

## Compaction instructions

These instructions are read by the compactor. When summarizing this conversation, preserve ALL of the following:

**Must preserve (verbatim or as a structured list):**
- The exact task being worked on and its acceptance criteria — specifically what "done" looks like
- Active git branch and worktree path
- Every file path read or modified this session, labeled by operation (Read / Write / Edit)
- Every decision made and the single-sentence reason behind it
- Every open error, blocker, or unresolved question
- Every mid-session behavioral override (e.g., "user said to skip X for this session")
- Every memory file written this session (path only)
- The filename of any handoff file written to memory/ before this compaction

**Must not preserve (discard or one-line note only):**
- Full file contents — the file still exists on disk; the path is sufficient
- Tool call chains where only the conclusion matters
- Ruled-out approaches — one-line note only
- Acknowledgments, preamble, and intermediate reasoning steps

`/compact <prompt>` overrides these defaults.
