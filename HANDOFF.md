# Session Handoff: dotfiles-precise-updates

**Last updated:** 2026-04-27
**Sessions covered:** dotfiles-precise-updates (session 1 + session 2)

---

## Session 1 summary (prior session)

### 1. DuckDB query discipline

Analyzed transcripts (15 queries in one project, 207 across 4 projects). Built purpose-based query framework.

**Files created/changed:**
- `claude/rules/duckdb.md` — NEW. Purpose-based framework (Analytical / Audit / Discovery / Inspection / Log). Five cross-purpose rules.
- `claude/skills/anaiis-duckdb/SKILL.md` — Guardrails section replaced: removed duplicated query discipline, added pointer to `rules/duckdb.md`.
- `claude/CLAUDE.md` — Added "Rules and skills" precedence section. Added `rules/duckdb.md` to index.
- `claude/skills/README.md` — Slimmed from 187 lines to 11.

**Tested:** 5 live DuckDB queries against `references_catalog.parquet` covering all 5 purpose types.

---

### 2. Agent orchestration

Cross-project scan: 182 Agent tool calls, 0% parallel spawning, ~30% redundant calls.

**Files created/changed:**
- `claude/rules/core.md` — Replaced "Use subagents liberally" with explicit threshold (< 4 tool calls = inline; never spawn for file listing/reads).
- `claude/skills/anaiis-agents/SKILL.md` — Parallel trigger hardened; Step 4 subagent type selection table; activation table; per-agent cap; integration rules-precedence note.
- `claude/agents/README.md` — NEW. Layer distinction (agents/ = named, capability-bounded; anaiis-agents = dynamic orchestration). Inventory of 3 named agents.

**Tested:** 10 scenarios via Explore agent. 9/10 CLEAR on first pass; scenario 9 (code review 3 files) fixed and re-validated.

---

### 3. Skill architecture cleanup

**Files changed:**
- `claude/skills/anaiis-gitpr/SKILL.md` — `trigger: /anaiis-gitpr` added; description updated to "Explicit /anaiis-gitpr —..."
- `claude/skills/anaiis-gitrebase/SKILL.md` — `trigger: /anaiis-gitrebase` added; description updated.
- `claude/skills/graphify/SKILL.md` — Description updated to "Explicit /graphify —...". Already had `trigger: /graphify`.
- `claude/skills/anaiis-duckdb/SKILL.md` — Description updated to signal auto-trigger.
- `claude/skills/anaiis-peerreview/SKILL.md` — Description trimmed (prior session only).
- `claude/skills/anaiis-copyedit/SKILL.md` — Description trimmed.

---

## Session 2 work (this session)

### 4. litreview and peerreview skill restructure

Both skills converted to match the architecture established for `anaiis-duckdb` and `anaiis-agents`: natural language auto-trigger, explicit activation criteria, rules-referencing guardrails, integration section with precedence statement.

**`claude/skills/anaiis-litreview/SKILL.md` — full rewrite:**
- Description: "Literature review or research synthesis on a topic — auto-triggers when the user asks to find, review, or synthesize literature from the local references catalog"
- Removed `$ARGUMENTS` / slash-command Scope section
- Added `When to activate` table (5 patterns including possessive library reference + expansion request)
- Added `Do NOT activate when` list (4 exclusions + disambiguation rule for "review my literature section")
- Setup detection: `ls` via Bash → Glob tool (rules/tools.md compliance)
- Step 1: LIMIT 30 → LIMIT 20 (conforms to `rules/duckdb.md` Discovery pattern); added explicit purpose label
- Step 3: `Bash(rg)` → Grep tool (rules/session.md prohibition on `Bash(rg)`)
- **Step 6 (NEW):** Web expansion — triggers when catalog < 5 results or user asks for broader coverage; WebSearch with DOI/ISBN confirmation required; results appear in separate "Expand your library" section
- Added Guardrails section referencing `rules/duckdb.md` and `rules/citations.md`
- Added Integration section with "Rules take precedence" statement and downstream handoff table
- Output format updated: DOI/path column in candidate papers table; "Expand your library" section with DOI/ISBN column

