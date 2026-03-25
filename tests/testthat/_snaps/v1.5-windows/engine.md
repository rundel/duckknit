# ansi=FALSE strips ANSI codes from .tables output

    Code
      cat(result)
    Output
      .tables
       ─── memory ─── 
       ──── main ──── 
      ┌──────────────┐
      │    ansi_t    │
      │              │
      │ id   integer │
      │ name varchar │
      │              │
      │    0 rows    │
      └──────────────┘

# ansi=TRUE preserves ANSI codes in .tables output

    Code
      cat(result)
    Output
      .tables
       ─── memory ─── 
       ──── main ──── 
      ┌──────────────┐
      │    ansi_t    │
      │              │
      │ id   integer │
      │ name varchar │
      │              │
      │    0 rows    │
      └──────────────┘

# ansi='html' converts ANSI to HTML in .tables output

    Code
      cat(result)
    Output
      .tables
       ─── memory ─── 
       ──── main ──── 
      ┌──────────────┐
      │    ansi_t    │
      │              │
      │ id   integer │
      │ name varchar │
      │              │
      │    0 rows    │
      └──────────────┘

