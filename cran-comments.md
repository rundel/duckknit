# cran-comments

## R CMD check results

0 errors | 0 warnings | 0 notes

## Notes for CRAN

* This is a new submission.
* The package wraps the external DuckDB command-line interface, declared in
  SystemRequirements. The CLI is not required to install or load the package.
* All tests and examples that require the DuckDB CLI skip gracefully when it
  is not available (as on CRAN check machines). This has been verified by
  running R CMD check on systems without the CLI installed.
