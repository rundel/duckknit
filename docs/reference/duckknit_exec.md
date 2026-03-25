# Execute SQL in a DuckDB CLI session

Sends SQL code to a running DuckDB CLI process and captures the output
using a sentinel-based detection mechanism.

## Usage

``` r
duckknit_exec(session, code, timeout = 30000L)
```

## Arguments

- session:

  A
  [`processx::process`](http://processx.r-lib.org/reference/process.md)
  object (a running DuckDB CLI session).

- code:

  Character. SQL code to execute.

- timeout:

  Integer. Maximum milliseconds to wait for output.

## Value

A list with `stdout` and `stderr` character strings.
