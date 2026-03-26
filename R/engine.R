#' Knitr engine for DuckDB CLI
#'
#' @param options A list of chunk options provided by knitr.
#'
#' @details
#' Supported chunk options:
#' \describe{
#'   \item{`db`}{Path to a DuckDB database file. Defaults to `":memory:"`.}
#'   \item{`session`}{Session name. If it already exists, it is reused.
#'     Otherwise a new session is created. When omitted, the last used session
#'     is reused (or a new one is created automatically).}
#'   \item{`mode`}{DuckDB output mode (e.g., `"table"`, `"markdown"`, `"csv"`).
#'     Sends `.mode <value>` before executing the chunk's SQL.}
#'   \item{`timeout`}{Maximum milliseconds to wait for output. Defaults to
#'     `30000`.}
#'   \item{`ansi`}{Controls handling of ANSI escape codes in output.
#'     `TRUE` preserves them, `FALSE` (default) strips them, and `"html"`
#'     converts them to HTML markup via [cli::ansi_html()].}
#' }
#'
#' @return A character string of formatted output for knitr.
#' @export
eng_duckdb = function(options) {
  if (!isTRUE(options$eval)) {
    return(knitr::engine_output(options, code = options$code, out = ""))
  }

  timeout = options$timeout %||% 30000L
  ansi = options$ansi %||% FALSE

  session_name = resolve_session(options$session, options$db)
  session = duckknit_get_session(session_name, options$db %||% ":memory:")
  .state$last_session = session_name

  if (!is.null(options$mode)) {
    duckknit_exec(session, paste0(".mode ", options$mode), timeout = timeout)
  }

  cmds = parse_commands(options$code)

  results = list()
  for (cmd in cmds) {
    cmd_code = paste(cmd, collapse = "\n")
    result = duckknit_exec(session, cmd_code, timeout = timeout)
    result$stdout = process_ansi(result$stdout, ansi)
    result$stderr = process_ansi(result$stderr, ansi)
    out = format_result(result, options)
    results = c(results, list(list(code = cmd, out = out)))
  }

  if (length(results) <= 1 || isTRUE(options$collapse)) {
    all_code = unlist(lapply(results, `[[`, "code"))
    if (is.null(all_code)) all_code = options$code
    all_out = paste(
      vapply(results, `[[`, character(1), "out"),
      collapse = "\n"
    )
    return(knitr::engine_output(options, code = all_code, out = all_out))
  }

  parts = vapply(results, function(r) {
    knitr::engine_output(options, code = r$code, out = r$out)
  }, character(1))
  paste(parts, collapse = "\n")
}

format_result = function(result, options) {
  if (nzchar(result$stderr)) {
    if (isTRUE(options$error)) {
      out = result$stderr
      if (nzchar(result$stdout)) {
        out = paste(result$stdout, result$stderr, sep = "\n")
      }
    } else {
      stop(result$stderr, call. = FALSE)
    }
  } else {
    out = result$stdout
  }
  out
}

parse_commands = function(lines) {
  cmds = list()
  current = character(0)
  for (line in lines) {
    trimmed = trimws(line)
    if (nchar(trimmed) == 0 && length(current) == 0) next
    if (grepl("^\\.", trimmed)) {
      if (length(current) > 0) {
        cmds = c(cmds, list(current))
        current = character(0)
      }
      cmds = c(cmds, list(line))
    } else {
      current = c(current, line)
      if (grepl(";\\s*$", trimmed)) {
        cmds = c(cmds, list(current))
        current = character(0)
      }
    }
  }
  if (length(current) > 0) cmds = c(cmds, list(current))
  cmds
}

resolve_session = function(session, db) {
  if (!is.null(session)) {
    return(session)
  }

  if (!is.null(db)) {
    existing = find_session_by_db(db)
    if (!is.null(existing)) return(existing)
    return(next_session_name())
  }

  if (!is.null(.state$last_session)) {
    return(.state$last_session)
  }

  next_session_name()
}

strip_ansi = function(x) {
  gsub("\033\\[[0-9;]*m", "", x)
}

process_ansi = function(x, ansi) {
  if (identical(ansi, "html")) {
    return(cli::ansi_html(x))
  }
  if (isTRUE(ansi)) {
    return(x)
  }
  strip_ansi(x)
}

`%||%` = function(x, y) {
  if (is.null(x)) y else x
}
