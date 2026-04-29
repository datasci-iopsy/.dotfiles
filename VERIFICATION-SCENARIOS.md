# Verification Scenarios — Claude Code Behavior

**Date created:** 2026-04-27
**Purpose:** Document expected behavior across 12 key scenarios covering memory, git, tools, domain skills, and session continuity. Use this to catch regressions, verify new memory files are loading, and measure `/anaiis-skillreview` output quality.

---

## How to use this document

Each scenario has:
- **Trigger:** what to say or do
- **Expected:** what Claude should do
- **Pass criteria:** binary — exactly what counts as correct
- **A/B comparison:** where applicable, before vs. after the new memory files
- **Status:** current state

Update the Status column after each test run. Log failures in the Failure Log section at the bottom.

---

## Status key

| Symbol | Meaning |
|--------|---------|
| `VERIFIED` | Tested this session and confirmed working |
| `EXPECTED` | Rule/skill exists and functioning; not re-run |
| `UNTESTED` | New functionality — not yet run |
| `FAIL` | Known to not work; see Failure Log |

---

## Scenarios

---

### S-01: Stop hook acknowledgment

**Category:** Memory / Communication
**Tests:** `feedback_output_style.md` memory + `rules/core.md`

**Trigger:** Stop hook fires with one of:
```
Stop hook feedback:
[bash $HOME/.claude/hooks/stop-hook-git-check.sh]: [git] uncommitted changes
```
```
Stop hook feedback:
[bash $HOME/.claude/hooks/stop-hook-git-check.sh]: [git] untracked files
```

**Expected:** Claude responds with exactly:
```
Ok
```

**Pass criteria:** Single word. No explanation. No "I'll wait for your instruction." No "noted." Exactly `Ok`.

**A/B comparison:**
| | Response |
|--|--|
| A — without memory | "I see there are uncommitted changes. I'll wait for your explicit instruction before staging or committing anything." |
| B — with memory | `Ok` |

**Status:** `VERIFIED` — observed correctly throughout this session (multiple times)

---

### S-02: Terse completion acknowledgment

**Category:** Memory / Communication
**Tests:** `feedback_output_style.md` memory + `rules/session.md`

**Trigger:** After Claude edits a single file (e.g., updates a hook script), ask nothing further.

**Expected:** Claude states the result in one sentence or fewer. Does NOT write a trailing summary block.

**Pass criteria:** No "Here's what I did:" section. No bulleted list of steps taken. No "Summary:" heading.

**A/B comparison:**
| | After editing `pre-compact.sh` |
|--|--|
| A — without memory | "I've updated `pre-compact.sh` to read `transcript_path` directly from the hook input. Previously it was constructing the path from `PROJECT_KEY + SESSION_ID`, which was fragile. Now it uses the provided path and falls back to derived path only when absent." |
| B — with memory | "Updated. `transcript_path` now read directly from hook input with fallback." |

**Status:** `EXPECTED` — session.md rule was working before memory was written; memory reinforces

---

### S-03: No em dashes in responses

**Category:** Memory / Communication
**Tests:** `feedback_output_style.md` memory + `rules/code-style.md`

**Trigger:** Ask Claude to explain a technical decision that involves a contrast or aside (natural em dash opportunity).

**Expected:** No `—` character anywhere in the response. Commas, semicolons, or new sentences used instead.

**Pass criteria:** `grep -c "—" <response>` returns 0.

**A/B comparison:**
| | Describing the memory system |
|--|--|
| A — without discipline | "The MEMORY.md index — which is always loaded — provides a lightweight map..." |
| B — with discipline | "The MEMORY.md index (always loaded) provides a lightweight map..." |

**Status:** `EXPECTED` — code-style.md rule existed before; memory reinforces

---

### S-04: Git staging by name

**Category:** Git discipline
**Tests:** `feedback_git_discipline.md` memory + `rules/git.md`

**Trigger:** After making edits to 3 specific files, ask: "Go ahead and stage those."

**Expected:** Claude runs:
```bash
git add <file1> <file2> <file3>
```
Each file named explicitly.

**Pass criteria:** No `git add -A`, `git add .`, or `git add --all` anywhere in the command. Files enumerated by path.

**A/B comparison:**
| | Staging after multi-file session |
|--|--|
| A — without discipline | `git add -A` or `git add .` |
| B — with discipline | `git add claude/settings.json claude/hooks/pre-compact.sh` |

**Regression reference:** The 2026-04-27 six-commit session staged every group by name across 24+ files — this was correct and should remain so.

**Status:** `VERIFIED` — observed correctly across 6 commits this session

---

### S-05: Branch check before push suggestion

**Category:** Git discipline
**Tests:** `feedback_git_discipline.md` memory + `rules/git.md`

**Trigger:** After staging and committing, say: "Push it."

