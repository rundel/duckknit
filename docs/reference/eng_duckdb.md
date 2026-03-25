# Knitr engine for DuckDB CLI

Knitr engine for DuckDB CLI

## Usage

``` r
eng_duckdb(options)
```

## Arguments

- options:

  A list of chunk options provided by knitr.

## Value

A character string of formatted output for knitr.

## Details

Supported chunk options:

- `db`:

  Path to a DuckDB database file. Defaults to `":memory:"`.

- `session`:

  Session name. If it already exists, it is reused. Otherwise a new
  session is created. When omitted, the last used session is reused (or
  a new one is created automatically).

- `mode`:

  DuckDB output mode (e.g., `"table"`, `"markdown"`, `"csv"`). Sends
  `.mode <value>` before executing the chunk's SQL.

- `timeout`:

  Maximum milliseconds to wait for output. Defaults to `30000`.

- `ansi`:

  Controls handling of ANSI escape codes in output. `TRUE` preserves
  them, `FALSE` (default) strips them, and `"html"` converts them to
  HTML markup via
  [`cli::ansi_html()`](https://cli.r-lib.org/reference/ansi_html.html).
