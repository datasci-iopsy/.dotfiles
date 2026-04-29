# LLM Council — Dotfiles Audit
**Date:** 2026-04-29
**Repo:** `/Users/dkgreen-mmai/.dotfiles`
**Branch:** main
**Mode:** Karpathy-style 5-advisor council with anonymized peer review

## Original question

> Provide a technical security and dotfile structure and performance audit on this .dotfiles repo. The repo spans two profiles (personal + work) sharing one config across machines (macOS now, Linux later). The codebase should be lean and precise. Skills must do something above and beyond Claude built-ins (e.g. `/simplify`). Token savings and performance are paramount. Use a two-level rubric — top-level facets (e.g. Security) and sub-facets (CIA triad style or analogous).

## Framed question

Audit `~/.dotfiles` as a Claude-Code-centric configuration repo with a thin shell-config tail. Surface a two-level rubric and judge the repo against it. Constraints: single-user, two physical machines, macOS now, Linux later, token-efficient by stated value. Evidence base: symlink install via `install.sh`; 11 hooks (3 fire on every UserPromptSubmit, 2 on every Bash); 10 auto-loading rules; 12 `anaiis-*` skills + `graphify`; 3 sub-agents on sonnet-4-6; `skipDangerousModePermissionPrompt: true` and `claude-yolo` alias; `.env` (empty `GITHUB_PAT=`) referenced by `.mcp.json` with no visible loader; 348-line `test-compact-hooks.sh` in production hooks dir; ~62KB of stale audit MDs in repo root; `bashrc.d/` numbering jumps `07→09`; `.vscode/` committed.

## Anonymization map

| Letter | Advisor |
|---|---|
| A | The Outsider |
| B | The Executor |
| C | The Contrarian |
| D | The First Principles Thinker |
| E | The Expansionist |

---

## Advisor responses

### A — The Outsider

Walking in cold, the first thing that hits me is signal-to-noise in the root. Five top-level Markdown files (README, COUNCIL-REVIEW, HANDOFF, MEMORY-SYSTEM-AUDIT, VERIFICATION-SCENARIOS) totaling ~80KB, and I cannot tell which are docs, which are stale artifacts, and which are inputs to tooling. HANDOFF in a repo root reads like leftover scratch. The `.env` / `.env.example` pair is identical and empty, which makes me suspect neither works; `.mcp.json` references `${GITHUB_PAT}` with no visible loader, so I'd assume it's broken until proven otherwise. `claude-yolo` and `skipDangerousModePermissionPrompt: true` together are a yellow flag — the naming literally says "skip the guardrail." A 348-line `test-compact-hooks.sh` sitting in `hooks/` next to production hooks looks executable-by-default; I'd want tests in a `tests/` sibling. The `bashrc.d` 07→09 gap reads as a bug or a deletion someone forgot to renumber. "anaiis" appears 12 times with zero glossary. `.vscode/` in a dotfiles repo suggests editor settings leaked in.

Rubric sub-facets the audit needs beyond CIA: **Discoverability**, **Naming legibility**, **Artifact hygiene**, **Onboarding-from-zero**, **Secret-loading provenance**, **Test/production separation**, **Profile model clarity**, **Dead-code/numbering integrity**.

The single highest-leverage fix: a 30-line README top section answering "what is this, who runs install.sh, what gets symlinked where, what are the two profiles, what is anaiis, and which root `.md` files are docs vs. archives." Move the audit artifacts to `docs/archive/`. Everything else follows.

### B — The Executor

**Security.** Check `.env` (rm it; `.env.example` is sufficient), `settings.json` allow list (verify no `bq rm`/`gcloud * delete` slipped past inline blocks), `.mcp.json` `${GITHUB_PAT}` source (add to `~/.bashrc.local` or direnv, document in CLAUDE.local.md). Pass = no secrets in tree, no destructive verbs in allow list, MCP env var resolves in fresh shell.

