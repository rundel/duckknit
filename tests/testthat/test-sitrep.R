test_that("sitrep reports cli details when found", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = duckdb_sitrep()

  expect_type(result$path, "character")
  expect_true(file.exists(result$path))
  expect_true(grepl("^v[0-9]+\\.", result$version))
  expect_length(result$sessions, 0)
})

test_that("sitrep lists active sessions", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  duckknit_start_session("s1", ":memory:")
  duckknit_start_session("s2", ":memory:")

  result = duckdb_sitrep()

  expect_length(result$sessions, 2)
  expect_true("s1" %in% result$sessions)
  expect_true("s2" %in% result$sessions)
})

test_that("sitrep handles missing cli", {
  on.exit(options(duckknit.duckdb = NULL), add = TRUE)

  options(duckknit.duckdb = "/nonexistent/duckdb")

  result = duckdb_sitrep()

  expect_true(is.na(result$path))
  expect_true(is.na(result$version))
})

test_that("sitrep output includes key info", {
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  expect_output(duckdb_sitrep(), "Path:")
  expect_output(duckdb_sitrep(), "Version:")
  expect_output(duckdb_sitrep(), "Sessions:")
})
