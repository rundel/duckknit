duckdb_variant = function() {
  ver = trimws(processx::run(duckknit:::find_duckdb(), "--version")$stdout)
  version = regmatches(ver, regexpr("^v\\d+\\.\\d+", ver))
  os = if (.Platform$OS.type == "windows") "windows" else "unix"
  paste(version, os, sep = "-")
}
