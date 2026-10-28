.sessions = new.env(parent = emptyenv())
.session_dbs = new.env(parent = emptyenv())
.session_readonly = new.env(parent = emptyenv())
.state = new.env(parent = emptyenv())
.state$counter = 0L
.state$exec_counter = 0L
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

agent_mode_env = function() {
  agent = getOption("duckknit.agent_mode", default = FALSE)
  if (!is.logical(agent) || length(agent) != 1L || is.na(agent)) {
    stop(
      "Option 'duckknit.agent_mode' must be TRUE or FALSE.",
      call. = FALSE
    )
  }
  c("current", DUCKDB_AGENT_MODE = if (agent) "1" else "0")
}

norm_db_path = function(db) {
  # Resolve symlinks like /var -> /private/var on macOS by normalizing the
  # parent directory (which always exists) then appending the filename
  dir = normalizePath(dirname(db), mustWork = FALSE)
  file.path(dir, basename(db))
}

session_readonly = function(name) {
  isTRUE(.session_readonly[[name]])
}

check_readonly = function(readonly) {
  if (!is.logical(readonly) || length(readonly) != 1L || is.na(readonly)) {
    stop("`readonly` must be TRUE or FALSE.", call. = FALSE)
  }
  readonly
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
#' DuckDB allows only one process to hold a database file open for writing at
#' a time. If the file is already open elsewhere (another duckknit session, an
#' R connection via the duckdb package, or a CLI in a terminal), the CLI exits
#' immediately and this function raises an error that includes DuckDB's
#' message identifying the process holding the lock. Any number of processes
#' may share a file when every one of them opens it read-only, so set
#' `readonly = TRUE` when the database is also open elsewhere in read-only
#' mode and the document only needs to query it.
#'
#' @param name Character. Name for the session.
#' @param db Character. Path to a DuckDB database file, or `":memory:"` for an
#'   in-memory database.
#' @param readonly Logical. Open the database read-only (the CLI's
#'   `-readonly` flag). Defaults to `FALSE`. Only meaningful for database
#'   files; the CLI refuses to open an in-memory database read-only.
#'
#' @section Agent mode:
#' DuckDB CLI 2.0.0 introduced an "agent mode" that switches on automatically
#' when an AI agent environment variable (such as `AI_AGENT`) is set and
#' standard output is not a terminal. Since duckknit always communicates with
#' the CLI through pipes, this would change result formatting, emit a startup
#' banner, and report errors as JSON whenever a document is rendered from
#' within an AI coding tool. duckknit therefore sets `DUCKDB_AGENT_MODE=0` in
#' the environment of every session it launches. Set
#' `options(duckknit.agent_mode = TRUE)` to force agent mode on instead. The
#' option is read when a session starts, so changing it does not affect
#' sessions that are already running. DuckDB versions prior to 2.0.0 ignore the
#' variable.
#'
#' @return A `processx::process` object (invisibly).
#'
#' @examplesIf nzchar(Sys.which("duckdb"))
#' s = duckknit_start_session("demo")
#' s$is_alive()
#' duckknit_kill_session("demo")
#' @export
duckknit_start_session = function(name, db = ":memory:", readonly = FALSE) {
  check_readonly(readonly)

  if (db != ":memory:") {
    db_norm = norm_db_path(db)
    for (existing in ls(.session_dbs)) {
      if (existing != name && .session_dbs[[existing]] == db_norm) {
        existing_proc = .sessions[[existing]]
        shared = readonly && session_readonly(existing)
        if (!shared && !is.null(existing_proc) && existing_proc$is_alive()) {
          stop(
            "Database '", db, "' is already open in session '", existing,
            "'. DuckDB only allows concurrent access from separate processes ",
            "when all of them open the database read-only.",
            call. = FALSE
          )
        }
      }
    }
  }

  cmd = find_duckdb()

  proc = processx::process$new(
    command = cmd,
    args = c(if (readonly) "-readonly", db),
    stdin = "|", stdout = "|", stderr = "|",
    env = agent_mode_env(),
    cleanup = TRUE, cleanup_tree = TRUE
  )

  # The CLI opens the database before reading stdin, so a lock conflict or
  # unreadable file surfaces as an immediate exit
  proc$wait(timeout = 50)
  if (!proc$is_alive()) {
    stop_session_exited(proc, paste0("DuckDB CLI exited while opening '", db, "'"))
  }

  .sessions[[name]] = proc
  .session_readonly[[name]] = readonly
  if (db != ":memory:") {
    .session_dbs[[name]] = norm_db_path(db)
  }
  invisible(proc)
}

#' Get or create a DuckDB CLI session
#'
#' Returns an existing session if one with the given name is alive, otherwise
#' starts a new one. If `db` or `readonly` is supplied and an existing live
#' session was opened with a different database or access mode, an error is
#' raised.
#'
#' @param name Character. Name for the session.
#' @param db Character. Path to a DuckDB database file, or `":memory:"` for an
#'   in-memory database. When `NULL` (the default), an existing session is
#'   returned regardless of its database and a new session uses `":memory:"`.
#' @param readonly Logical. Whether the database should be open read-only.
#'   When `NULL` (the default), an existing session is returned regardless of
#'   its access mode and a new session is opened read/write.
#'
#' @return A `processx::process` object (invisibly).
#'
#' @examplesIf nzchar(Sys.which("duckdb"))
#' s1 = duckknit_get_session("demo")
#' s2 = duckknit_get_session("demo")
#' identical(s1$get_pid(), s2$get_pid())
#' duckknit_kill_session("demo")
#' @export
duckknit_get_session = function(name, db = NULL, readonly = NULL) {
  if (!is.null(readonly)) check_readonly(readonly)

  if (name %in% ls(.sessions)) {
    proc = .sessions[[name]]
    if (proc$is_alive()) {
      if (!is.null(db)) {
        registered = if (name %in% ls(.session_dbs)) .session_dbs[[name]] else ":memory:"
        requested = if (db == ":memory:") ":memory:" else norm_db_path(db)
        if (registered != requested) {
          stop(
            "Session '", name, "' is already connected to '", registered,
            "', not '", db, "'. Kill it first or use a different session name.",
            call. = FALSE
          )
        }
      }
      if (!is.null(readonly) && readonly != session_readonly(name)) {
        mode = function(ro) if (ro) "read-only" else "read/write"
        stop(
          "Session '", name, "' is already open ", mode(session_readonly(name)),
          ", not ", mode(readonly), ". Kill it first or use a different session name.",
          call. = FALSE
        )
      }
      return(invisible(proc))
    }
  }

  duckknit_start_session(name, db %||% ":memory:", readonly %||% FALSE)
}

#' Kill a DuckDB CLI session
#'
#' @param name Character. Name of the session to kill. Killing a session
#'   that does not exist is a no-op.
#'
#' @return `NULL` (invisibly). Called for its side effect.
#'
#' @examplesIf nzchar(Sys.which("duckdb"))
#' duckknit_start_session("demo")
#' duckknit_kill_session("demo")
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
  if (name %in% ls(.session_readonly)) {
    rm(list = name, envir = .session_readonly)
  }

  if (identical(.state$last_session, name)) {
    .state$last_session = NULL
  }

  invisible()
}

#' Kill all DuckDB CLI sessions
#'
#' Kills every registered session and resets the automatic session name
#' counter.
#'
#' @return `NULL` (invisibly). Called for its side effect.
#'
#' @examplesIf nzchar(Sys.which("duckdb"))
#' duckknit_start_session("demo1")
#' duckknit_start_session("demo2")
#' duckknit_kill_all_sessions()
#' @export
duckknit_kill_all_sessions = function() {
  for (name in ls(.sessions)) {
    duckknit_kill_session(name)
  }
  .state$counter = 0L
  .state$last_session = NULL
  invisible()
}
