# DuckDB CLI situation report

Reports the status of the DuckDB CLI tool including its location,
version, and any active sessions.

## Usage

``` r
duckknit_sitrep()
```

## Value

Invisibly returns a list with `path`, `version`, and `sessions`.

## Examples

``` r
duckknit_sitrep()
#> duckknit situation report
#> ========================
#> 
#> DuckDB CLI
#>   Path:    /opt/homebrew/bin/duckdb 
#>   Version: v1.5.4 (Variegata) 08e34c447b 
#> 
#> Sessions: 0 active
```