**Structure.** Repo-root audit dross are one-shots, not living docs; move to `docs/archive/` or delete. `test-compact-hooks.sh` does not belong in production hooks dir; move to `tests/`. Pass = `ls ~/.dotfiles` shows only living config.

**Performance.** UserPromptSubmit fires 3 hooks per prompt; collapse `maintenance-check` + `ensure-repo-hooks` + `coderabbit-triage` into one dispatcher with early-exit guards. PreToolUse-Bash inline destructive-block is fine; `prefer-jq.sh` runs on every Bash, confirm it exits <50ms. Pass = prompt-to-first-token unchanged after consolidation.

**Skills hygiene.** Cull overlaps with built-ins. Keep anaiis-* that beat built-ins (litreview, peerreview, graphify); drop the rest if redundant.

**Hard-cull (run today):**
```
git rm .env COUNCIL-REVIEW.md HANDOFF.md MEMORY-SYSTEM-AUDIT.md VERIFICATION-SCENARIOS.md
git mv claude/hooks/test-compact-hooks.sh tests/
```

**Fastest path.** 1) Branch `chore/dot-audit-cull`. 2) Run hard-cull; commit. 3) Fix `.env`/MCP; verify `claude` starts clean. 4) Consolidate UserPromptSubmit hooks; verify with `time`. 5) Run install.sh on second machine. 6) Open PR, self-review with `/security-review`.

### C — The Contrarian

**Security > Blast-radius containment** (not generic CIA — Confidentiality is fine, Integrity is the real axis here): can a single misfire from one profile damage the other profile's GCP project, git identity, or secrets? **Operational performance > Per-prompt hook tax**: wall-clock and token cost added to every user message and every Bash call. **Skill correctness > Built-in collision surface**: which custom skills duplicate or conflict with Anthropic-shipped slash commands. Availability is noise here — single-user tooling, not a service.

Concrete failure modes: (1) `settings.json` `skipDangerousModePermissionPrompt: true` AND `bashrc.d/05-tools.bash` ships `claude-yolo='claude --dangerously-skip-permissions'`. Two independent bypass paths around the very PreToolUse hooks that block `*.env*`, `*credentials*`, `bq rm`, `gcloud delete`. The blocklist is theater if either path is hot. (2) Three UserPromptSubmit hooks fire on every message; three PreToolUse hooks fire on every Bash. Token tax never itemized. (3) `claude/hooks/test-compact-hooks.sh` (348 lines) is a test file in production hooks directory. (4) `bashrc.local.template` carries GCP project + secrets, copied on install — silent drift between machines. (5) anaiis-copyedit/anaiis-docaudit overlap `/simplify` and `/review`; anaiis-preflight overlaps `/security-review`. (6) 62KB of stale review artifacts in repo root get globbed by every "read the repo" agent.

**Single biggest risk to shut down today:** the `skipDangerousModePermissionPrompt: true` + `claude-yolo` alias combination. Your hook-based blocklist is the only thing standing between a hallucinated command and your work GCP project, and you have two routes around it. Remove the alias, flip the setting to false, force every dangerous op through the prompt.

### D — The First Principles Thinker

This repo isn't a "dotfiles repo." It's a **personal Claude Code policy stack** with a thin shell-config tail. Eighty percent of the surface (rules, skills, hooks, agents, commands) shapes one LLM's behavior; the bash modules are incidental. Once named correctly, the structure question changes: portability to Linux matters far less than whether the policy stack is internally coherent and the LLM can actually execute it under load.

The "two profiles on one machine" framing is also wrong. There is one profile and a machine-local override file. Either build real profile routing (env-based settings selection) or drop the claim. Pretending it exists creates phantom requirements.

CIA triad is the wrong frame. Confidentiality/Integrity/Availability assumes adversaries and shared systems. This is single-user dev tooling. The real failure modes are **instruction collisions, token waste, and skill redundancy with built-ins**, not breaches.

