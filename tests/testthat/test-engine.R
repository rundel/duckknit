duckdb_variant = function() {
  ver = processx::run(duckknit:::find_duckdb(), "--version")$stdout
  minor = as.integer(sub("^v\\d+\\.(\\d+)\\..*", "\\1", trimws(ver)))
  version = if (minor <= 4) "v1.4" else "v1.5"
  os = if (.Platform$OS.type == "windows") "windows" else "unix"
  paste(version, os, sep = "-")
}

make_options = function(code, ...) {
  opts = list(
    code = code,
    eval = TRUE,
    echo = TRUE,
    results = "markup",
    collapse = FALSE,
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

  expect_snapshot(cat(result), variant = duckdb_variant())
})

test_that("ansi=TRUE preserves ANSI codes in .tables output", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("CREATE TABLE ansi_t (id INT, name TEXT);"))
  result = eng_duckdb(make_options(".tables", ansi = TRUE))

  expect_snapshot(cat(result), variant = duckdb_variant())
})

test_that("ansi='html' converts ANSI to HTML in .tables output", {
  skip_if_not_installed("cli")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("CREATE TABLE ansi_t (id INT, name TEXT);"))
  result = eng_duckdb(make_options(".tables", ansi = "html"))

  expect_snapshot(cat(result), variant = duckdb_variant())
})

test_that("counter resets after kill_all", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  eng_duckdb(make_options("SELECT 1;"))
  expect_true("session-1" %in% ls(.sessions))

  duckknit_kill_all_sessions()

  eng_duckdb(make_options("SELECT 2;"))
  expect_true("session-1" %in% ls(.sessions))
})

# parse_commands tests

test_that("parse_commands: single SQL", {
  expect_equal(
    parse_commands("SELECT 1;"),
    list("SELECT 1;")
  )
})

test_that("parse_commands: multiple SQL", {
  expect_equal(
    parse_commands(c("SELECT 1;", "SELECT 2;")),
    list("SELECT 1;", "SELECT 2;")
  )
})

test_that("parse_commands: multi-line SQL", {
  expect_equal(
    parse_commands(c("SELECT", "  *", "FROM t;")),
    list(c("SELECT", "  *", "FROM t;"))
  )
})

test_that("parse_commands: single dot-command", {
  expect_equal(
    parse_commands(".tables"),
    list(".tables")
  )
})

test_that("parse_commands: multiple dot-commands", {
  expect_equal(
    parse_commands(c(".mode csv", ".tables")),
    list(".mode csv", ".tables")
  )
})

test_that("parse_commands: mixed dot and SQL", {
  expect_equal(
    parse_commands(c(".mode csv", "SELECT 1;", ".tables")),
    list(".mode csv", "SELECT 1;", ".tables")
  )
})

test_that("parse_commands: blank lines between commands", {
  expect_equal(
    parse_commands(c("SELECT 1;", "", "SELECT 2;")),
    list("SELECT 1;", "SELECT 2;")
  )
})

test_that("parse_commands: trailing SQL without semicolon", {
  expect_equal(
    parse_commands(c("SELECT 1")),
    list("SELECT 1")
  )
})

test_that("parse_commands: dot-command flushes incomplete SQL", {
  expect_equal(
    parse_commands(c("SELECT", ".tables")),
    list("SELECT", ".tables")
  )
})

# interleaved output tests

test_that("multiple commands produce interleaved output", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  opts = make_options(c("SELECT 1 as a;", "SELECT 2 as b;"))
  result = eng_duckdb(opts)

  a_pos = regexpr("SELECT 1 as a;", result)
  a_out_pos = regexpr("\\b1\\b", substring(result, a_pos + 14))
  b_pos = regexpr("SELECT 2 as b;", result)
  expect_true(a_pos < b_pos)
  expect_true(grepl("a", result))
  expect_true(grepl("b", result))
})

test_that("collapse = TRUE batches all code then output", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  single = eng_duckdb(make_options(c("SELECT 1 as a;", "SELECT 2 as b;"), collapse = TRUE))
  multi = eng_duckdb(make_options(c("SELECT 1 as a;", "SELECT 2 as b;"), collapse = FALSE))

  expect_false(identical(single, multi))
})

test_that("error stops at first failing command", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  opts = make_options(c("SELECT 1;", "SELCT bad;", "SELECT 3;"))
  expect_error(eng_duckdb(opts), "Error")
})

test_that("error = TRUE continues after failing command", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  opts = make_options(c("SELECT 1 as a;", "SELCT bad;", "SELECT 3 as c;"), error = TRUE)
  result = eng_duckdb(opts)

  expect_true(grepl("a", result))
  expect_true(grepl("Error", result))
  expect_true(grepl("c", result))
})
