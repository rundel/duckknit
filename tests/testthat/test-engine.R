make_options = function(code, ...) {
  opts = list(
    code = code,
    eval = TRUE,
    echo = TRUE,
    results = "markup",
    include = TRUE,
    error = FALSE,
    label = "test-chunk",
    engine = "duckdb"
  )
  extra = list(...)
  opts[names(extra)] = extra
  opts
}

test_that("engine returns output for SELECT", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  opts = make_options("SELECT 1 as val;")
  result = eng_duckdb(opts)

  expect_true(grepl("val", result))
  expect_true(grepl("1", result))
})

test_that("engine respects eval = FALSE", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  opts = make_options("SELECT 1;", eval = FALSE)
  result = eng_duckdb(opts)

  expect_true(is.character(result))
  expect_false(grepl("DUCKKNIT", result))
})

test_that("engine auto-creates session-1 for first chunk", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("SELECT 1;"))

  expect_true("session-1" %in% ls(.sessions))
  expect_equal(.state$last_session, "session-1")
})

test_that("engine reuses last session when no options given", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("CREATE TABLE lt (id INT);"))
  eng_duckdb(make_options("INSERT INTO lt VALUES (5);"))
  result = eng_duckdb(make_options("SELECT * FROM lt;"))

  expect_true(grepl("5", result))
  expect_length(ls(.sessions), 1)
})

test_that("engine db option creates new auto-named session", {
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  eng_duckdb(make_options("SELECT 1;"))
  eng_duckdb(make_options("CREATE TABLE db_t (v TEXT);", db = tmp))

  expect_true("session-1" %in% ls(.sessions))
  expect_true("session-2" %in% ls(.sessions))
  expect_equal(.state$last_session, "session-2")
})

test_that("engine db option reuses existing session for same db", {
  tmp = tempfile(fileext = ".duckdb")
  on.exit({
    duckknit_kill_all_sessions()
    unlink(tmp)
  }, add = TRUE)

  eng_duckdb(make_options("CREATE TABLE db_t (v TEXT);", db = tmp))
  eng_duckdb(make_options("INSERT INTO db_t VALUES ('hello');", db = tmp))
  result = eng_duckdb(make_options("SELECT * FROM db_t;", db = tmp))

  expect_true(grepl("hello", result))
  expect_length(ls(.sessions), 1)
})

test_that("engine session option creates named session", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("CREATE TABLE st (x INT);", session = "custom"))
  expect_true("custom" %in% ls(.sessions))

  result = eng_duckdb(make_options("SELECT * FROM st;", session = "custom"))
  expect_true(grepl("x", result))
})

test_that("engine session option sets last session", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("SELECT 1;"))
  expect_equal(.state$last_session, "session-1")

  eng_duckdb(make_options("SELECT 2;", session = "other"))
  expect_equal(.state$last_session, "other")

  eng_duckdb(make_options("SELECT 3;"))
  expect_equal(.state$last_session, "other")
})

test_that("engine mode option changes output format", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("CREATE TABLE mode_t (a INT);"))
  eng_duckdb(make_options("INSERT INTO mode_t VALUES (1);"))
  result = eng_duckdb(make_options("SELECT * FROM mode_t;", mode = "csv"))

  expect_true(grepl("a", result))
  expect_true(grepl("1", result))
})

test_that("engine stops on error by default", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  expect_error(
    eng_duckdb(make_options("SELCT bad;")),
    "Error"
  )
})

test_that("engine displays error when error = TRUE", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = eng_duckdb(make_options("SELCT bad;", error = TRUE))

  expect_true(grepl("Error", result))
})

test_that("engine handles multi-line code vector", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  opts = make_options(c("CREATE TABLE ml (id INT);", "INSERT INTO ml VALUES (7);"))
  eng_duckdb(opts)

  result = eng_duckdb(make_options("SELECT * FROM ml;"))
  expect_true(grepl("7", result))
})

test_that("engine does not echo mode command in displayed code", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  opts = make_options("SELECT 1 as x;", mode = "csv")
  result = eng_duckdb(opts)

  expect_false(grepl("\\.mode csv", result))
})

test_that("ansi=FALSE strips ANSI codes from .tables output", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("CREATE TABLE ansi_t (id INT, name TEXT);"))
  result = eng_duckdb(make_options(".tables", ansi = FALSE))

  expect_snapshot(cat(result))
})

test_that("ansi=TRUE preserves ANSI codes in .tables output", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("CREATE TABLE ansi_t (id INT, name TEXT);"))
  result = eng_duckdb(make_options(".tables", ansi = TRUE))

  expect_snapshot(cat(result))
})

test_that("ansi='html' converts ANSI to HTML in .tables output", {
  skip_if_not_installed("cli")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("CREATE TABLE ansi_t (id INT, name TEXT);"))
  result = eng_duckdb(make_options(".tables", ansi = "html"))

  expect_snapshot(cat(result))
})

test_that("counter resets after kill_all", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("SELECT 1;"))
  expect_true("session-1" %in% ls(.sessions))

  duckknit_kill_all_sessions()

  eng_duckdb(make_options("SELECT 2;"))
  expect_true("session-1" %in% ls(.sessions))
})
