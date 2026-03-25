test_that("simple SELECT returns output", {
  s = duckknit_get_session("exec_basic", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = duckknit_exec(s, "SELECT 1 as val;")

  expect_true(nzchar(result$stdout))
  expect_true(grepl("val", result$stdout))
  expect_true(grepl("1", result$stdout))
  expect_equal(result$stderr, "")
})

test_that("state persists across exec calls", {
  s = duckknit_get_session("exec_persist", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_exec(s, "CREATE TABLE t (id INT);")
  duckknit_exec(s, "INSERT INTO t VALUES (10), (20);")
  result = duckknit_exec(s, "SELECT * FROM t ORDER BY id;")

  expect_true(grepl("10", result$stdout))
  expect_true(grepl("20", result$stdout))
})

test_that("non-output statements return empty stdout", {
  s = duckknit_get_session("exec_noout", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = duckknit_exec(s, "CREATE TABLE t2 (x INT);")

  expect_equal(result$stdout, "")
  expect_equal(result$stderr, "")
})

test_that("syntax errors appear in stderr", {
  s = duckknit_get_session("exec_err", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = duckknit_exec(s, "SELCT bad;")

  expect_true(nzchar(result$stderr))
  expect_true(grepl("Error", result$stderr))
})

test_that("errors do not prevent subsequent commands", {
  s = duckknit_get_session("exec_recover", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_exec(s, "SELCT bad;")
  result = duckknit_exec(s, "SELECT 42 as answer;")

  expect_true(grepl("42", result$stdout))
})

test_that("multi-statement code works", {
  s = duckknit_get_session("exec_multi", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = duckknit_exec(s, "SELECT 1 as a;\nSELECT 2 as b;")

  expect_true(grepl("1", result$stdout))
  expect_true(grepl("2", result$stdout))
})

test_that("exec on dead session errors", {
  s = duckknit_start_session("exec_dead", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  s$kill()
  Sys.sleep(0.1)

  expect_error(
    duckknit_exec(s, "SELECT 1;"),
    "no longer running"
  )
})

test_that("sentinel is stripped from output", {
  s = duckknit_get_session("exec_sentinel", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = duckknit_exec(s, "SELECT 1 as val;")

  expect_false(grepl("DUCKKNIT", result$stdout))
})

test_that(".mode commands work within exec", {
  s = duckknit_get_session("exec_mode", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_exec(s, "CREATE TABLE m (id INT, name TEXT);")
  duckknit_exec(s, "INSERT INTO m VALUES (1, 'alice');")

  result = duckknit_exec(s, ".mode csv\nSELECT * FROM m;")

  expect_true(grepl("id,name", result$stdout))
  expect_true(grepl("1,alice", result$stdout))
})

test_that("mode persists across exec calls", {
  s = duckknit_get_session("exec_mode_persist", ":memory:")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_exec(s, "CREATE TABLE mp (x INT);")
  duckknit_exec(s, "INSERT INTO mp VALUES (1);")

  duckknit_exec(s, ".mode csv")
  result = duckknit_exec(s, "SELECT * FROM mp;")

  expect_true(grepl("x", result$stdout))
  expect_true(grepl("1", result$stdout))
  expect_false(grepl("\u250c", result$stdout))
})

test_that("file-backed database persists data", {
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  s = duckknit_get_session("exec_file", tmp)
  duckknit_exec(s, "CREATE TABLE ft (v INT);")
  duckknit_exec(s, "INSERT INTO ft VALUES (99);")
  duckknit_kill_session("exec_file")

  s2 = duckknit_get_session("exec_file2", tmp)
  result = duckknit_exec(s2, "SELECT * FROM ft;")

  expect_true(grepl("99", result$stdout))
})
