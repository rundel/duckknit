# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

duckknit is an R package that provides a knitr chunk engine for DuckDB's CLI. Users write `{duckdb}` chunks in Rmd/qmd documents targeting database files, with persistent CLI sessions across chunks.

## Architecture

- `R/session.R` — Session registry (`.sessions` environment) and processx process lifecycle
- `R/exec.R` — SQL execution with `.print`-based sentinel detection for output capture
- `R/engine.R` — knitr engine function (`eng_duckdb`) with chunk option handling
- `R/zzz.R` — `.onLoad` (engine registration) and `.onUnload` (session cleanup)

Key design: each session is a persistent `processx::process` running `duckdb <db>`. Commands are sent via stdin; output is captured by appending `.print <unique_sentinel>` after each chunk's SQL and reading stdout until the sentinel appears.

## Common Commands

```sh
# Document (regenerate NAMESPACE and man pages)
Rscript -e "devtools::document()"

# Build and check
R CMD build .
R CMD check duckknit_*.tar.gz

# Install locally
Rscript -e "devtools::install()"

# Run tests (once tests exist)
Rscript -e "devtools::test()"

# Run a single test file
Rscript -e "testthat::test_file('tests/testthat/test-<name>.R')"
```

## Code Style

- Use `=` for assignment, not `<-`
- For functions from other packages: add the package to DESCRIPTION Imports and use `pkg::fun()` syntax rather than `@importFrom`
- Minimize inline comments; only comment to explain *why*, not *how*
