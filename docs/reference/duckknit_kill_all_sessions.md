# Kill all DuckDB CLI sessions

Kills every registered session and resets the automatic session name
counter.

## Usage

``` r
duckknit_kill_all_sessions()
```

## Value

`NULL` (invisibly). Called for its side effect.

## Examples

``` r
duckknit_start_session("demo1")
duckknit_start_session("demo2")
duckknit_kill_all_sessions()
```
