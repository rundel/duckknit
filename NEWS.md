# duckknit (development version)

* Sessions now launch with `DUCKDB_AGENT_MODE=0` so that DuckDB 2.0.0's agent
  mode (which is auto-enabled when run from AI coding tools) does not alter
  output formatting or error reporting. The new `duckknit.agent_mode` option
  can be set to `TRUE` to force agent mode on.

# duckknit 0.1.0

* Initial release.
* `{duckdb}` knitr engine with persistent CLI sessions across chunks.
* Chunk options: `db`, `session`, `mode`, `timeout`, `ansi`.
* `duckknit_sitrep()` for diagnostics.
