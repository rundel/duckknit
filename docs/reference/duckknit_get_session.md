# Get or create a DuckDB CLI session

Returns an existing session if one with the given name is alive,
otherwise starts a new one. If `db` is supplied and an existing live
session is connected to a different database, an error is raised.

## Usage

``` r
duckknit_get_session(name, db = NULL)
```

## Arguments

- name:

  Character. Name for the session.

- db:

  Character. Path to a DuckDB database file, or `":memory:"` for an
  in-memory database. When `NULL` (the default), an existing session is
  returned regardless of its database and a new session uses
  `":memory:"`.

## Value

A [`processx::process`](http://processx.r-lib.org/reference/process.md)
object (invisibly).
