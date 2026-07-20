# List active DuckDB CLI sessions

Returns a tibble summarizing all registered sessions.

## Usage

``` r
duckknit_list_sessions()
```

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
with columns `session`, `status`, `db`, and `active` (logical, `TRUE`
for the last used session).

## Examples

``` r
duckknit_start_session("demo")
duckknit_list_sessions()
#> # A tibble: 1 × 4
#>   session status  db       active
#>   <chr>   <chr>   <chr>    <lgl> 
#> 1 demo    running :memory: FALSE 
duckknit_kill_all_sessions()
```