**`claude/skills/anaiis-peerreview/SKILL.md` — targeted edits:**
- Description: added "auto-triggers on manuscript review requests"
- Scope section (had `$ARGUMENTS`) replaced with `When to activate` table + `Do NOT activate` list
- Disambiguation note: file path present → peerreview; no file path → litreview
- Integration section: added "Rules take precedence" statement + copyedit handoff bullet
- Hard limits: added `rules/citations.md` pointer — do not name specific missing papers unless catalog-confirmed

**Validation:** 10 scenarios via Explore agent. 9/10 CLEAR on first pass; scenario 10 ("review my literature section") was AMBIGUOUS — resolved with disambiguation note in both skills. Final: **10/10 CLEAR**.

---

### 5. Citation integrity rule (new global rule)

**`claude/rules/citations.md` — NEW:**

Core principle: a citation is a specific claim about a paper (author, year, title, finding). This is distinct from conceptual knowledge — explaining JD-R theory from training is always fine; attributing a specific finding to a specific paper requires corpus confirmation or flagging.

| Source | Behavior |
|---|---|
| Catalog-confirmed (DuckDB or direct Read) | Cite normally. Include DOI/ISBN if in catalog. |
| User-provided text | Cite normally. No flag. |
| Training knowledge, not in catalog | Answer fully. Flag "not in local catalog — drawing on training knowledge." Offer web search with DOI. |
| Web search result | Must include DOI (articles) or ISBN-13 (books). Cannot confirm? Flag it. Never fabricate. |
| Books with both ISBN and DOI | ISBN-13 is primary. Include DOI if available (e.g., book chapters in edited volumes). |
| Conference papers with no identifier | Note what is available. Do not fabricate. |

**Progressive search pattern ("my library / my corpus / my references"):**
- Possessive phrasing → catalog first via DuckDB
- If < 5 results OR user asks for more → offer/execute web expansion
- Web results presented separately with DOIs/ISBNs — never mixed into catalog synthesis

**Explicit carve-outs (rule does NOT restrict):**
- Conceptual explanations of theories or models
- General characterizations of a research area
- Questions that do not require citing a specific paper
- Everyday coding, data, methodological, or general knowledge questions

**`claude/CLAUDE.md`:** Added `rules/citations.md` row to rules index.

**Skill pointers added:**
- `anaiis-litreview` hard limits: inline "do not fabricate" replaced with pointer to `rules/citations.md`
- `anaiis-peerreview` hard limits: `rules/citations.md` pointer added alongside existing "do not suggest citations" constraint

**Validation:** 10 scenarios via Explore agent. **10/10 CORRECT** including edge cases:
- In-corpus citation (normal, no flag)
- Out-of-corpus citation in general conversation (substantive answer + flag)
- Conceptual question — rule stays out of the way
- Incidental paper mention — answers fully, flags as training knowledge
- Everyday coding question — completely uninvolved
- Peerreview gap flagging — abstract gap note, no fabricated specific citation
- Explicit user-requested web search — rule satisfied, proceeds
- I-O Psychology overview — no restriction
- DOI fabrication prevention — flags when cannot confirm
- Book ISBN vs DOI precedence — ISBN-13 primary, include DOI if available

---

## Current architecture state