Proposed rubric: **Policy coherence** (rule conflicts, rule-vs-skill precedence, hook-vs-rule overlap, dead/contradictory directives). **Execution cost** (per-prompt hook fan-out, auto-loaded rule tonnage, redundant Reads, agent spawn discipline). **Skill justification** (does it beat the built-in equivalent on a named axis?). **Boundary hygiene** (machine-local vs repo-tracked, living docs vs stale artifacts, test code in production paths). **Portability surface** (only the bash layer; scope it there).

The wrong question: "is this secure and performant?" The right question: **"is this policy stack causing the friction my insights already flagged (Claude guessing, jumping to edits, missing conventions), or fixing it?"** Audit against observed behavior, not abstract facets.

### E — The Expansionist

**Underused leverage.** The memory system plus pre/post-compact hooks is the most differentiated piece of this repo and it is being treated like plumbing. Per-project `MEMORY.md` indexes with topical files and auto-generated handoffs are a session-continuity layer that compounds: every audit, every CodeRabbit triage, every rebase pattern becomes reusable signal. The 31-session insight stream and the 9-of-31 CodeRabbit cadence are training data for a coderabbit-triage skill that encodes the user's actual patterns. Same for surgical rebase: 9→5 and 10→4 are a documented style.

**Sub-facets to add.** Beyond security/structure/performance: skill differentiation (which skills encode I-O Psych domain knowledge no built-in will ever replicate — litreview, peerreview, duckdb, preflight — and which are commodity), session-continuity quality (does memory survive compaction with the right artifacts), cost predictability per session class (triage vs rebase vs litreview should have known token envelopes), onboarding velocity (time-to-green on a fresh machine, measurable), cross-OS portability as a feature (Linux readiness as a forcing function for cleaner module boundaries), cross-domain leverage (does the dbt/BigQuery muscle feed the R/lintr muscle through shared rules).

**The 2x upgrade.** Promote the memory system from infrastructure to product. Add a `/memory-mine` skill that reads across `~/.claude/projects/*/memory/` and surfaces recurring patterns as candidate skills or rules. The repo already generates the substrate; nothing harvests it. One move, compounds against every future session, turns the moat into a flywheel.

---

## Peer reviews (anonymized)

### Reviewer 1
**Strongest:** C. Names the single highest-severity finding precisely (two independent bypass paths render the blocklist theater) and ties each rubric facet to a concrete failure mode in this repo, not a generic checklist. B is runner-up for executable sequencing.
**Biggest blind spot:** E. Praises the moat without addressing the audit. No security finding, no comment on the yolo bypass, no structural cull. Answers a different question.
**All five missed:** Linux portability — none audited macOS-isms (BSD `sed`, `pbcopy`, `osascript`, Homebrew paths). Symlink install collision behavior (does `install.sh` clobber existing `~/.claude/settings.json`?). The auto-loading rules' actual token cost was named (D) but never measured.

### Reviewer 2
**Strongest:** C. Identifies that `skipDangerousModePermissionPrompt: true` *combined with* `claude-yolo` is a compounded bypass. Orders by blast radius, which is what an audit is for. B treats the `.env` leak and yolo alias as equal-weight items, which is wrong.
**Biggest blind spot:** E. Reframes the audit as a moat-expansion exercise and proposes a *new skill* while the repo has an active credential-loading ambiguity and a double permission bypass. Adding surface area before closing bypasses is the wrong direction.
**All five missed:** None addressed the supply-chain question — `.mcp.json` references `.env` with no visible loader; until the loader is identified, every other security finding is downstream of an unknown trust boundary. Verify the loader before any `git rm` or scoring.

### Reviewer 3
**Strongest:** C. Correctly identifies the dual-bypass interaction as load-bearing. B is more actionable but executes without prioritizing. C also catches `bashrc.local` copy drift across machines, which A, B, D miss.
**Biggest blind spot:** D. Reframing is sharp but offers no concrete fixes. Misses that the dual permission bypass is a real security issue regardless of framing. Reframing without remediation leaves the bypass live.
**All five missed:** No one audited the **rules themselves for internal contradiction or staleness** — `core.md` says "offload to subagents" while memory `feedback_agent_token_cost.md` says agents are expensive and sequential is fine. No one verified `settings.json` env-block author identity actually resolves on the second machine. Pre/post-compact hooks have never been verified end-to-end on a real compaction.

