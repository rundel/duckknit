test_that("duckknit_start_session creates a live process", {
  s = duckknit_start_session("test_start", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  expect_true(s$is_alive())
  expect_true("test_start" %in% ls(.sessions))
})

test_that("duckknit_get_session returns existing session", {
  s1 = duckknit_get_session("test_get", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  s2 = duckknit_get_session("test_get", ":memory:")
  expect_identical(s1$get_pid(), s2$get_pid())
})

test_that("duckknit_get_session restarts dead session", {
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
  duckknit_start_session("a", ":memory:")
  duckknit_start_session("b", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  expect_length(ls(.sessions), 2)

  duckknit_kill_all_sessions()
  expect_length(ls(.sessions), 0)
})

test_that("concurrent file db sessions are rejected", {
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
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  s1 = duckknit_start_session("mem1", ":memory:")
  s2 = duckknit_start_session("mem2", ":memory:")

  expect_true(s1$is_alive())
  expect_true(s2$is_alive())
  expect_false(identical(s1$get_pid(), s2$get_pid()))
})

test_that("db tracking is cleaned up on session kill", {
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

test_that("find_duckdb respects duckknit.duckdb option", {
  on.exit(options(duckknit.duckdb = NULL), add = TRUE)

  options(duckknit.duckdb = "/nonexistent/path/duckdb")
  expect_error(
    duckknit_start_session("opt_test", ":memory:"),
    "DuckDB binary not found"
  )
})

test_that("kill_all resets counter and last_session", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_start_session("s1", ":memory:")
  .state$last_session = "s1"
  .state$counter = 5L

  duckknit_kill_all_sessions()

  expect_equal(.state$counter, 0L)
  expect_null(.state$last_session)
})

test_that("kill_session clears last_session if it was the killed session", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_start_session("s1", ":memory:")
  .state$last_session = "s1"

  duckknit_kill_session("s1")
  expect_null(.state$last_session)
})

test_that("kill_session preserves last_session if different session killed", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_start_session("s1", ":memory:")
  duckknit_start_session("s2", ":memory:")
  .state$last_session = "s1"

  duckknit_kill_session("s2")
  expect_equal(.state$last_session, "s1")
})

test_that("find_session_by_db finds existing session for file db", {
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
