# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

duckknit is an R package that provides a knitr chunk engine for DuckDB's CLI. Users write `{duckdb}` chunks in Rmd/qmd documents targeting database files, with persistent CLI sessions across chunks.

## Architecture

- `R/session.R` — Session registry (`.sessions`, `.session_dbs`, `.state` environments) and processx process lifecycle
- `R/exec.R` — SQL execution with `.print`-based sentinel detection for output capture
- `R/engine.R` — knitr engine function (`eng_duckdb`) with chunk option handling, session resolution, and ANSI processing
- `R/sitrep.R` — `duckdb_sitrep()` diagnostic function
- `R/zzz.R` — `.onLoad` (engine registration) and `.onUnload` (session cleanup)

### Sentinel mechanism

Each session is a persistent `processx::process` running `duckdb <db>`. Commands are sent via stdin; output is captured by appending `.print <unique_sentinel>` after each chunk's SQL and reading stdout until the sentinel appears. The `.print` command outputs raw text regardless of the current output mode, so it never interferes with user formatting settings. Sentinel detection uses `grep` (substring match) rather than exact `match` because DuckDB commands like `.tables` emit ANSI escape codes that can wrap the sentinel line.

### Session resolution

The engine resolves which session to use via `resolve_session()` in this priority order:

1. `session` option provided → use/create that named session
2. `db` option provided (no `session`) → find existing session for that db via `find_session_by_db()`, or create a new auto-named one (`session-1`, `session-2`, etc.)
3. Neither provided → reuse `.state$last_session`, or create first auto-named session

Every chunk execution updates `.state$last_session`. The counter and last-session state reset on `duckknit_kill_all_sessions()`.

### Concurrent database protection

DuckDB's single-writer file lock prevents multiple CLI processes from opening the same database file. `duckknit_start_session()` checks `.session_dbs` before launching a new process and errors immediately if another live session holds the same file. In-memory (`:memory:`) sessions are exempt.

### Path normalization

`norm_db_path()` normalizes database file paths by resolving the parent directory (which always exists) then appending the filename. This handles the macOS `/var` → `/private/var` symlink issue where `normalizePath()` produces different results depending on whether the file exists yet.

### ANSI handling

DuckDB dot-commands (`.tables`, `.schema`, etc.) emit ANSI color codes. The `ansi` chunk option controls handling: `FALSE` (default) strips them, `TRUE` preserves them, `"html"` converts via `cli::ansi_html()`. Stripping happens in the engine after `duckknit_exec()` returns, not in exec itself.

### Error handling

DuckDB errors go to stderr; valid output goes to stdout. The sentinel always appears on stdout even after errors. By default, errors stop document rendering (`stop()`). With `error: true`, error text is included in the output instead.

## Common Commands

```sh
# Document (regenerate NAMESPACE and man pages)
Rscript -e "devtools::document()"

# Build and check
Rscript -e "devtools::check()"

# Install locally
Rscript -e "devtools::install()"

# Run tests (once tests exist)
Rscript -e "devtools::test()"

# Run a single test file
Rscript -e "testthat::test_file('tests/testthat/test-<name>.R')"

# Render README
quarto render README.qmd

# Build pkgdown site
Rscript -e "pkgdown::build_site()"
```

Note: snapshot tests require `NOT_CRAN=true` to run. The qmd render snapshot test requires the package to be installed (not just `load_all()`), because quarto spawns a child R process.

## Code Style

- Use `=` for assignment, not `<-`
- For functions from other packages: add the package to DESCRIPTION Imports and use `pkg::fun()` syntax rather than `@importFrom`
- Minimize inline comments; only comment to explain *why*, not *how*
