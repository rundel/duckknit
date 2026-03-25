.onLoad = function(libname, pkgname) {
  knitr::knit_engines$set(duckdb = eng_duckdb)
}

.onUnload = function(libpath) {
  duckknit_kill_all_sessions()
}