```
~/.dotfiles/claude/
├── CLAUDE.md                    # Entry point. Rules index + precedence statement.
├── rules/
│   ├── citations.md             # NEW (session 2): Citation integrity, DOI/ISBN, progressive search
│   ├── core.md                  # Principles, workflow, hook output rules, agent threshold
│   ├── duckdb.md                # NEW (session 1): Query discipline (purpose-based)
│   ├── environment.md           # macOS, bash, direnv, pyenv
│   ├── git.md                   # Branch naming, staging, commit discipline
│   ├── code-style.md            # Writing style, JSON/SQL/shell formatting
│   ├── python.md                # pyenv, ruff, uv
│   ├── r-conventions.md         # Vectorization, lapply/vapply, lintr
│   ├── session.md               # Token efficiency, compaction, output prefs
│   └── tools.md                 # gh, jq, gcloud, make, structured output flags
├── skills/
│   ├── README.md                # Slim (11 lines): rules/skills relationship + how to add
│   ├── anaiis-agents/           # Auto-trigger: parallel/comparative tasks
│   ├── anaiis-changelog/        # Auto-trigger: changelog from branch diff
│   ├── anaiis-copyedit/         # Auto-trigger: manuscript copyediting
│   ├── anaiis-docaudit/         # Auto-trigger: doc accuracy audit
│   ├── anaiis-duckdb/           # Auto-trigger: data analysis requests
│   ├── anaiis-gitpr/            # Explicit: trigger: /anaiis-gitpr
│   ├── anaiis-gitrebase/        # Explicit: trigger: /anaiis-gitrebase
│   ├── anaiis-litreview/        # Auto-trigger: litreview + web expansion (Step 6)
│   ├── anaiis-peerreview/       # Auto-trigger: manuscript peer review
│   ├── anaiis-preflight/        # Auto-trigger: environment health check
│   └── graphify/                # Explicit: trigger: /graphify
└── agents/
    ├── README.md                # Layer distinction + inventory table
    ├── code-reviewer.md         # Named agent: Read/Grep/Glob; used by coderabbit-fix
    ├── code-surgeon.md          # Named agent: Read/Grep/Glob/Edit; applies single fix
    └── security-auditor.md      # Named agent: Read/Grep/Glob; used by coderabbit-fix
```

---

## Key decisions and rationale

| Decision | Rationale |
|----------|-----------|
| Rules = always-on constraints; Skills = workflow within those constraints | Prevents skill content from overriding behavioral guardrails; single source of truth per topic |
| Skills reference rule files, never duplicate content | Eliminates drift; rule file is authoritative for cross-cutting concerns |
| `rules/citations.md` is a global rule, not a skill constraint | Citation integrity applies in litreview, peerreview, and general conversation — it crosses all skill boundaries |
| `rules/duckdb.md` is a global rule for the same reason | DuckDB queries appear across many skills and ad hoc requests |
| No `rules/litreview.md` or `rules/peerreview.md` | Their constraints are domain-specific (only apply when the skill is active) — belongs in the skill, not a cross-cutting rule |
| Progressive search: catalog-first, then web expansion | Keeps local corpus authoritative; prevents bubble effect; web expansion is always supplementary |
| DOI/ISBN required for all external citations | Trackability and downloadability — hallucinated DOIs resolve to wrong papers or dead links |
| Web results in separate "Expand your library" section | Prevents catalog-confirmed and training-knowledge/web citations from being mixed in synthesis |
| Possessive phrasing triggers catalog-first, not a keyword lock | "My library" signals intent, not a technical filter — progressive pattern handles both catalog-only and expand cases |
| `trigger:` field in frontmatter for explicit-only skills | Harness-level lock; description-only prevention is fragile |
| "Explicit /skill-name —" prefix in descriptions | Signals invocation model in `/` picker; prevents accidental auto-trigger |

---

## Scenario validation results (session 2)

### litreview/peerreview activation scenarios (10/10 CLEAR)

| # | Scenario | Verdict |
|---|---|---|
| 1 | Literature search on engagement and burnout | CLEAR — litreview, topic keyword pattern |
| 2 | Synthesize longitudinal SEM in references | CLEAR — litreview, research synthesis pattern |
| 3 | How many papers on burnout in catalog? | CLEAR — DuckDB inline, not litreview |
| 4 | Find Smith & Jones (2019) paper | CLEAR — targeted DuckDB lookup, not litreview |
| 5 | Review lit section for missing papers on CWB | CLEAR — litreview, gap identification pattern |
| 6 | Feedback on manuscript draft PDF | CLEAR — peerreview, manuscript pattern |
| 7 | Fix APA errors in manuscript | CLEAR — copyedit, not peerreview |
| 8 | Write peer review for journal submission | CLEAR — decline per APA ethics |
| 9 | Review paper + find papers on psych safety | CLEAR — peerreview + litreview separable by input type |
| 10 | "Review my literature section" (no file path) | CLEAR after disambiguation fix — litreview; with file path → peerreview |

