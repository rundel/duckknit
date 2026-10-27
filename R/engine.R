#' Knitr engine for DuckDB CLI
#'
#' @param options A list of chunk options provided by knitr.
#'
#' @details
#' Supported chunk options:
#' \describe{
#'   \item{`db`}{Path to a DuckDB database file. Defaults to `":memory:"`.}
#'   \item{`session`}{Session name. If it already exists, it is reused.
#'     Otherwise a new session is created. When omitted, the last used session
#'     is reused (or a new one is created automatically).}
#'   \item{`mode`}{DuckDB output mode (e.g., `"table"`, `"markdown"`, `"csv"`).
#'     Sends `.mode <value>` before executing the chunk's SQL.}
#'   \item{`timeout`}{Maximum milliseconds to wait for output. Defaults to
#'     `30000`.}
#'   \item{`ansi`}{Controls handling of ANSI escape codes in output.
#'     `TRUE` preserves them, `FALSE` (default) strips them, and `"html"`
#'     converts them to HTML markup via [cli::ansi_html()].}
#'   \item{`prompt`}{If `TRUE`, the echoed code is shown as it would appear
#'     in an interactive CLI session: the first line of each command is
#'     prefixed with `"D "` and continuation lines are indented to match.
#'     In HTML output (including revealjs) the prompts are drawn with CSS so
#'     they are not picked up by copy buttons or text selection; this relies
#'     on the code being syntax highlighted, so `lang` defaults to `"sql"`.
#'     Use `prompt = "text"` to insert the prompts as plain text in every
#'     output format. The prompt and continuation strings can be changed with
#'     `options(duckknit.prompt = , duckknit.continue = )`. Defaults to
#'     `FALSE`, as for knitr's own `prompt` option.}
#' }
#'
#' @return A character string of formatted output for knitr.
#'
#' @examplesIf nzchar(Sys.which("duckdb"))
#' opts = c(
#'   knitr::opts_chunk$get(),
#'   list(code = "SELECT 42 AS answer;", engine = "duckdb", label = "demo")
#' )
#' cat(eng_duckdb(opts))
#' duckknit_kill_all_sessions()
#' @export
eng_duckdb = function(options) {
  mode = prompt_mode(options$prompt)
  # knitr's own prompt handling would add R's prompt to the echoed code as well
  options$prompt = FALSE
  if (mode == "css") options = add_prompt_css(options)

  if (!isTRUE(options$eval)) {
    return(echo_only(options, mode))
  }

  timeout = options$timeout %||% 30000L
  ansi = options$ansi %||% FALSE

  session_name = resolve_session(options$session, options$db)
  session = duckknit_get_session(session_name, options$db)
  .state$last_session = session_name

  if (!is.null(options$mode)) {
    duckknit_exec(session, paste0(".mode ", options$mode), timeout = timeout)
  }

  cmds = parse_commands(options$code)

  results = list()
  for (cmd in cmds) {
    cmd_code = paste(cmd, collapse = "\n")
    result = duckknit_exec(session, cmd_code, timeout = timeout)
    result$stdout = process_ansi(result$stdout, ansi)
    result$stderr = process_ansi(result$stderr, ansi)
    out = format_result(result, options)
    if (mode == "text") cmd = add_prompt(cmd)
    results = c(results, list(list(code = cmd, out = out)))
  }

  if (length(results) <= 1 || isTRUE(options$collapse)) {
    all_code = unlist(lapply(results, `[[`, "code"))
    if (is.null(all_code)) all_code = options$code
    all_out = paste(
      vapply(results, `[[`, character(1), "out"),
      collapse = "\n"
    )
    return(knitr::engine_output(options, code = all_code, out = all_out))
  }

  parts = vapply(results, function(r) {
    knitr::engine_output(options, code = r$code, out = r$out)
  }, character(1))
  paste(parts, collapse = "\n")
}

format_result = function(result, options) {
  if (nzchar(result$stderr)) {
    if (isTRUE(options$error)) {
      out = result$stderr
      if (nzchar(result$stdout)) {
        out = paste(result$stdout, result$stderr, sep = "\n")
      }
    } else {
      stop(result$stderr, call. = FALSE)
    }
  } else {
    out = result$stdout
  }
  out
}