**Expected:** Claude runs `git branch --show-current` first, then constructs:
```bash
git push origin <actual-branch-name>
```
with the real branch name substituted.

**Pass criteria:** `git branch --show-current` appears in tool calls before the push command is suggested. The push command contains the literal branch name (not a placeholder).

**Status:** `EXPECTED` — git.md rule has been enforced

---

### S-06: Grep tool over Bash grep

**Category:** Tool discipline
**Tests:** `rules/session.md` tool discipline section

**Trigger:** "Find every file in the skills directory that references `rules/citations.md`."

**Expected:** Claude uses the Grep tool with `path: ~/.dotfiles/claude/skills`.

**Pass criteria:** No `Bash(grep ...)` or `Bash(rg ...)` call. Grep tool used directly.

**A/B comparison:**
| | Finding references to a pattern |
|--|--|
| A — wrong | `Bash: grep -r "citations" ~/.dotfiles/claude/skills/` |
| B — correct | `Grep: pattern="citations", path="~/.dotfiles/claude/skills"` |

**Status:** `EXPECTED` — session.md rule enforces this; Bash grep is blocked by prefer-jq.sh hook for jq but not for grep specifically — this is worth verifying

---

### S-07: Agent spawn threshold (< 4 tool calls inline)

**Category:** Tool discipline / Agent behavior
**Tests:** `rules/core.md` agent spawn threshold

**Trigger:** "Check if `anaiis-litreview` and `anaiis-peerreview` both have a `trigger:` field in their frontmatter."

**Expected:** Claude uses Grep or Read directly on the two files — does NOT spawn an Explore or general-purpose agent.

**Pass criteria:** No `Agent(...)` tool call. Task resolved with 1-2 Grep or Read calls.

**A/B comparison:**
| | Checking 2 specific files |
|--|--|
| A — over-engineered | Spawns Explore agent: "I'll have a subagent check both files..." |
| B — correct | `Grep: pattern="trigger:", glob="*/anaiis-litreview/SKILL.md"` + same for peerreview |

**Regression reference:** core.md rule was added this session (commit `440d472`) specifically to stop over-spawning — this is a direct regression test.

**Status:** `EXPECTED` — core.md rule just committed; verify at next opportunity

---

### S-08: DuckDB analytical query — COUNT before content

**Category:** Domain skills
**Tests:** `rules/duckdb.md` analytical purpose pattern

**Trigger:** "How many papers in my catalog mention engagement and burnout together?"

**Expected:** Claude classifies this as Analytical purpose and writes:
```sql
SELECT COUNT(*) FROM catalog
WHERE lower(abstract) LIKE '%engagement%'
  AND lower(abstract) LIKE '%burnout%'
```
Does NOT run `SELECT title, abstract, doi ... LIMIT 20` to answer a count question.

**Pass criteria:** Query uses `COUNT(*)` or equivalent aggregate. No row-level SELECT for an analytical question. No fetching content to count it.

**A/B comparison:**
| | Answering "how many papers on X" |
|--|--|
| A — wrong purpose | `SELECT title, abstract FROM catalog WHERE topic LIKE '%burnout%' LIMIT 20` |
| B — correct purpose | `SELECT COUNT(*) FROM catalog WHERE lower(abstract) LIKE '%burnout%'` |

**Status:** `EXPECTED` — duckdb.md rule added (commit `440d472`); first live test pending

---

### S-09: Literature review auto-trigger on possessive phrasing

**Category:** Domain skills
**Tests:** `claude/skills/anaiis-litreview/SKILL.md` description matching + citation rules

**Trigger:** "What does my library have on the job demands-resources model?"

**Expected:** `anaiis-litreview` activates automatically. Does NOT just run an inline DuckDB query.

**Pass criteria:** Skill activation message appears (or observable skill behavior). Catalog queried with LIMIT 20 Discovery pattern. If fewer than 5 results, web expansion offered (Step 6 of litreview).

**Possessive phrasing note:** "my library", "my catalog", "my references", "what do I have on X" — all should trigger litreview, not ad hoc DuckDB.

**Status:** `EXPECTED` — litreview was restructured this session (commit `7fef666`) with this exact trigger

---

### S-10: Citation training-knowledge flag

**Category:** Domain skills / Citations
**Tests:** `rules/citations.md`

**Trigger:** During a literature discussion, Claude mentions a specific paper that has NOT been confirmed in the local catalog. Observe response.

**Example setup:** Ask "What does Bakker and Demerouti's JD-R model say about resource caravan passageways?" — this may reference papers not in the catalog.

**Expected:** Claude answers substantively AND flags:
> "Not in your local catalog — drawing on training knowledge."

Optionally offers: "I can search the web for this and provide the DOI."

**Pass criteria:** Substantive answer present (no refusal). Flag present if paper is not catalog-confirmed. DOI not fabricated.

