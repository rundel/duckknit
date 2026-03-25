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

test_that("Rmd rendering", {
  skip_if_not_installed("rmarkdown")
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = render_rmd("test.Rmd")
  expect_snapshot(cat(result))
})

test_that("qmd rendering", {
  skip_if_not_installed("quarto")
  skip_if_not_installed("duckknit")
  skip_if(
    system2("quarto", "--version", stdout = TRUE, stderr = TRUE) |> length() == 0,
    "quarto CLI not available"
  )
  on.exit(duckknit_kill_all_sessions(), add = TRUE)

  result = render_qmd("test.qmd")
  expect_snapshot(cat(result))
})
