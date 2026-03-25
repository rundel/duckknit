#' Execute SQL in a DuckDB CLI session
#'
#' Sends SQL code to a running DuckDB CLI process and captures the output using
#' a sentinel-based detection mechanism.
#'
#' @param session A `processx::process` object (a running DuckDB CLI session).
#' @param code Character. SQL code to execute.
#' @param timeout Integer. Maximum milliseconds to wait for output.
#'
#' @return A list with `stdout` and `stderr` character strings.
#' @export
duckknit_exec = function(session, code, timeout = 30000L) {
  if (!session$is_alive()) {
    stop("DuckDB session is no longer running.", call. = FALSE)
  }

  sentinel = paste0(
    "___DUCKKNIT_", as.hexmode(sample.int(.Machine$integer.max, 1)), "___"
  )

  session$read_output()
  session$read_error()

  input = paste0(code, "\n.print ", sentinel, "\n")
  session$write_input(input)

  stdout_buf = ""
  elapsed = 0L
  poll_interval = 100L

  while (elapsed < timeout) {
    session$poll_io(poll_interval)
    chunk = session$read_output()
    if (nchar(chunk) > 0) {
      stdout_buf = paste0(stdout_buf, chunk)
    }
    if (grepl(sentinel, stdout_buf, fixed = TRUE)) break
    elapsed = elapsed + poll_interval
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
