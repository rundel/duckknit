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
      [38;5;172m ─── memory ─── 
      [00m[38;5;39m ──── main ──── 
      [00m[90m┌──────────────┐[00m[90m
      [00m[90m│    [00m[1mansi_t[00m[90m    │[00m[90m
      [00m[90m│              │[00m[90m
      [00m[90m│ [00mid[90m   [00m[90minteger[00m[90m [00m[90m│[00m[90m
      [00m[90m│ [00mname[90m [00m[90mvarchar[00m[90m [00m[90m│[00m[90m
      [00m[90m│              │[00m[90m
      [00m[90m│    [00m[90m0 rows[00m[90m    │[00m[90m
      [00m[90m└──────────────┘[00m[90m

# ansi='html' converts ANSI to HTML in .tables output

    Code
      cat(result)
    Output
      .tables
      <span class="ansi ansi-color-172"> ─── memory ─── 
      </span><span class="ansi ansi-color-39"> ──── main ──── 
      </span><span class="ansi ansi-color-0">┌──────────────┐</span>
      │    <span class="ansi ansi-bold">ansi_t</span><span class="ansi ansi-color-0">    │</span>
      │              │
      │ id<span class="ansi ansi-color-0">   </span>integer │
      │ name<span class="ansi ansi-color-0"> </span>varchar │
      │              │
      │    0 rows    │
      └──────────────┘

