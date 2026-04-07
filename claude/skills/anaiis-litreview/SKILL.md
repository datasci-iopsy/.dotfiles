# Literature Review

Conduct a focused literature review on a topic or subdirectory of the references collection.

## Scope

$ARGUMENTS — a topic keyword, subdirectory name, or research question.
Examples: `/litreview glmm`, `/litreview "power analysis longitudinal"`, `/litreview burnout-engagement`

## Setup detection

Before querying, check for the catalog and text index:

```bash
ls -lh references_catalog.parquet 2>/dev/null || \
  ls -lh ~/Documents/icloud-docs/prof-edu/references/references_catalog.parquet 2>/dev/null
```

- **Catalog exists**: proceed with the workflow below
- **Catalog missing**: stop and inform the user. Do not attempt to read PDFs directly at scale.
  Report: "No catalog found. Run `python3 build_catalog.py` in the references directory to build it first."

## Workflow

### Step 1: Query the catalog (DuckDB)

Always query the catalog before reading any PDF. This is the primary narrowing step.

```bash
duckdb -json -c "
  SELECT title, authors, year, subdirectory, file_path, abstract
  FROM 'references_catalog.parquet'
  WHERE (
    subdirectory ILIKE '%<topic>%'
    OR title ILIKE '%<keyword>%'
    OR abstract ILIKE '%<keyword>%'
  )
  AND quality_score > 0.4
  ORDER BY year DESC
  LIMIT 30;
"
```

Adapt the WHERE clause to the user's query. Use multiple ILIKE conditions joined with OR to cast a wider net. If the subdirectory name is known exactly, filter on it directly to reduce noise.

Inspect the results:
- If 0 results: broaden the keyword or remove the subdirectory filter
- If > 20 results: add a more specific keyword filter or restrict to subdirectory
- Target: 8-15 candidate papers to evaluate

### Step 2: Narrow by abstract review (in context, no reads)

From the catalog results, rank the candidates based on title, authors, year, and abstract text already returned by the query. Do this reasoning in context — do not read PDFs yet.

Select the 3-5 papers most relevant to the user's specific question. Prefer:
- Papers where the abstract directly addresses the query
- Higher-quality catalog entries (quality_score closer to 1.0)
- More recent papers unless the user asks for foundational/older work

### Step 3: Full-text keyword search (ripgrep, if available)

If the catalog abstracts are insufficient to distinguish candidates, use ripgrep on extracted text files:

```bash
rg -l "<keyword>" ~/Documents/icloud-docs/prof-edu/references/<subdirectory>/ 2>/dev/null
```

Use this to verify a specific method, finding, or term appears in the paper body, not just the abstract.

Skip this step if `.txt` files do not exist alongside the PDFs — check with:
```bash
ls ~/Documents/icloud-docs/prof-edu/references/<subdirectory>/*.txt 2>/dev/null | head -3
```

### Step 4: Deep read selected papers (Read tool)

Read only the 3-5 papers selected in Step 2 (or confirmed in Step 3). Use the `pages` parameter for large PDFs:
- Pages 1-3: title, authors, abstract, introduction (orient to argument)
- Pages with methods section: find via page scan if needed
- Final pages: discussion, conclusion, limitations

Hard limit: **5 PDFs per review pass**. If the user needs broader coverage, run a second pass with a refined query.

Respect the read-only analyst role established in the project CLAUDE.md.

### Step 5: Synthesize

After reading, produce a synthesis — not a list of summaries. Structure around themes, agreements, contradictions, and gaps relevant to the user's query.

Cite as: Author(s) (Year) — use the catalog `authors` and `year` fields for accuracy.

## Output format

```
## Catalog query
[Show the DuckDB query used and row count returned]

## Candidate papers reviewed
[List the 3-5 papers selected, with title, authors, year, file path]

## Synthesis
[Thematic synthesis addressing the user's query]

## Gaps and next steps
[What the reviewed papers do not cover; suggested follow-up queries or subdirectories]
```

## Hard limits

- Never read more than 5 PDFs in a single pass
- Never attempt to read all PDFs in a subdirectory
- Always query the catalog first; never skip to reading
- Do not summarize papers individually — synthesize across them
- Do not fabricate citations; use only papers confirmed via catalog or direct read
