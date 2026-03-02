#!/usr/bin/env Rscript

header_path <- "RcppTskit/inst/include/RcppTskit_public.hpp"
source_path <- "RcppTskit/src/RcppTskit.cpp"

extract_options_defaults <- function(path, signature_pattern) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  matches <- gregexpr(signature_pattern, text, perl = TRUE)[[1]]

  if (identical(matches, -1L)) {
    return(structure(integer(), names = character()))
  }

  signatures <- regmatches(text, list(matches))[[1]]
  defaults <- list()

  capture_first_group <- function(string, pattern) {
    match <- regexpr(pattern, string, perl = TRUE)
    if (match[[1]] == -1L) {
      return(NA_character_)
    }
    starts <- attr(match, "capture.start")
    lengths <- attr(match, "capture.length")
    if (is.null(starts) || is.null(lengths) || starts[1, 1] == -1L) {
      return(NA_character_)
    }
    substr(string, starts[1, 1], starts[1, 1] + lengths[1, 1] - 1L)
  }

  for (signature in signatures) {
    if (!grepl("\\boptions\\s*=", signature, perl = TRUE)) {
      next
    }

    name <- capture_first_group(
      signature,
      "^[[:space:]]*(?:SEXP|void)\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\("
    )
    default_text <- capture_first_group(
      signature,
      "\\boptions\\s*=\\s*([0-9]+)\\b"
    )
    if (is.na(name) || is.na(default_text)) {
      next
    }
    default <- as.integer(default_text)
    defaults[[name]] <- default
  }

  if (length(defaults) == 0L) {
    return(structure(integer(), names = character()))
  }

  values <- unlist(defaults, use.names = TRUE)
  storage.mode(values) <- "integer"
  values
}

stop_with <- function(lines) {
  cat(paste0(lines, collapse = "\n"), "\n")
  quit(save = "no", status = 1L)
}

if (!file.exists(header_path)) {
  stop_with(c("ERROR: Missing header file:", paste0("  - ", header_path)))
}
if (!file.exists(source_path)) {
  stop_with(c("ERROR: Missing source file:", paste0("  - ", source_path)))
}

header_defaults <- extract_options_defaults(
  header_path,
  "(?:SEXP|void)\\s+[A-Za-z_][A-Za-z0-9_]*\\s*\\([^;{}]*?\\)\\s*;"
)
source_defaults <- extract_options_defaults(
  source_path,
  "(?:SEXP|void)\\s+[A-Za-z_][A-Za-z0-9_]*\\s*\\([^;{}]*?\\)\\s*\\{"
)

if (length(header_defaults) == 0L || length(source_defaults) == 0L) {
  stop_with(c(
    "ERROR: Could not parse function defaults for `options`.",
    "       Update check_sync_between_cpp_and_hpp.R if function signatures changed."
  ))
}

missing_in_header <- setdiff(names(source_defaults), names(header_defaults))
missing_in_source <- setdiff(names(header_defaults), names(source_defaults))
common <- intersect(names(header_defaults), names(source_defaults))
mismatched <- common[header_defaults[common] != source_defaults[common]]

problems <- character()

if (length(missing_in_header) > 0L) {
  problems <- c(
    problems,
    "ERROR: Functions with `options` defaults found in .cpp but missing in .hpp:",
    paste0("  - ", sort(missing_in_header))
  )
}
if (length(missing_in_source) > 0L) {
  problems <- c(
    problems,
    "ERROR: Functions with `options` defaults found in .hpp but missing in .cpp:",
    paste0("  - ", sort(missing_in_source))
  )
}
if (length(mismatched) > 0L) {
  problems <- c(
    problems,
    "ERROR: Mismatched `options` defaults between .hpp and .cpp:"
  )
  for (name in sort(mismatched)) {
    problems <- c(
      problems,
      sprintf(
        "  - %s: header=%d, source=%d",
        name,
        header_defaults[[name]],
        source_defaults[[name]]
      )
    )
  }
}

if (length(problems) > 0L) {
  stop_with(c(
    problems,
    "",
    "Keep defaults in sync between:",
    paste0("  - ", header_path),
    paste0("  - ", source_path)
  ))
}

cat(
  sprintf(
    "OK: %d function default(s) for `options` are in sync between .hpp and .cpp.\n",
    length(common)
  )
)
