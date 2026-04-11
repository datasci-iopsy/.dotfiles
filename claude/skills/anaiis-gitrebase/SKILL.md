---
name: anaiis-gitrebase
description: Safely rebase git commits into logical, review-ready groups using branch reconstruction instead of interactive rebase
---

# Git Rebase (Branch Reconstruction)

Reorganize commits on a feature branch into clean, logically grouped commits for PR review. Uses branch reconstruction instead of `git rebase -i` -- avoids the interactive editor entirely. Claude never force-pushes; the final step hands the user the exact command to run.

## Scope

```
$ARGUMENTS: [branch] [base] [--dry-run]
```

- `branch`: feature branch to rebase (default: current branch)
- `base`: base ref to rebase onto (default: `main`)
- `--dry-run`: run phases 1 and 2 only; output proposed grouping without executing

Examples:
- `/anaiis-gitrebase`
- `/anaiis-gitrebase feature/my-branch main`
- `/anaiis-gitrebase --dry-run`

## Tool usage

- `Bash(git:*)` for all git operations (pre-approved, no permission overhead)
- `Grep`/`Glob` only when file purpose is ambiguous from its path alone
- Never use `Read` to examine file contents for grouping decisions; `--stat` and `--name-only` output is sufficient

## Phase 1: Preflight (read-only)

Run all checks in a single chained Bash call:

```bash
git status --porcelain && \
git branch --show-current && \
git merge-base <base> HEAD && \
git log --oneline <fork>..HEAD && \
git log --oneline --merges <fork>..HEAD
```

**Hard stops -- do not proceed if:**
- Working tree is dirty (`git status --porcelain` returns output) -- tell user to stash or commit first
- Merge commits exist in range (last command returns output) -- refuse; merge commits require manual handling
- Detached HEAD -- require a named branch
- No commits in range -- nothing to rebase

## Phase 2: Analysis (read-only)

```bash
git diff --stat <fork>..HEAD && \
git diff --name-only -M <fork>..HEAD && \
git log --oneline --name-only <fork>..HEAD
```

Use `-M` (rename detection) in `--name-only` so renames are grouped correctly rather than appearing as delete + add.

**Grouping heuristics:**
1. Source files in the same module or package group together
2. Test files group with the source files they test
3. Config, tooling, and CI changes (Makefile, pyproject.toml, .github/, linting configs, CodeRabbit config) form their own commit
4. Documentation changes (README, CLAUDE.md) form their own commit unless tightly coupled to a specific feature
5. A file appearing in multiple original commits: use its final state, placed in the logical group matching its purpose
6. Binary files and submodules: flag explicitly and ask the user which group they belong to

**Output format:**

```
Proposed rebase plan (N files, M logical commits):

Commit 1: "feat(scope): description"
  Files:
  - path/to/file1.py
  - path/to/test_file1.py

Commit 2: "chore: description"
  Files:
  - pyproject.toml
  - Makefile
```

If `--dry-run`: output the plan and stop.

---

**GATE 1:** Present the plan and ask the user to confirm, modify, or reject the grouping before any destructive work begins.

---

## Phase 3: Execute (destructive)

**First: create the safety bookmark.**

```bash
FINAL_SHA=$(git rev-parse HEAD)
BRANCH=$(git branch --show-current)
git tag safety/pre-rebase-${BRANCH} ${FINAL_SHA}
```

Tell the user:

> Safety bookmark created: `safety/pre-rebase-<branch>` at `<sha>`.
> To revert at any time: `git checkout <branch> && git reset --hard safety/pre-rebase-<branch>`

**Then: build the temp branch.**

```bash
git checkout -b tmp/rebase-${BRANCH} <fork>
```

**For each commit group (in order):**

```bash
git checkout ${FINAL_SHA} -- <file1> <file2> ...
git commit -m "<message>"
```

**File deletions:** if a file existed at the fork point but was deleted by HEAD, use `git rm <file>` in the appropriate group rather than `git checkout`.

**On pre-commit hook failure:** pause immediately. Report which hook tripped and the full output. Ask the user how to proceed:
1. Fix the issue (e.g., run `poetry lock`, fix lint errors) then retry
2. Skip the hook for this commit with `--no-verify` (requires explicit user approval; overrides the CLAUDE.md "never skip hooks" rule for this case only)
3. Abort and revert to the safety tag

## Phase 4: Verify

```bash
git diff ${FINAL_SHA} tmp/rebase-${BRANCH}
```

- **Empty diff:** "Tree equality verified. New history produces identical file contents."
- **Non-empty diff:** hard stop. Show the diff. Do NOT proceed. Offer to abort: `git checkout ${BRANCH} && git reset --hard safety/pre-rebase-${BRANCH} && git branch -D tmp/rebase-${BRANCH}`.

---

**GATE 2:** User confirms verification passed and approves the branch swap.

---

## Phase 5: Swap

```bash
git checkout ${BRANCH}
git reset --hard tmp/rebase-${BRANCH}
git branch -d tmp/rebase-${BRANCH}
```

Output the final commit log:

```bash
git log <base>..HEAD --oneline
```

## Phase 6: Hand off (Claude does NOT push)

Present the result and the commands for the user to run:

```
Rebase complete. <N> clean commits:

  <sha> <commit 1 message>
  <sha> <commit 2 message>

To publish the rebased history, run:

  git push --force-with-lease origin <branch>

The safety tag `safety/pre-rebase-<branch>` remains. To revert after pushing:

  git reset --hard safety/pre-rebase-<branch>
  git push --force-with-lease origin <branch>

Delete the safety tag when you are satisfied:

  git tag -d safety/pre-rebase-<branch>
```

Claude does not execute the push. This is a human-only action.

## Failure modes and recovery

| Failure | Recovery |
|---|---|
| Dirty working tree | Stash (`git stash`) or commit, then re-run |
| Merge commits in range | Refuse; suggest `git rebase --onto` manually |
| Hook failure during commit | Pause, ask user: fix / skip (with approval) / abort |
| Tree verification fails | `git checkout <branch> && git reset --hard safety/pre-rebase-<branch> && git branch -D tmp/rebase-<branch>` |
| Process interrupted mid-execute | Same revert command as above |
| Wrong files in a group | Revert to safety tag, re-run with corrected grouping |

## Hard limits

- Never execute `git push --force`, `git push --force-with-lease`, or any force-push variant. Human-only action.
- Never proceed past Phase 4 if the tree diff is non-empty.
- Never start without a clean working tree.
- Never operate on a range that includes merge commits.
- Never delete the safety tag -- the user deletes it when satisfied.
- Never use `git rebase -i`.
- Maximum 10 logical commit groups. If more are needed, suggest splitting the PR.

## Integration with other skills

- `anaiis-changelog`: after rebase, run to generate a PR description from the clean commit history.
- `anaiis-preflight`: not needed; this skill does its own git-state preflight in Phase 1.