**A/B comparison:**
| | Citing a paper not in catalog |
|--|--|
| A — wrong | "Bakker & Demerouti (2007) argue that..." (no flag, treating training knowledge as confirmed) |
| B — correct | "Bakker & Demerouti (2007) argue that... [Not in your local catalog — drawing on training knowledge. I can search for the DOI if you'd like to add it.]" |

**Status:** `EXPECTED` — citations.md rule added (commit `5d25d63`)

---

### S-11: Pre/post compact cycle — handoff injection

**Category:** Session continuity
**Tests:** `pre-compact.sh`, `post-compact.sh` hooks, `settings.json` PreCompact/PostCompact matchers

**Trigger:** Make several file edits, then run `/compact`.

**Expected sequence:**
1. `pre-compact.sh` runs: `handoff_<date>_<session>.md` written to memory directory
2. MEMORY.md updated with new handoff entry
3. Compaction occurs
4. `post-compact.sh` runs: injects handoff content as systemMessage
5. New session starts with "## Restored from pre-compact handoff" visible in output

**Pass criteria:** All 5 steps occur. The restored context includes the correct list of files edited and git state from just before compaction.

**Status:** `VERIFIED` — tested and confirmed this session. Pre-compact wrote `handoff_2026-04-27_20fc8532.md`. Post-compact injected it with full file list and git diff stats. Both hooks reported "completed successfully" in the compact output.

---

### S-12: `/anaiis-skillreview` end-to-end

**Category:** Session continuity / Skill improvement loop
**Tests:** `claude/skills/anaiis-skillreview/SKILL.md`

**Trigger:** After at least 2-3 sessions with handoff files present, run: `/anaiis-skillreview`

**Expected sequence:**
1. Skill activates (explicit trigger match)
2. Glob finds handoff files in memory directory
3. Reads most recent 5 (or all if fewer)
4. Reads `feedback_output_style.md`, `feedback_git_discipline.md` from memory
5. Runs `git log --oneline -20` on dotfiles
6. Identifies patterns across sessions
7. Writes `~/.dotfiles/SKILL-REVIEW-<date>.md`
8. Reports: N handoffs reviewed, N patterns found, N already covered, path to file

**Pass criteria:**
- No agent spawned (skill runs inline)
- Proposal file written to dotfiles root
- File contains at minimum: patterns identified section, no-action items, recommended next step
- Terminal output is the terse summary only — not the full proposal

**Current limitation:** Only 1 handoff file exists as of 2026-04-27. First run will produce a minimal report per the skill's guardrail ("fewer than 2 handoff files — limited data"). **Re-test after 2-3 more sessions with /compact.**

**Status:** `UNTESTED` — skill newly written; first run pending

---

## Summary table

| ID | Scenario | Category | Status | Requires |
|----|----------|----------|--------|---------|
| S-01 | Stop hook → "Ok" | Memory | `VERIFIED` | — |
| S-02 | Terse completion ack | Memory | `EXPECTED` | — |
| S-03 | No em dashes | Memory | `EXPECTED` | — |
| S-04 | Stage by name | Git | `VERIFIED` | — |
| S-05 | Branch check before push | Git | `EXPECTED` | — |
| S-06 | Grep not Bash(grep) | Tools | `EXPECTED` | Manual test |
| S-07 | Agent threshold < 4 calls | Tools | `EXPECTED` | Manual test |
| S-08 | DuckDB COUNT before content | Domain | `EXPECTED` | Live DuckDB session |
| S-09 | litreview possessive trigger | Domain | `EXPECTED` | Live catalog session |
| S-10 | Citation training-knowledge flag | Domain | `EXPECTED` | Live litreview session |
| S-11 | Pre/post compact cycle | Continuity | `VERIFIED` | — |
| S-12 | /anaiis-skillreview end-to-end | Continuity | `UNTESTED` | 2+ more handoffs |

**Verified:** 3 | **Expected pass:** 8 | **Untested:** 1 | **Failing:** 0

---

## Failure log

No failures recorded as of 2026-04-27.

_When a failure is found, record here:_
```
### F-XX: <scenario ID> — <short description>
**Date:** <date>
**Observed:** <what actually happened>
**Expected:** <what should have happened>
**Root cause:** <rule missing / memory not loaded / skill not triggered / etc.>
**Fix applied:** <what was changed>
**Re-test result:** <pass / still failing>
```

---

## Maintenance notes

- Run S-12 after every 2-3 sessions that include `/compact`
- After running `/anaiis-skillreview`, review the proposal file and update this document if any scenarios need revision
- If a scenario moves from EXPECTED to FAIL, diagnose before fixing — check whether the rule file was changed, the memory file is loading, or the skill description changed
- principles.md will be added as a new category of scenarios once it exists (post skill-review cycle)
