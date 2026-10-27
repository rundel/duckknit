render_rmd = function(filename) {
  src = testthat::test_path("fixtures", filename)
  tmp_dir = tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  tmp_src = file.path(tmp_dir, filename)
  file.copy(src, tmp_src)

  out_file = rmarkdown::render(tmp_src, quiet = TRUE)
  paste(readLines(out_file), collapse = "\n")
}

render_qmd = function(filename) {
  src = testthat::test_path("fixtures", filename)
  tmp_dir = tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  tmp_src = file.path(tmp_dir, filename)
  file.copy(src, tmp_src)

  quarto::quarto_render(tmp_src, quiet = TRUE)
  out_file = file.path(tmp_dir, sub("\\.qmd$", ".md", filename))
  paste(readLines(out_file), collapse = "\n")
}

render_html = function(filename) {
  src = testthat::test_path("fixtures", filename)
  tmp_dir = tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  tmp_src = file.path(tmp_dir, filename)
  file.copy(src, tmp_src)

  quarto::quarto_render(tmp_src, quiet = TRUE)
  out_file = file.path(tmp_dir, sub("\\.qmd$", ".html", filename))
  paste(readLines(out_file, warn = FALSE), collapse = "\n")
}

test_that("Rmd rendering", {
  skip_if_not_installed("rmarkdown")
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = render_rmd("test.Rmd")
  expect_snapshot(cat(result), variant = duckdb_variant())
})

test_that("qmd rendering", {
  skip_if_not_installed("quarto")
  skip_if_not_installed("duckknit")
  skip_if(is.null(quarto::quarto_path()), "quarto CLI not available")
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = render_qmd("test.qmd")
  expect_snapshot(cat(result), variant = duckdb_variant())
})

test_that("html rendering draws prompts with CSS", {
  skip_if_not_installed("quarto")
  skip_if_not_installed("duckknit")
  skip_if(is.null(quarto::quarto_path()), "quarto CLI not available")
  skip_if_no_duckdb()
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = render_html("test-html.qmd")

  expect_true(grepl("duckknit-prompt.css", result, fixed = TRUE))
  expect_true(grepl('--duckknit-prompt:"D\\000020"', result, fixed = TRUE))
  expect_equal(lengths(regmatches(result, gregexpr('class="sourceCode sql duckknit-prompt', result))), 3)
  expect_false(grepl("D SELECT", result, fixed = TRUE))
})
