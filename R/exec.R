#' Execute SQL in a DuckDB CLI session
#'
#' Sends SQL code to a running DuckDB CLI process and captures the output using
#' a sentinel-based detection mechanism.
#'
#' @param session A `processx::process` object (a running DuckDB CLI session).
#' @param code Character. SQL code to execute.
#' @param timeout Integer. Maximum milliseconds to wait for output. An error
#'   is thrown if the command does not complete within this time.
#'
#' @return A list with `stdout` and `stderr` character strings.
#'
#' @details
#' If the CLI process exits before producing output (for example because the
#' database file is locked by another process), an error is raised immediately
#' with the process's exit status and anything it wrote to stderr, rather than
#' waiting for `timeout` to elapse.
#'
#' @examplesIf nzchar(Sys.which("duckdb"))
#' s = duckknit_start_session("demo")
#' result = duckknit_exec(s, "SELECT 1 + 1 AS two;")
#' cat(result$stdout)
#' duckknit_kill_session("demo")
#' @export
duckknit_exec = function(session, code, timeout = 30000L) {
  if (!session$is_alive()) stop_session_exited(session)

  # Counter-based sentinel so execution never touches the global RNG state,
  # which would break reproducibility of documents that set a seed
  .state$exec_counter = .state$exec_counter + 1L
  sentinel = paste0(
    "___DUCKKNIT_", Sys.getpid(), "_", .state$exec_counter, "___"
  )

  session$read_output()
  session$read_error()

  input = paste0(code, "\n.print ", sentinel, "\n")
  tryCatch(
    session$write_input(input),
    error = function(e) {
      if (!session$is_alive()) stop_session_exited(session)
      stop(e)
    }
  )

  stdout_buf = ""
  poll_interval = 100L
  deadline = Sys.time() + timeout / 1000
  found = FALSE

  while (Sys.time() < deadline) {
    session$poll_io(poll_interval)
    chunk = session$read_output()
    if (nchar(chunk) > 0) {
      stdout_buf = paste0(stdout_buf, chunk)
    }
    if (grepl(sentinel, stdout_buf, fixed = TRUE)) {
      found = TRUE
      break
    }
    if (!session$is_alive()) {
      stdout_buf = paste0(stdout_buf, read_remaining(session$read_output))
      found = grepl(sentinel, stdout_buf, fixed = TRUE)
      if (!found) stop_session_exited(session)
      break
    }
  }

  if (!found) {
    stop("DuckDB command timed out after ", timeout, " ms.", call. = FALSE)
  }

  stderr_buf = session$read_error()

  stdout_lines = strsplit(stdout_buf, "\n", fixed = TRUE)[[1]]
  sentinel_idx = grep(sentinel, stdout_lines, fixed = TRUE)
  if (length(sentinel_idx) > 0) {
    stdout_lines = stdout_lines[seq_len(sentinel_idx[1] - 1L)]
  }

  # Drop trailing empty line if present
  if (length(stdout_lines) > 0 && stdout_lines[length(stdout_lines)] == "") {
    stdout_lines = stdout_lines[-length(stdout_lines)]
  }

  list(
    stdout = paste(stdout_lines, collapse = "\n"),
    stderr = stderr_buf
  )
}

stop_session_exited = function(session, context = "DuckDB CLI process is no longer running") {
  session$wait(timeout = 1000)
  status = session$get_exit_status()
  err = trimws(read_remaining(session$read_error))

  msg = context
  if (!is.null(status)) msg = paste0(msg, " (exit status ", status, ")")
  msg = if (nzchar(err)) paste0(msg, ":\n", err) else paste0(msg, ".")
  stop(msg, call. = FALSE)
}

# Pipes are closed once a process has been killed, so a read can error
read_remaining = function(reader) {
  tryCatch(reader(), error = function(e) "")
}
