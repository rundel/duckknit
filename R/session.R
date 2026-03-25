.sessions = new.env(parent = emptyenv())
.session_dbs = new.env(parent = emptyenv())
.state = new.env(parent = emptyenv())
.state$counter = 0L
.state$last_session = NULL

next_session_name = function() {
  .state$counter = .state$counter + 1L
  paste0("session-", .state$counter)
}

find_duckdb = function() {
  path = getOption("duckknit.duckdb", default = NULL)
  if (!is.null(path)) {
    if (!file.exists(path)) {
      stop("DuckDB binary not found at: ", path, call. = FALSE)
    }
    return(path)
  }

  path = Sys.which("duckdb")
  if (nchar(path) == 0) {
    stop(
      "DuckDB CLI not found. Install it or set options(duckknit.duckdb = '/path/to/duckdb').",
      call. = FALSE
    )
  }

  path
}

norm_db_path = function(db) {
  # Resolve symlinks like /var -> /private/var on macOS by normalizing the
  # parent directory (which always exists) then appending the filename
  dir = normalizePath(dirname(db), mustWork = FALSE)
  file.path(dir, basename(db))
}

find_session_by_db = function(db) {
  if (db == ":memory:") return(NULL)

  db_norm = norm_db_path(db)
  for (name in ls(.session_dbs)) {
    if (.session_dbs[[name]] == db_norm) {
      proc = .sessions[[name]]
      if (!is.null(proc) && proc$is_alive()) {
        return(name)
      }
    }
  }
  NULL
}

#' Start a new DuckDB CLI session
#'
#' Launches a persistent DuckDB CLI process connected to the specified database.
#'
#' @param name Character. Name for the session.
#' @param db Character. Path to a DuckDB database file, or `":memory:"` for an
#'   in-memory database.
#'
#' @return A `processx::process` object (invisibly).
#' @export
duckknit_start_session = function(name, db = ":memory:") {
  if (db != ":memory:") {
    db_norm = norm_db_path(db)
    for (existing in ls(.session_dbs)) {
      if (existing != name && .session_dbs[[existing]] == db_norm) {
        existing_proc = .sessions[[existing]]
        if (!is.null(existing_proc) && existing_proc$is_alive()) {
          stop(
            "Database '", db, "' is already open in session '", existing,
            "'. DuckDB does not support concurrent connections from separate processes.",
            call. = FALSE
          )
        }
      }
    }
  }

  cmd = find_duckdb()

  proc = processx::process$new(
    command = cmd,
    args = db,
    stdin = "|", stdout = "|", stderr = "|",
    cleanup = TRUE, cleanup_tree = TRUE
  )

  .sessions[[name]] = proc
  if (db != ":memory:") {
    .session_dbs[[name]] = norm_db_path(db)
  }
  invisible(proc)
}

#' Get or create a DuckDB CLI session
#'
#' Returns an existing session if one with the given name is alive, otherwise
#' starts a new one.
#'
#' @inheritParams duckknit_start_session
#'
#' @return A `processx::process` object (invisibly).
#' @export
duckknit_get_session = function(name, db = ":memory:") {
  if (name %in% ls(.sessions)) {
    proc = .sessions[[name]]
    if (proc$is_alive()) {
      return(invisible(proc))
    }
  }

  duckknit_start_session(name, db)
}

#' Kill a DuckDB CLI session
#'
#' @param name Character. Name of the session to kill.
#'
#' @export
duckknit_kill_session = function(name) {
  if (!(name %in% ls(.sessions))) return(invisible())

  proc = .sessions[[name]]
  if (proc$is_alive()) {
    proc$kill()
  }
  rm(list = name, envir = .sessions)
  if (name %in% ls(.session_dbs)) {
    rm(list = name, envir = .session_dbs)
  }

  if (identical(.state$last_session, name)) {
    .state$last_session = NULL
  }

  invisible()
}

#' Kill all DuckDB CLI sessions
#'
#' @export
duckknit_kill_all_sessions = function() {
  for (name in ls(.sessions)) {
    duckknit_kill_session(name)
  }
  .state$counter = 0L
  .state$last_session = NULL
  invisible()
}
