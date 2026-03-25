# List active DuckDB CLI sessions

Returns a tibble summarising all registered sessions.

## Usage

``` r
duckknit_list_sessions()
```

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
with columns `session`, `status`, `db`, and `active` (logical, `TRUE`
for the last used session).