### Reviewer 4
**Strongest:** C. Names a concrete, exploitable failure mode (double-bypass hits work GCP via hallucinated `bq rm`/`gcloud delete`). Others rank facets; C ranks consequences.
**Biggest blind spot:** B. A pass/fail checklist ending in `/security-review` treats this like a CI pipeline, but the repo IS the policy that governs the reviewer. Running `/security-review` under `claude-yolo` validates nothing — auditor is auditee.
**All five missed:** `.env` with empty `GITHUB_PAT=` consumed by `.mcp.json` is *supply-chain*, not hygiene. MCP servers load on every session across both machines; an empty token means either silent-fail auth or fallback to ambient `gh` credentials. None traced which. None audited symlink install for TOCTOU. None audited whether 11 hooks have bounded execution time.

### Reviewer 5
**Strongest:** C. Identifies the only finding with same-day operational consequence. Correctly elevates blast-radius over tidiness; correctly rejects Availability as noise for single-user tooling.
**Biggest blind spot:** E. Praises the memory + compact-hook system as a "moat" without auditing whether the 11 hooks actually deliver value proportional to their per-prompt latency cost. Proposes `/memory-mine` (more surface) when the evidence says contract.
**All five missed:** Empty `GITHUB_PAT=` in tracked `.env` referenced by `.mcp.json` with no loader is treated as hygiene; nobody asks whether MCP is silently failing or pulling a token from elsewhere. No advisor proposes timing the 3 UserPromptSubmit hooks before recommending changes. The `07→09` gap may be a meaningful deletion, not a bug.

---

## Chairman's verdict

### Where the council agrees

1. **The dual permission bypass is the highest-priority finding.** `skipDangerousModePermissionPrompt: true` (in `settings.json`) plus `claude-yolo='claude --dangerously-skip-permissions'` (in `bashrc.d/05-tools.bash`) provide two independent paths that defeat the inline PreToolUse blocklist guarding `*.env*`, `*credentials*`, `bq rm`, `gcloud delete`. Five out of five peer reviewers ranked C strongest specifically for naming this. The work-machine GCP project is exposed to any hallucinated destructive command.
2. **Repo-root cruft must move.** Four large MDs (`COUNCIL-REVIEW.md`, `HANDOFF.md`, `MEMORY-SYSTEM-AUDIT.md`, `VERIFICATION-SCENARIOS.md`, ~62 KB total) are stale audit artifacts, not living docs. They get globbed by every "read the repo" agent. A, B, C all flag.
3. **`test-compact-hooks.sh` (348 lines) does not belong in `claude/hooks/`.** It will be symlinked into the production hooks directory by `install.sh`. Move to `tests/`. A, B, C flag.
4. **Per-prompt hook tax is real and unmeasured.** Three `UserPromptSubmit` hooks fire on every message; two `PreToolUse` hooks fire on every Bash. None of the advisors timed them; consolidation should be evidence-driven, not speculative. C names; B prescribes; reviewers 1/5 escalate.
5. **Each `anaiis-*` skill must justify itself against its built-in counterpart.** `anaiis-docaudit` vs `/review`, `anaiis-preflight` vs `/security-review`, `anaiis-changelog` vs branch-diff prompts. Domain skills (`litreview`, `peerreview`, `duckdb`, `copyedit`, `graphify`) clearly differentiate; the others need a one-line "why not the built-in" annotation or deletion.
6. **"Two profiles" is imprecise.** There is one profile plus a machine-local override file. The framing creates phantom requirements. A, D explicit; B, C consistent.

### Where the council clashes

