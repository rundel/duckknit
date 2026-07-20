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

  Integer. Maximum milliseconds to wait for output. An error is thrown
  if the command does not complete within this time.

## Value

A list with `stdout` and `stderr` character strings.

## Examples

``` r
s = duckknit_start_session("demo")
result = duckknit_exec(s, "SELECT 1 + 1 AS two;")
cat(result$stdout)
#> ┌───────┐
#> │  two  │
#> │ int32 │
#> ├───────┤
#> │     2 │
#> └───────┘
duckknit_kill_session("demo")
```
