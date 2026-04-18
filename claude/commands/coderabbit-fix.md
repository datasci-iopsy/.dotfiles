Process deferred CodeRabbit findings, fix real defects, and commit by logical group.

## Arguments

$ARGUMENTS — optional flags:
- `--review`: spawn the `code-reviewer` agent on staged changes before committing (quality gate, costs extra tokens)

## Pipeline

Run all steps inline. Do not spawn agents unless `--review` is passed.

### 1. Read deferred findings

Read `~/.claude/coderabbit-deferred.md`. If the file is empty or contains only comments (lines starting with `#`), report "No deferred findings. Done." and stop.

### 2. Re-assess each finding

For each finding in the deferred file:
- Use Grep/Glob/Read to verify whether the issue still exists in the current code
- If already resolved (e.g., fixed in a prior commit): mark as **resolved**, skip
- If still present: mark as **actionable**

### 3. Fix actionable findings

For each actionable finding:
- Apply the minimal fix using Edit (never Write unless creating a new file is the fix)
- Do not refactor surrounding code, add comments, or touch unrelated lines
- Group fixes by logical concern (same file, same subsystem, or same finding type)

### 4. Commit by group

For each logical fix group:
- Stage files by name: `git add <file1> <file2>` — never `git add .` or `git add -A`
- Commit with an imperative message describing the fix: `git commit -m "fix: <what>"`
- One commit per logical group; do not batch unrelated fixes into a single commit

If `--review` was passed: before the first commit, spawn the `code-reviewer` agent with the staged diff as context. Address any blocking findings before committing. Advisory findings may be noted but do not block the commit.

### 5. Report

Print a concise summary:
- Fixed: N findings (list commit SHAs and one-line descriptions)
- Already resolved: N findings (list)
- Still deferred: N findings (list — these remain in `~/.claude/coderabbit-deferred.md`)

Do NOT push. The user reviews commits and pushes when satisfied.

## Escalation note

If findings span 5+ unrelated files and you judge that parallel exploration would materially reduce errors, say so explicitly and ask the user whether to proceed with parallel agents. The `cost-guard.sh` hook will gate the cost tier automatically.
