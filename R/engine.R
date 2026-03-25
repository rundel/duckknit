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
#' }
#'
#' @return A character string of formatted output for knitr.
#' @export
eng_duckdb = function(options) {
  code = paste(options$code, collapse = "\n")

  if (!isTRUE(options$eval)) {
    return(knitr::engine_output(options, code = options$code, out = ""))
  }

  timeout = options$timeout %||% 30000L

  session_name = resolve_session(options$session, options$db)
  session = duckknit_get_session(session_name, options$db %||% ":memory:")
  .state$last_session = session_name

  exec_code = code
  if (!is.null(options$mode)) {
    exec_code = paste0(".mode ", options$mode, "\n", exec_code)
  }

  result = duckknit_exec(session, exec_code, timeout = timeout)

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

  knitr::engine_output(options, code = options$code, out = out)
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

`%||%` = function(x, y) {
  if (is.null(x)) y else x
}
