# Start a new DuckDB CLI session

Launches a persistent DuckDB CLI process connected to the specified
database.

## Usage

``` r
duckknit_start_session(name, db = ":memory:")
```

## Arguments

- name:

  Character. Name for the session.

- db:

  Character. Path to a DuckDB database file, or `":memory:"` for an
  in-memory database.

## Value

A [`processx::process`](http://processx.r-lib.org/reference/process.md)
object (invisibly).

## Examples

``` r
s = duckknit_start_session("demo")
s$is_alive()
#> [1] TRUE
duckknit_kill_session("demo")
```