echo_only = function(options, mode) {
  cmds = parse_commands(options$code)
  if (mode == "text") {
    code = unlist(lapply(cmds, add_prompt))
    return(knitr::engine_output(options, code = code, out = ""))
  }
  if (mode == "css" && length(cmds) > 1) {
    # one block per command so that each first line gets a prompt
    parts = vapply(cmds, function(cmd) {
      knitr::engine_output(options, code = cmd, out = "")
    }, character(1))
    return(paste(parts, collapse = "\n"))
  }
  knitr::engine_output(options, code = options$code, out = "")
}

prompt_mode = function(prompt) {
  if (identical(prompt, "text")) return("text")
  if (!isTRUE(prompt)) return("none")
  html = knitr::is_html_output(excludes = c("markdown", "gfm", "epub", "epub2"))
  if (html) "css" else "text"
}

prompt_strings = function() {
  list(
    prompt = getOption("duckknit.prompt", "D "),
    continue = getOption("duckknit.continue", "  ")
  )
}

add_prompt = function(code) {
  if (length(code) == 0) return(code)
  p = prompt_strings()
  paste0(c(p$prompt, rep(p$continue, length(code) - 1L)), code)
}

add_prompt_css = function(options) {
  options$class.source = c(options$class.source, "duckknit-prompt")
  if (is.null(options$lang)) options$lang = "sql"
  knitr::knit_meta_add(list(prompt_dependency()))
  options
}

prompt_dependency = function() {
  p = prompt_strings()
  vars = paste0(
    ":root{--duckknit-prompt:", css_string(p$prompt),
    ";--duckknit-continue:", css_string(p$continue), "}"
  )
  htmltools::htmlDependency(
    name = "duckknit-prompt",
    version = as.character(utils::packageVersion("duckknit")),
    src = system.file("css", package = "duckknit"),
    stylesheet = "duckknit-prompt.css",
    head = paste0("<style>", vars, "</style>")
  )
}

# Non-alphanumeric characters are hex escaped so that CSS minifiers (such as
# Quarto's when embedding resources) cannot collapse runs of spaces
css_string = function(x) {
  chars = strsplit(x, "")[[1]]
  esc = vapply(chars, function(ch) {
    if (grepl("[A-Za-z0-9]", ch)) return(ch)
    paste0("\\", format(as.hexmode(utf8ToInt(ch)), width = 6))
  }, character(1))
  paste0('"', paste(esc, collapse = ""), '"')
}

parse_commands = function(lines) {
  cmds = list()
  current = character(0)
  for (line in lines) {
    trimmed = trimws(line)
    if (nchar(trimmed) == 0 && length(current) == 0) next
    if (grepl("^\\.", trimmed)) {
      if (length(current) > 0) {
        cmds = c(cmds, list(current))
        current = character(0)
      }
      cmds = c(cmds, list(line))
    } else {
      current = c(current, line)
      if (grepl(";\\s*$", trimmed)) {
        cmds = c(cmds, list(current))
        current = character(0)
      }
    }
  }
  if (length(current) > 0) cmds = c(cmds, list(current))
  cmds
}

resolve_session = function(session, db) {
  if (!is.null(session)) {
    return(session)
  }

  if (!is.null(db)) {
    existing = find_session_by_db(db)
    if (!is.null(existing)) return(existing)
    return(next_session_name())
  }

  if (!is.null(.state$last_session)) {
    return(.state$last_session)
  }

  next_session_name()
}

strip_ansi = function(x) {
  gsub("\033\\[[0-9;]*m", "", x)
}

process_ansi = function(x, ansi) {
  if (identical(ansi, "html")) {
    if (!requireNamespace("cli", quietly = TRUE)) {
      stop("The cli package is required for ansi = \"html\".", call. = FALSE)
    }
    return(cli::ansi_html(x))
  }
  if (isTRUE(ansi)) {
    return(x)
  }
  strip_ansi(x)
}

`%||%` = function(x, y) {
  if (is.null(x)) y else x
}
