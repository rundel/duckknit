# duckknit ![duckknit website](reference/figures/duckknit_hex.png)

duckknit provides a [knitr](https://yihui.org/knitr/) chunk engine that
interfaces with the [DuckDB](https://duckdb.org/) command-line
interface. It allows you to write [duckdb](https://r.duckdb.org/) code
chunks in R Markdown and Quarto documents that execute SQL against
DuckDB databases, with persistent sessions that carry state across
chunks.

## Prerequisites

The DuckDB CLI must be installed and available on your `PATH`. See the
[DuckDB installation guide](https://duckdb.org/docs/installation/) for
instructions.

You can verify your installation with:

``` r

duckdb_sitrep()
#> duckknit situation report
#> ========================
#> 
#> DuckDB CLI
#>   Path:    /opt/homebrew/bin/duckdb 
#>   Version: v1.5.1 (Variegata) 7dbb2e646f 
#> 
#> Sessions: 0 active
```

## Installation

You can install the development version of duckknit from GitHub with:

``` r

# install.packages("pak")
pak::pak("rundel/duckknit")
```

## Usage

Load the package to register the `duckdb` knitr engine:

``` r

library(duckknit)
```

Then use [duckdb](https://r.duckdb.org/) chunks in your document. By
default, chunks use an in-memory database and each chunk reuses the last
active session, so state persists automatically:

```` markdown
```{duckdb}
CREATE TABLE penguins (species TEXT, island TEXT, bill_length DOUBLE);
INSERT INTO penguins VALUES
  ('Adelie',    'Torgersen', 39.1),
  ('Gentoo',    'Biscoe',    47.3),
  ('Chinstrap', 'Dream',     46.5);
```
````

```` markdown
```{duckdb}
SELECT * FROM penguins ORDER BY bill_length DESC;
```
````

``` R
#> ┌───────────┬───────────┬─────────────┐
#> │  species  │  island   │ bill_length │
#> │  varchar  │  varchar  │   double    │
#> ├───────────┼───────────┼─────────────┤
#> │ Gentoo    │ Biscoe    │        47.3 │
#> │ Chinstrap │ Dream     │        46.5 │
#> │ Adelie    │ Torgersen │        39.1 │
#> └───────────┴───────────┴─────────────┘
```

### Database files

Use the `db` chunk option to target a specific database file. A new
session is created automatically and subsequent chunks without options
continue using it:

```` markdown
```{duckdb}
#| db: my.duckdb
CREATE TABLE scores (name TEXT, score INT);
INSERT INTO scores VALUES ('Alice', 95), ('Bob', 87);
```
````

```` markdown
```{duckdb}
.tables
```
````

``` R
#>  ───── my ────── 
#>  ──── main ───── 
#> ┌───────────────┐
#> │    scores     │
#> │               │
#> │ name  varchar │
#> │ score integer │
#> │               │
#> │    2 rows     │
#> └───────────────┘
```

```` markdown
```{duckdb}
SELECT * FROM scores;
```
````

``` R
#> ┌─────────┬───────┐
#> │  name   │ score │
#> │ varchar │ int32 │
#> ├─────────┼───────┤
#> │ Alice   │    95 │
#> │ Bob     │    87 │
#> └─────────┴───────┘
```

### Output modes

Use the `mode` chunk option or the `.mode` dot-command to control output
formatting. Mode changes made with `.mode` persist for the remainder of
the session:

```` markdown
```{duckdb}
#| mode: csv
SELECT * FROM scores;
```
````

``` R
#> name,score
#> Alice,95
#> Bob,87
```

```` markdown
```{duckdb}
.mode markdown
SELECT * FROM scores;
```
````

``` R
#> | name  | score |
#> |-------|------:|
#> | Alice | 95    |
#> | Bob   | 87    |
```

### Named sessions

The `session` option lets you give a session an explicit name. This is
useful for switching between sessions or creating independent
workspaces:

```` markdown
```{duckdb}
#| session: analysis
SELECT 42 as answer;
```
````

``` R
#> ┌────────┐
#> │ answer │
#> │ int32  │
#> ├────────┤
#> │     42 │
#> └────────┘
```

```` markdown
```{duckdb}
#| session: analysis
SELECT 'still here' as status;
```
````

``` R
#> ┌────────────┐
#> │   status   │
#> │  varchar   │
#> ├────────────┤
#> │ still here │
#> └────────────┘
```

### Managing sessions

Use
[`duckdb_sitrep()`](https://rundel.github.io/duckknit/reference/duckdb_sitrep.md)
to see active sessions. The `*` marks the last used session:

```` markdown
```{r}
duckdb_sitrep()
```
````

``` R
#> duckknit situation report
#> ========================
#> 
#> DuckDB CLI
#>   Path:    /opt/homebrew/bin/duckdb 
#>   Version: v1.5.1 (Variegata) 7dbb2e646f 
#> 
#> Sessions: 3 active
#>   - analysis (running) -> :memory:  * 
#>   - session-1 (running) -> :memory:  
#>   - session-2 (running) -> /Users/rundel/Desktop/Projects/duckknit/my.duckdb
```

Use
[`duckknit_list_sessions()`](https://rundel.github.io/duckknit/reference/duckknit_list_sessions.md)
to get a tibble of sessions:

``` r

duckknit_list_sessions()
#> # A tibble: 3 × 4
#>   session   status  db                                                active
#>   <chr>     <chr>   <chr>                                             <lgl> 
#> 1 analysis  running :memory:                                          TRUE  
#> 2 session-1 running :memory:                                          FALSE 
#> 3 session-2 running /Users/rundel/Desktop/Projects/duckknit/my.duckdb FALSE
```

You can also kill individual sessions or all sessions at once:

``` r

duckknit_kill_session("analysis")
duckknit_kill_all_sessions()
```

## Chunk options

| Option | Default | Description |
|----|----|----|
| `db` | `":memory:"` | Path to a DuckDB database file |
| `session` | *(auto)* | Session name — reuses if it exists, creates if new. When omitted, the last used session is reused. |
| `mode` | *(not set)* | DuckDB output mode (`csv`, `markdown`, `json`, etc.) |
| `timeout` | `30000` | Max milliseconds to wait for output |

Standard knitr options (`echo`, `eval`, `results`, `include`, `error`)
are also supported.

## Configuration

If the `duckdb` binary is not on your `PATH`, you can specify its
location:

``` r

options(duckknit.duckdb = "/path/to/duckdb")
```

## Disclaimer

This project was vibe coded in an afternoon using [Claude
Code](https://claude.ai/code). The hex logo was generated via ChatGPT.
