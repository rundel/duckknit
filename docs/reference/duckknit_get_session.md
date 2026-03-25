# Get or create a DuckDB CLI session

Returns an existing session if one with the given name is alive,
otherwise starts a new one.

## Usage

``` r
duckknit_get_session(name, db = ":memory:")
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