### Citation integrity + DOI scenarios (10/10 CORRECT)

| # | Scenario | Verdict |
|---|---|---|
| 1 | In-corpus citation, litreview context | CORRECT — cite normally, no flag |
| 2 | Out-of-corpus citation, litreview context | CORRECT — answer + flag + offer web search |
| 3 | General knowledge, no citation needed | CORRECT — rule stays out |
| 4 | Incidental paper mention in conversation | CORRECT — answer fully + flag as training knowledge |
| 5 | Everyday coding question | CORRECT — rule completely uninvolved |
| 6 | Peerreview: noting literature gap | CORRECT — abstract gap noted, no specific citation fabricated |
| 7 | User explicitly requests web search | CORRECT — rule satisfied, Claude proceeds |
| 8 | I-O Psychology overview | CORRECT — no flag, no restriction |
| 9 | Web result without DOI | CORRECT — flagged, not fabricated |
| 10 | Book citation: ISBN vs. DOI | CORRECT after fix — ISBN-13 primary, DOI included if available |

---

## Outstanding / next session scope

### Skills not yet reviewed for description/trigger consistency

These skills in the system-reminder were not touched in either session and may need the same review:
- `install-hooks` — likely auto-trigger; description may need clarity
- `seed-project` — likely auto-trigger
- `coderabbit-fix` — likely explicit; check if `trigger:` needed
- `init` — likely explicit; check if `trigger:` needed
- `statusline` — likely explicit
- `review` — likely explicit
- `security-review` — likely explicit
- `insights` — likely explicit
- `team-onboarding` — likely explicit

### Marketplace/external skills

Skills in the system-reminder not found in `~/.dotfiles/claude/skills/` (update-config, keybindings-help, simplify, loop, schedule, claude-api) appear to come from `mattermoreai/agents` or another external source. Do not modify without identifying source.

### Drift detection

`anaiis-docaudit` is the right tool for periodic consistency checks across rules/ and skills/. No automation set up yet. Run manually when rule or skill count changes significantly.

### Parallel agent activation

0% parallel spawning observed across 182 transcript calls despite anaiis-agents mandating it. Rules sharpened but behavioral validation requires a live session post-propagation. Open the anaiis-athenaeum session and check transcripts after rule changes propagate.

### litreview web expansion (Step 6) — live validation pending

Step 6 is defined in the skill but has not been tested against a live session with WebSearch. The DOI confirmation workflow (CrossRef, Semantic Scholar, publisher page) should be validated in a real litreview session with a thin catalog result. Known edge: some conference papers have no DOI or ISBN — rule handles this with flagging, but UX should be confirmed.

---

## Files with uncommitted changes (as of session 2 end)

All changes are in `~/.dotfiles/`. Stage and commit when ready.

Suggested logical commit groupings:

```
# Session 1 commits (if not already committed)
1. claude/rules/duckdb.md + claude/CLAUDE.md + claude/skills/anaiis-duckdb/SKILL.md
   → "Add DuckDB query discipline rule and update skill guardrails"

2. claude/rules/core.md + claude/skills/anaiis-agents/SKILL.md + claude/agents/README.md
   → "Add agent orchestration threshold and subagent type selection"

3. claude/skills/README.md + anaiis-gitpr + anaiis-gitrebase + graphify + copyedit descriptions
   → "Clean up skill descriptions and add explicit trigger fields"

# Session 2 commits
4. claude/rules/citations.md + claude/CLAUDE.md (index row)
   → "Add citation integrity rule with DOI/ISBN requirements and progressive search"

5. claude/skills/anaiis-litreview/SKILL.md
   → "Restructure litreview skill: natural language trigger, web expansion step, DOI output"

6. claude/skills/anaiis-peerreview/SKILL.md
   → "Restructure peerreview skill: natural language trigger, activation criteria, rules precedence"
```
