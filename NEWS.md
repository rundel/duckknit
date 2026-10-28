# duckknit (development version)

* New `readonly` chunk option (and `readonly` argument to
  `duckknit_start_session()` and `duckknit_get_session()`) opens the database
  with the CLI's `-readonly` flag. DuckDB allows multiple processes to open
  the same file only when all of them are read-only, so this lets a document
  query a database that is also open elsewhere. `duckknit_list_sessions()`
  gains a `readonly` column.

* Opening a database file that is locked by another process (another CLI, an
  R connection via the duckdb package, etc.) now fails immediately with
  DuckDB's error message identifying the lock holder. Previously the CLI
  exited silently and the chunk waited for the full `timeout` before
  reporting a generic timeout error, which looked like a hang. More
  generally, `duckknit_exec()` now detects when the CLI process has exited
  and reports its exit status and stderr instead of timing out.

* The `prompt` chunk option now echoes code with CLI-style prompts (`D `
  before each command, continuation lines indented). In HTML output the
  prompts are drawn with CSS so they are not copied with the code. The
  strings are configurable via the `duckknit.prompt` and `duckknit.continue`
  options.

* Sessions now launch with `DUCKDB_AGENT_MODE=0` so that DuckDB 2.0.0's agent
  mode (which is auto-enabled when run from AI coding tools) does not alter
  output formatting or error reporting. The new `duckknit.agent_mode` option
  can be set to `TRUE` to force agent mode on.

# duckknit 0.1.0

* Initial release.
* `{duckdb}` knitr engine with persistent CLI sessions across chunks.
* Chunk options: `db`, `session`, `mode`, `timeout`, `ansi`.
* `duckknit_sitrep()` for diagnostics.
