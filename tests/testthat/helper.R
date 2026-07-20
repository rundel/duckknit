has_duckdb = function() {
  tryCatch(
    nzchar(duckknit:::find_duckdb()),
    error = function(e) FALSE
  )
}

skip_if_no_duckdb = function() {
  testthat::skip_if_not(has_duckdb(), "DuckDB CLI not available")
}

duckdb_variant = function() {
  ver = trimws(processx::run(duckknit:::find_duckdb(), "--version")$stdout)
  version = regmatches(ver, regexpr("^v\\d+\\.\\d+", ver))
  os = if (.Platform$OS.type == "windows") "windows" else "unix"
  paste(version, os, sep = "-")
}
