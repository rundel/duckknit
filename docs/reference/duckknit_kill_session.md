# Kill a DuckDB CLI session

Kill a DuckDB CLI session

## Usage

``` r
duckknit_kill_session(name)
```

## Arguments

- name:

  Character. Name of the session to kill. Killing a session that does
  not exist is a no-op.

## Value

`NULL` (invisibly). Called for its side effect.

## Examples

``` r
duckknit_start_session("demo")
duckknit_kill_session("demo")
```
