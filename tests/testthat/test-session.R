test_that("duckknit_start_session creates a live process", {
  skip_if_no_duckdb()
  s = duckknit_start_session("test_start", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  expect_true(s$is_alive())
  expect_true("test_start" %in% ls(.sessions))
})

test_that("duckknit_get_session returns existing session", {
  skip_if_no_duckdb()
  s1 = duckknit_get_session("test_get", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  s2 = duckknit_get_session("test_get", ":memory:")
  expect_identical(s1$get_pid(), s2$get_pid())
})

test_that("duckknit_get_session restarts dead session", {
  skip_if_no_duckdb()
  s1 = duckknit_get_session("test_restart", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  pid1 = s1$get_pid()
  s1$kill()
  Sys.sleep(0.1)

  s2 = duckknit_get_session("test_restart", ":memory:")
  expect_true(s2$is_alive())
  expect_false(identical(pid1, s2$get_pid()))
})

test_that("duckknit_kill_session removes session from registry", {
  skip_if_no_duckdb()
  duckknit_start_session("test_kill", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  expect_true("test_kill" %in% ls(.sessions))

  duckknit_kill_session("test_kill")
  expect_false("test_kill" %in% ls(.sessions))
})

test_that("duckknit_kill_session on nonexistent session is a no-op", {
  expect_no_error(duckknit_kill_session("does_not_exist"))
})

test_that("duckknit_kill_all_sessions clears all sessions", {
  skip_if_no_duckdb()
  duckknit_start_session("a", ":memory:")
  duckknit_start_session("b", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  expect_length(ls(.sessions), 2)

  duckknit_kill_all_sessions()
  expect_length(ls(.sessions), 0)
})

test_that("concurrent file db sessions are rejected", {
  skip_if_no_duckdb()
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  duckknit_start_session("first", tmp)

  expect_error(
    duckknit_start_session("second", tmp),
    "already open in session"
  )
})

test_that("file db can be reused after killing prior session", {
  skip_if_no_duckdb()
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  duckknit_start_session("s1", tmp)
  duckknit_kill_session("s1")

  s2 = duckknit_start_session("s2", tmp)
  expect_true(s2$is_alive())
})

test_that("multiple in-memory sessions are allowed", {
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  s1 = duckknit_start_session("mem1", ":memory:")
  s2 = duckknit_start_session("mem2", ":memory:")

  expect_true(s1$is_alive())
  expect_true(s2$is_alive())
  expect_false(identical(s1$get_pid(), s2$get_pid()))
})

test_that("db tracking is cleaned up on session kill", {
  skip_if_no_duckdb()
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  duckknit_start_session("tracked", tmp)
  expect_true("tracked" %in% ls(.session_dbs))

  duckknit_kill_session("tracked")
  expect_false("tracked" %in% ls(.session_dbs))
})

test_that("get_session errors when db conflicts with existing session", {
  skip_if_no_duckdb()
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  duckknit_get_session("conflict_mem", ":memory:")
  expect_error(
    duckknit_get_session("conflict_mem", tmp),
    "already connected"
  )
  expect_no_error(duckknit_get_session("conflict_mem"))
  expect_no_error(duckknit_get_session("conflict_mem", ":memory:"))

  duckknit_get_session("conflict_file", tmp)
  expect_error(
    duckknit_get_session("conflict_file", ":memory:"),
    "already connected"
  )
  expect_no_error(duckknit_get_session("conflict_file", tmp))
})

test_that("find_duckdb respects duckknit.duckdb option", {
  on.exit(options(duckknit.duckdb = NULL), add = TRUE)

  options(duckknit.duckdb = "/nonexistent/path/duckdb")
  expect_error(
    duckknit_start_session("opt_test", ":memory:"),
    "DuckDB binary not found"
  )
})

test_that("kill_all resets counter and last_session", {
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_start_session("s1", ":memory:")
  .state$last_session = "s1"
  .state$counter = 5L

  duckknit_kill_all_sessions()

  expect_equal(.state$counter, 0L)
  expect_null(.state$last_session)
})

test_that("kill_session clears last_session if it was the killed session", {
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_start_session("s1", ":memory:")
  .state$last_session = "s1"

  duckknit_kill_session("s1")
  expect_null(.state$last_session)
})

test_that("kill_session preserves last_session if different session killed", {
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_start_session("s1", ":memory:")
  duckknit_start_session("s2", ":memory:")
  .state$last_session = "s1"

  duckknit_kill_session("s2")
  expect_equal(.state$last_session, "s1")
})

test_that("find_session_by_db finds existing session for file db", {
  skip_if_no_duckdb()
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  duckknit_start_session("mydb", tmp)

  result = find_session_by_db(tmp)
  expect_equal(result, "mydb")
})

test_that("find_session_by_db returns NULL for memory and unknown dbs", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  expect_null(find_session_by_db(":memory:"))
  expect_null(find_session_by_db("/no/such/file.duckdb"))
})

test_that("agent_mode_env disables agent mode by default", {
  withr::local_options(duckknit.agent_mode = NULL)
  expect_equal(agent_mode_env(), c("current", DUCKDB_AGENT_MODE = "0"))

  withr::local_options(duckknit.agent_mode = TRUE)
  expect_equal(agent_mode_env(), c("current", DUCKDB_AGENT_MODE = "1"))

  withr::local_options(duckknit.agent_mode = "yes")
  expect_error(agent_mode_env(), "must be TRUE or FALSE")
})

test_that("sessions ignore agent environment variables by default", {
  skip_if_no_duckdb()
  withr::local_envvar(AI_AGENT = "test")
  s = duckknit_start_session("agent_default", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = duckknit_exec(s, "SELECT 1 AS x;")
  expect_equal(result$stderr, "")
  expect_false(grepl("| x:INTEGER |", result$stdout, fixed = TRUE))
})

test_that("duckknit.agent_mode = TRUE enables agent mode", {
  skip_if_no_duckdb()
  skip_if_duckdb_older_than("2.0.0")
  withr::local_options(duckknit.agent_mode = TRUE)
  s = duckknit_start_session("agent_on", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = duckknit_exec(s, "SELECT 1 AS x;")
  expect_match(result$stdout, "| x:INTEGER |", fixed = TRUE)
})

test_that("starting a session on a locked database file errors immediately", {
  skip_if_no_duckdb()
  db = withr::local_tempfile(fileext = ".duckdb")

  holder = processx::process$new(
    find_duckdb(), db,
    stdin = "|", stdout = "|", stderr = "|",
    env = agent_mode_env(), cleanup = TRUE
  )
  withr::defer(holder$kill())
  holder$write_input("CREATE TABLE t (x INTEGER);\n.print READY\n")
  out = ""
  deadline = Sys.time() + 10
  while (!grepl("READY", out, fixed = TRUE) && Sys.time() < deadline) {
    holder$poll_io(100)
    out = paste0(out, holder$read_output())
  }
  expect_true(grepl("READY", out, fixed = TRUE))

  on.exit(duckknit_kill_all_sessions(), add = TRUE)
  start = Sys.time()
  expect_error(
    {
      s = duckknit_start_session("locked", db)
      duckknit_exec(s, "SELECT 1;")
    },
    "lock"
  )
  expect_lt(as.numeric(Sys.time() - start, units = "secs"), 5)
  expect_false("locked" %in% ls(.sessions))
})

test_that("readonly sessions can share a database file", {
  skip_if_no_duckdb()
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  w = duckknit_start_session("writer", tmp)
  duckknit_exec(w, "CREATE TABLE t AS SELECT 42 AS x;")
  duckknit_kill_session("writer")

  r1 = duckknit_start_session("ro1", tmp, readonly = TRUE)
  r2 = duckknit_start_session("ro2", tmp, readonly = TRUE)
  expect_true(r1$is_alive())
  expect_true(r2$is_alive())
  expect_match(duckknit_exec(r2, "SELECT x FROM t;")$stdout, "42")

  expect_error(
    duckknit_start_session("rw", tmp),
    "already open in session"
  )

  result = duckknit_exec(r1, "CREATE TABLE y (a INTEGER);")
  expect_match(result$stderr, "read-only")
})

test_that("readonly session cannot be added to a read/write database", {
  skip_if_no_duckdb()
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  duckknit_start_session("rw", tmp)

  expect_error(
    duckknit_start_session("ro", tmp, readonly = TRUE),
    "already open in session"
  )
})

test_that("get_session errors when readonly conflicts with existing session", {
  skip_if_no_duckdb()
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  duckknit_start_session("mode", tmp)

  expect_error(
    duckknit_get_session("mode", tmp, readonly = TRUE),
    "already open read/write"
  )
  expect_no_error(duckknit_get_session("mode", tmp, readonly = FALSE))
  expect_no_error(duckknit_get_session("mode", tmp))
})

test_that("readonly tracking is cleaned up on session kill", {
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_start_session("ro_track", ":memory:")
  expect_true("ro_track" %in% ls(.session_readonly))
  expect_false(session_readonly("ro_track"))

  duckknit_kill_session("ro_track")
  expect_false("ro_track" %in% ls(.session_readonly))
})

test_that("readonly must be a single logical", {
  expect_error(duckknit_start_session("bad", ":memory:", readonly = "yes"), "TRUE or FALSE")
  expect_error(duckknit_get_session("bad", readonly = NA), "TRUE or FALSE")
})

test_that("readonly in-memory session errors at startup", {
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)
  expect_error(duckknit_start_session("romem", ":memory:", readonly = TRUE), "read-only")
})
