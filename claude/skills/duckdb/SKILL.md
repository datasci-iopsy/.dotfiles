# DuckDB Analytics

Run ad hoc SQL analytics on local parquet and CSV files using the DuckDB CLI.

## When to use this skill

- User asks to analyze, query, or explore a local parquet or CSV file
- User wants to inspect schema, row counts, or column distributions
- User has data exported from BigQuery for local analysis
- User asks to join, aggregate, or filter structured data files

## Tool selection rules

| Task | Tool |
|---|---|
| SQL aggregations, joins, filters, window functions on local files | DuckDB CLI |
| Reading parquet or CSV directly without loading into memory | DuckDB CLI |
| Plotting (matplotlib, plotly, seaborn) | Python |
| ML pipelines, sklearn, feature engineering | Python |
| Complex control flow or custom transforms | Python |
| Writing results to a new parquet or CSV file | DuckDB CLI |

**Never** load a multi-GB parquet file into pandas with `pd.read_parquet()`. DuckDB reads parquet natively with streaming/out-of-core execution.

Before using Python for data work, check whether the `duckdb` Python package is installed:

```bash
pip list | grep duckdb
```

If not installed, default to the CLI rather than installing without asking.

## Standard workflow

### 1. Check file size first

```bash
ls -lh path/to/file.parquet
```

- Under ~100MB: safe to preview with `SELECT * LIMIT 10`
- Over 100MB: use column projections, filters, and aggregations; avoid `SELECT *` without `LIMIT`
- Multiple files: use glob patterns (see below)

### 2. Introspect schema before querying

Parquet:
```bash
duckdb -c "DESCRIBE SELECT * FROM 'path/to/file.parquet';"
duckdb -c "SELECT COUNT(*) FROM 'path/to/file.parquet';"
duckdb -c "SELECT * FROM 'path/to/file.parquet' LIMIT 5;"
```

CSV (let DuckDB auto-detect schema):
```bash
duckdb -c "DESCRIBE SELECT * FROM read_csv_auto('path/to/file.csv');"
duckdb -c "SELECT * FROM read_csv_auto('path/to/file.csv') LIMIT 5;"
```

### 3. Query patterns

One-shot query with `-c`:
```bash
duckdb -c "SELECT col, COUNT(*) FROM 'file.parquet' GROUP BY col ORDER BY 2 DESC LIMIT 20;"
```

JSON output for piping to jq:
```bash
duckdb -json -c "SELECT col, COUNT(*) FROM 'file.parquet' GROUP BY col;" | jq '.[]'
```

Multiple files via glob:
```bash
duckdb -c "SELECT * FROM 'data/*.parquet' LIMIT 10;"
duckdb -c "SELECT COUNT(*) FROM 'exports/2024-*.parquet';"
```

Multi-statement analysis via heredoc (in-memory, no persistent db):
```bash
duckdb <<'SQL'
CREATE TABLE t AS SELECT * FROM 'file.parquet';
SELECT column_name, column_type FROM information_schema.columns WHERE table_name = 't';
SELECT COUNT(*), AVG(value_col) FROM t WHERE condition;
SQL
```

### 4. Export results

```bash
duckdb -c "COPY (SELECT col, COUNT(*) FROM 'file.parquet' GROUP BY col) TO 'output.csv' (HEADER, DELIMITER ',');"
duckdb -c "COPY (SELECT * FROM 'file.parquet' WHERE condition) TO 'filtered.parquet' (FORMAT PARQUET);"
```

## Guardrails

- Do not create persistent `.duckdb` database files unless the user explicitly asks. Use in-memory mode (no db path argument).
- Do not install Python packages (`duckdb`, `pandas`, `pyarrow`) without asking. The CLI handles the common analytical case.
- Do not dump large result sets into context. Summarize with SQL aggregations or write results to a file.
- Do not use `SELECT *` without `LIMIT` on files over 100MB.

## Output format

- Small result sets (under 20 rows): render as a markdown table.
- Large result sets: show the query used and a prose summary of findings.
- Schema introspection: show as a table with column name, type, and nullable.