1. **Frame: CIA triad vs policy-stack rubric.** C uses Confidentiality + Integrity (drops Availability) as a usable subset; D rejects CIA entirely as the wrong frame for single-user dev tooling and proposes Policy coherence / Execution cost / Skill justification / Boundary hygiene / Portability surface. Reasonable advisors disagree because both frames cover the territory; the question is which is more legible to the user. **Resolution:** D's reframing is correct in spirit (this is a Claude policy stack, not classical dotfiles), but the user explicitly asked for a CIA-style two-level rubric. The chairman synthesizes: keep top-level Security and Performance, but adopt D's policy-coherence and skill-justification axes as additional top-levels rather than smuggling them into "Structure."
2. **Direction: cull vs expand.** B/C/D all push contraction (delete, move, consolidate). E proposes expansion (`/memory-mine` skill). All five peer reviewers — without exception — call E's expansion premature given the unaddressed bypass and the unverified MCP loader. **Resolution:** E's idea is genuinely valuable and should be a v2 candidate, but it goes after Phase 1 (close bypass), Phase 2 (cull), and Phase 3 (instrument).

### Blind spots the council caught (peer review)

- **MCP supply chain is unaudited.** `.mcp.json` references `${GITHUB_PAT}` with no traced loader. The github MCP server starts on every Claude session across both machines. Nobody confirmed whether (a) the empty value silently fails, (b) MCP reads `.env` directly, (c) there is fallback to ambient `gh` credentials, or (d) something else injects it. **Until this is traced, every other security finding is downstream of an unknown trust boundary.** (Reviewers 2, 4, 5 unanimous.)
- **Rules vs memory contradiction.** `claude/rules/core.md` instructs offloading to subagents while memory `feedback_agent_token_cost.md` records "agents are expensive; sequential is fine." Neither overrides the other; the policy stack contains an unresolved instruction collision the LLM must arbitrate every session. (Reviewer 3.)
- **macOS-isms not surfaced for Linux readiness.** Despite the stated future-Linux constraint, no advisor checked `os-darwin.bash`, hook scripts, or skill scripts for BSD-only `sed` flags, `pbcopy`, `osascript`, or Homebrew-specific paths. (Reviewer 1.)
- **`bashrc.d/08-*.bash` deletion intent.** The 07→09 gap may be a meaningful removal worth a comment, not a numbering bug. (Reviewer 5.)
- **`install.sh` collision behavior.** The script's behavior when `~/.claude/settings.json` already exists as a real file (not a symlink) is gentle (skip), but no advisor verified what happens to a stale symlink pointing at a renamed source. (Reviewer 1.)
- **Auditor=auditee circularity.** Running `/security-review` to validate this repo is meaningless if the reviewer Claude is itself running under the very `skipDangerousModePermissionPrompt: true` it is supposed to evaluate. The audit must be performed in a session that has flipped that setting first. (Reviewer 4.)
- **Bashrc.local copy drift.** Templates copied at install are silently divergent across machines. No drift-detection mechanism. (C named; A/B/D missed.)

### The recommendation

**Cull, close, then compound.** Three phases, in order. Do not skip Phase 1.

#### Phase 1 — Close the bypass (today, blocking)

Verifiable success: a hallucinated `gcloud projects delete` from Claude is blocked without user intervention.

| # | Action | Pass signal |
|---|---|---|
| 1 | Remove the `claude-yolo` alias from `bash/bashrc.d/05-tools.bash` | `alias claude-yolo` returns "not found" in fresh shell |
| 2 | Set `skipDangerousModePermissionPrompt: false` in `claude/settings.json` | Setting reads `false` |
| 3 | Trace the `${GITHUB_PAT}` resolver. Either (a) load via `direnv` from `.bashrc.local`, (b) move into `~/.claude/settings.local.json` as `env`, or (c) document that MCP fails silently | `claude` startup logs show github MCP server connecting OR documented as intentionally unused |

#### Phase 2 — Cull the noise (this week)

