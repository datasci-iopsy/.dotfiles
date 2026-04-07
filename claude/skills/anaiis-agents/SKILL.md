---
name: anaiis-agents
description: Orchestrate parallel subagents for comparative analyses, multi-source research, codebase exploration across domains, and any task with independent subtasks that benefit from concurrent execution to minimize wall-clock time
---

# Agent Orchestration

Decompose tasks into parallel subagents when independent subtasks exist. Fire automatically -- the user should not need to ask for parallelism explicitly.

## When to activate

Activate when the task matches ANY of these patterns:

| Pattern | Example |
|---|---|
| Comparative analysis (A vs B) | "Compare DuckDB vs pandas on this file", "benchmark three approaches" |
| Multi-file analysis with unrelated sources | "Summarize findings across these 4 reports" |
| Multi-source research with independent angles | "What does the literature say from clinical, statistical, and policy perspectives?" |
| Codebase exploration across 3+ unrelated modules | "How do auth, billing, and notifications handle errors?" |
| Independent setup tasks | "Configure linting, testing, and CI" |
| Explicit parallelism request | "Run these in parallel", "use agents for this" |

Do NOT activate when:

- Task is a single linear thread (one file, one query, one fix)
- Subtasks have serial dependencies (output of A feeds B)
- Entire task fits in under 4 tool calls
- User is asking a question, not requesting work

## Decision framework

### Step 1: Decompose the task

List each subtask and whether it depends on another subtask's output. Independent subtasks (no shared inputs/outputs) are candidates for parallel agents. Dependent subtasks run sequentially inline.

### Step 2: Choose a strategy

| Independent subtask count | Strategy |
|---|---|
| 1 | No agents. Do inline. |
| 2-3 | Spawn parallel subagents |
| 4-5 | Spawn parallel subagents, cap at 5 concurrent |
| 6+ | Batch into 4-5 logical groups, one agent per group |
| Any with mid-execution coordination | Sequential inline. Do not use agents. |

### Step 3: Select model per agent

| Subtask type | Model |
|---|---|
| File reads, schema inspection, grep, row counts | haiku |
| SQL analysis, code review, summarization | sonnet |
| Multi-step reasoning, cross-source synthesis, architectural decisions | opus |

Default to sonnet when uncertain. Use haiku aggressively for gather-and-report tasks -- most subagent work qualifies.

## Spawn protocol

Each agent prompt must include:

1. **One focused task** -- never bundle unrelated work into a single agent
2. **All file paths and context needed** -- agents have no shared memory or state
3. **Expected output format** -- what to return and how to structure it
4. **Scope boundary** -- what not to do (e.g., "read only, do not modify files")

Keep spawn prompts under 200 words. The main token cost driver is context accumulated during execution, not the prompt size itself.

## Synthesis protocol

After all agents return:

1. Do not paste raw agent output into the response
2. Cross-synthesize: identify agreements, contradictions, and patterns across agents
3. Present a unified answer with attribution (which subtask produced each finding)
4. If an agent returned incomplete results, note it and offer to retry that piece only

## Cost guardrails

- **Prefer subagents over agent teams.** Subagents return summarized results; agent teams maintain full per-agent context with coordination overhead (~7x token cost). Only use agent teams when teammates must communicate mid-task.
- **Cap at 5 parallel agents** per user request.
- **Skip parallelism for short tasks.** If the work would take under 4 sequential tool calls, the token overhead of spawning agents exceeds the benefit.
- **Cap agent depth at 10 tool calls.** If a subtask needs more, it is too broad -- split it or run it inline.
- **Model down where possible.** Haiku at ~$0.25/MTok vs Sonnet at ~$3/MTok. A gather-and-report agent should never run on Sonnet.

## Planning vs implementation token profiles

Exploration agents are expensive and unbounded. On a large codebase, a single Explore agent can read 30+ files and consume 50k+ tokens because it follows patterns speculatively. Implementation agents are bounded -- they write or edit specific files and cost proportionally less.

**During planning:**
- Prefer targeted Glob and Grep over Explore agents when you know what you're looking for
- Use at most 1-2 Explore agents per planning session, with tightly scoped prompts
- Avoid broad "explore this entire layer" prompts on large codebases because they will read everything
- Prompt the user for targeted searches BEFORE exploring entire layer to avoid reading everything
- Sequential exploration is acceptable; the user's wall-clock patience is not the bottleneck

**During implementation:**
- Parallel agents are justified for genuinely independent file writes/edits (e.g., 3 unrelated models, separate config files)
- Token cost is predictable and bounded by the files being modified

The "thorough planning = cheaper coding" argument breaks down when planning consumes so much of the session budget that implementation cannot proceed. Prefer a leaner plan that can be refined during implementation over an exhaustive plan that exhausts the session.

## Integration with domain skills

This skill provides the orchestration layer. Domain skills provide the expertise. When spawning agents for domain work, reference the skill by name so the agent picks it up from its own context -- do not duplicate domain skill logic in the spawn prompt.

| Domain | Skill to reference |
|---|---|
| File/data analysis (parquet, CSV, avro, JSON, SQLite) | anaiis-duckdb |
| Literature and document research | anaiis-litreview |
| Environment health checks | anaiis-preflight (run inline, not in an agent) |

**anaiis-preflight** is always run inline before spawning agents. Do not waste an agent on it.
