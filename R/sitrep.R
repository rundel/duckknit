#' DuckDB CLI situation report
#'
#' Reports the status of the DuckDB CLI tool including its location, version,
#' and any active sessions.
#'
#' @return Invisibly returns a list with `path`, `version`, and `sessions`.
#' @export
duckdb_sitrep = function() {
  cli_found = tryCatch(
    { path = find_duckdb(); TRUE },
    error = function(e) FALSE
  )

  cat("duckknit situation report\n")

  cat("========================\n\n")

  if (!cli_found) {
    source = if (!is.null(getOption("duckknit.duckdb"))) {
      paste0("option duckknit.duckdb = \"", getOption("duckknit.duckdb"), "\"")
    } else {
      "PATH"
    }
    cat("DuckDB CLI: NOT FOUND\n")
    cat("  Source:", source, "\n")
    cat("\n  Install DuckDB or set options(duckknit.duckdb = '/path/to/duckdb')\n")
    return(invisible(list(path = NA, version = NA, sessions = list())))
  }

  source = if (!is.null(getOption("duckknit.duckdb"))) {
    "option (duckknit.duckdb)"
  } else {
    "PATH"
  }

  version = tryCatch(
    processx::run(path, "--version")$stdout,
    error = function(e) NA_character_
  )
  version = trimws(version)

  cat("DuckDB CLI\n")
  cat("  Path:   ", path, "\n")
  cat("  Source:  ", source, "\n")
  cat("  Version:", version, "\n")

  session_names = ls(.sessions)
  n_sessions = length(session_names)

  cat("\nSessions:", n_sessions, "active\n")

  if (n_sessions > 0) {
    for (name in session_names) {
      proc = .sessions[[name]]
      alive = proc$is_alive()
      db = if (name %in% ls(.session_dbs)) .session_dbs[[name]] else ":memory:"
      status = if (alive) "running" else "dead"
      marker = if (identical(name, .state$last_session)) " *" else ""
      cat("  -", name, paste0("(", status, ")"), "->", db, marker, "\n")
    }
  }

  invisible(list(
    path = path, version = version,
    sessions = session_names, last_session = .state$last_session
  ))
}
