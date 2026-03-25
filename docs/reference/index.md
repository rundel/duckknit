# Package index

## Knitr Engine

The chunk engine for R Markdown and Quarto documents.

- [`eng_duckdb()`](https://rundel.github.io/duckknit/reference/eng_duckdb.md)
  : Knitr engine for DuckDB CLI

## Session Management

Create, retrieve, and clean up persistent DuckDB CLI sessions.

- [`duckknit_start_session()`](https://rundel.github.io/duckknit/reference/duckknit_start_session.md)
  : Start a new DuckDB CLI session
- [`duckknit_get_session()`](https://rundel.github.io/duckknit/reference/duckknit_get_session.md)
  : Get or create a DuckDB CLI session
- [`duckknit_kill_session()`](https://rundel.github.io/duckknit/reference/duckknit_kill_session.md)
  : Kill a DuckDB CLI session
- [`duckknit_list_sessions()`](https://rundel.github.io/duckknit/reference/duckknit_list_sessions.md)
  : List active DuckDB CLI sessions
- [`duckknit_kill_all_sessions()`](https://rundel.github.io/duckknit/reference/duckknit_kill_all_sessions.md)
  : Kill all DuckDB CLI sessions

## Execution

Send SQL to a DuckDB CLI session and capture output.

- [`duckknit_exec()`](https://rundel.github.io/duckknit/reference/duckknit_exec.md)
  : Execute SQL in a DuckDB CLI session

## Diagnostics

Inspect the current state of the DuckDB CLI and active sessions.

- [`duckdb_sitrep()`](https://rundel.github.io/duckknit/reference/duckdb_sitrep.md)
  : DuckDB CLI situation report