| # | Action |
|---|---|
| 4 | `git rm` or `git mv → docs/archive/` the four root MDs |
| 5 | `git mv claude/hooks/test-compact-hooks.sh tests/` (create `tests/`) |
| 6 | `git rm .env` (it duplicates `.env.example`, both empty, neither sourced) |
| 7 | Remove `.vscode/` from tracking; add to `.gitignore` |
| 8 | Investigate intent of missing `bashrc.d/08-*.bash`; renumber or comment why the gap exists |
| 9 | For each `anaiis-*` skill, add a one-line "why not built-in X" frontmatter field, or delete |
| 10 | Add a 30-line top section to `README.md` answering: what is this, what is "anaiis", what gets symlinked, what `*.local` files mean, how to bootstrap a new machine |

#### Phase 3 — Instrument and compound (next sprint)

| # | Action |
|---|---|
| 11 | Time the three `UserPromptSubmit` hooks individually. If aggregate >100 ms, collapse into one dispatcher with early-exit guards |
| 12 | Audit `claude/rules/*.md` against `~/.claude/projects/*/memory/feedback_*.md` for contradictions (start with `core.md` vs `feedback_agent_token_cost.md`) |
| 13 | Audit `os-darwin.bash` and any hook script for BSD-only `sed -i`, `pbcopy`, `osascript`, or Homebrew paths; either gate on `$OSTYPE` or use portable forms |
| 14 | Implement E's `/memory-mine` skill — reads across `~/.claude/projects/*/memory/` and surfaces recurring patterns as candidate rules. Only after Phases 1 and 2 |

### The final rubric (canonical for this audit)

**1. Security**
- 1.1 Confidentiality — secret-loading provenance (`${GITHUB_PAT}` resolver), tracked-vs-ignored boundary, MCP supply chain
- 1.2 Integrity / blast-radius containment — permission-bypass paths, destructive-command blocklist coverage, cross-machine identity drift

**2. Policy coherence** (D's contribution)
- 2.1 Rule self-consistency — internal contradictions across `rules/` and `memory/`
- 2.2 Hook-vs-rule overlap — instructions duplicated between an auto-loaded rule and a hook that enforces the same thing
- 2.3 Auditor=auditee — can the policy stack be evaluated by a Claude session running under it

**3. Performance / execution cost**
- 3.1 Per-prompt hook tax — measured wall-clock for `UserPromptSubmit` chain
- 3.2 Per-Bash hook tax — measured wall-clock for `PreToolUse` chain
- 3.3 Auto-loaded rule tonnage — bytes loaded into every session via `CLAUDE.md` + `rules/`
- 3.4 Cost predictability per session class — known envelope for triage, rebase, litreview workflows

**4. Skill justification** (E's domain-skill spine, sharpened by C/D)
- 4.1 Built-in collision — for each `anaiis-*`, the named axis on which it beats the built-in (corpus access, multi-step, domain knowledge)
- 4.2 Domain differentiation — which skills are I-O Psych moats (litreview, peerreview, duckdb, copyedit, graphify) and which are commodity
- 4.3 Trigger discipline — explicit-only vs auto-trigger; collisions across skills

**5. Hygiene & legibility** (A's spine)
- 5.1 Artifact hygiene — living docs vs stale audit outputs in tracked tree
- 5.2 Test/production separation — no `test-*.sh` under `hooks/`
- 5.3 Naming legibility — glossary for `anaiis-`, no fear-naming (`claude-yolo`)
- 5.4 Discoverability — README answers "what is this in 60 seconds"

**6. Portability**
- 6.1 macOS-ism scan — no BSD-only flags, no Homebrew-only paths in shared layers
- 6.2 Profile model clarity — be honest about one profile + machine-local; or build real profile routing
- 6.3 Symlink install resilience — collision behavior with pre-existing real files and stale symlinks

### The one thing to do first

**Remove the `claude-yolo` alias and flip `skipDangerousModePermissionPrompt` to `false`.** Two-line change. Restores the inline blocklist as a real guardrail before anything else gets audited. Everything else in this report is downstream of that fix.
