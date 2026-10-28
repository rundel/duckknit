test_that("sitrep reports cli details when found", {
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = duckknit_sitrep()

  expect_type(result$path, "character")
  expect_true(file.exists(result$path))
  expect_true(grepl("^v[0-9]+\\.", result$version))
  expect_length(result$sessions, 0)
})

test_that("sitrep lists active sessions", {
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_start_session("s1", ":memory:")
  duckknit_start_session("s2", ":memory:")

  result = duckknit_sitrep()

  expect_length(result$sessions, 2)
  expect_true("s1" %in% result$sessions)
  expect_true("s2" %in% result$sessions)
})

test_that("sitrep handles missing cli", {
  on.exit(options(duckknit.duckdb = NULL), add = TRUE)

  options(duckknit.duckdb = "/nonexistent/duckdb")

  result = duckknit_sitrep()

  expect_true(is.na(result$path))
  expect_true(is.na(result$version))
})

test_that("list_sessions returns all sessions when last_session is NULL", {
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_start_session("ls1", ":memory:")
  duckknit_start_session("ls2", ":memory:")

  result = duckknit_list_sessions()

  expect_equal(nrow(result), 2)
  expect_false(any(result$active))
})

test_that("list_sessions marks last session active", {
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_start_session("ls1", ":memory:")
  duckknit_start_session("ls2", ":memory:")
  .state$last_session = "ls2"

  result = duckknit_list_sessions()

  expect_equal(result$active, result$session == "ls2")
})

test_that("sitrep output includes key info", {
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  expect_output(duckknit_sitrep(), "Path:")
  expect_output(duckknit_sitrep(), "Version:")
  expect_output(duckknit_sitrep(), "Sessions:")
})

test_that("sitrep and list_sessions report readonly sessions", {
  skip_if_no_duckdb()
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  duckknit_exec(duckknit_start_session("w", tmp), "SELECT 1;")
  duckknit_kill_session("w")
  duckknit_start_session("ro", tmp, readonly = TRUE)
  duckknit_start_session("mem", ":memory:")

  expect_output(duckknit_sitrep(), "ro \\(running, read-only\\)")
  sessions = duckknit_list_sessions()
  expect_equal(sessions$readonly[sessions$session == "ro"], TRUE)
  expect_equal(sessions$readonly[sessions$session == "mem"], FALSE)
  expect_named(duckknit_list_sessions(), c("session", "status", "db", "readonly", "active"))
})
