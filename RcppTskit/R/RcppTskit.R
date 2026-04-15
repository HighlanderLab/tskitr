# A range of functions

#' @title Get the reticulate \code{tskit} Python module
#' @description This function imports the reticulate Python \code{tskit} module.
#'   If it is not yet installed, it attempts to install it first.
#' @param object_name character name of the object holding the reticulate
#'   \code{tskit} module. If this object exists in the global R environment and
#'   is a reticulate Python module, it is returned. Otherwise, the function
#'   attempts to install and import \code{tskit} before returning it.
#' @param force logical; force installation and/or import before returning the
#'   reticulate Python module.
#' @param object reticulate Python module.
#' @param stop logical; whether to throw an error in \code{check_tskit_py}.
#' @details This function is meant for users running \code{tskit <- get_tskit_py()}
#'   or similar code, and for other functions in this package that need the
#'   \code{tskit} reticulate Python module. The point of \code{get_tskit_py} is
#'   to avoid importing the module repeatedly; if it has been imported already,
#'   we reuse that instance. This process can be sensitive to the reticulate
#'   Python setup, module availability, and internet access.
#' @return \code{get_tskit_py} returns the reticulate Python module \code{tskit}
#'   if successful. Otherwise it throws an error (when \code{object_name} exists
#'   but is not a reticulate Python module) or returns \code{simpleError}
#'   (when installation or import failed). \code{check_tskit_py} returns
#'   \code{TRUE} if \code{object} is a reticulate Python module or \code{FALSE}
#'   otherwise.
#' @examples
#' \dontrun{
#'   tskit <- get_tskit_py()
#'   is(tskit)
#'   if (check_tskit_py(tskit)) {
#'     tskit$ALLELES_01
#'   }
#' }
#' @export
get_tskit_py <- function(object_name = "tskit", force = FALSE) {
  if (!force) {
    test <- !is.null(object_name) &&
      exists(object_name, envir = .GlobalEnv, inherits = FALSE)
    if (test) {
      tskit <- get(object_name, envir = .GlobalEnv, inherits = FALSE)
      test <- reticulate::is_py_object(tskit) &&
        is(tskit, "python.builtin.module")
      if (test) {
        return(tskit)
      } else {
        txt <- paste0(
          "Object '",
          object_name,
          "' exists in the global environment but is not a reticulate Python module!"
        )
        stop(txt)
      }
    }
  }

  msgSuccess <- paste0('reticulate::py_require("', object_name, '") succeeded!')
  msgFail <- paste0('reticulate::py_require("', object_name, '") failed!')
  e <- simpleError(msgFail)
  if (!reticulate::py_module_available(object_name)) {
    txt <- paste0(
      'Python module ',
      object_name,
      ' is not available. Attempting to install it ...'
    )
    message(txt)
    out <- tryCatch(
      reticulate::py_require(object_name),
      error = function(s) e
    )
    if (is(out, "simpleError")) {
      # Line below is challenging to hit with tests!
      return(out) # nocov
    }
  }
  msgFail <- paste0('reticulate::import("', object_name, '") failed!')
  e <- simpleError(msgFail)
  out <- tryCatch(
    reticulate::import(object_name, delay_load = TRUE),
    error = function(e) e
  )
  return(out)
}

#' @describeIn get_tskit_py Test whether \code{get_tskit_py} returned a reticulate Python module object
#' @export
check_tskit_py <- function(object, stop = FALSE) {
  test <- reticulate::is_py_object(object) &&
    (is(object, "python.builtin.module"))
  if (test) {
    return(TRUE)
  } else {
    msg <- "object must be a reticulate Python module object!"
    if (stop) {
      stop(msg)
    } else {
      message(msg)
    }
    return(FALSE)
  }
}

# INTERNAL
# @title Validating logical args
# @param value logical from the argument
# @param name character of the argument
# @return No return value; called for side effects.
validate_logical_arg <- function(value, name) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    stop(name, " must be TRUE/FALSE!")
  }
}

# INTERNAL
# @title Validating integer-like numeric scalar args
# @param value numeric/integer scalar from the argument
# @param name character of the argument
# @param minimum lower bound
# @param allow_null logical
# @param nullable_msg logical; if TRUE include NULL in error message
# @return Integer scalar (or NULL if allowed).
validate_integer_numeric_scalar_arg <- function(
  value,
  name,
  minimum = NULL,
  allow_null = FALSE,
  nullable_msg = FALSE
) {
  int_min <- -(.Machine$integer.max) - 1
  int_max <- .Machine$integer.max
  fail <- function() {
    if (is.null(minimum)) {
      stop(name, " must be a non-NA integer scalar!")
    }
    if (nullable_msg) {
      stop(
        name,
        " must be ",
        minimum,
        ", NULL, or a non-NA integer scalar!"
      )
    }
    if (identical(minimum, 0L)) {
      stop(name, " must be a non-NA zero or positive integer scalar!")
    }
    stop(name, " must be a non-NA integer scalar >= ", minimum, "!")
  }
  if (is.null(value)) {
    if (allow_null) {
      return(NULL)
    }
    fail()
  }
  if (
    !is.numeric(value) ||
      length(value) != 1L ||
      is.na(value) ||
      !is.finite(value)
  ) {
    fail()
  }
  if (value != trunc(value)) {
    fail()
  }
  if (value < int_min || value > int_max) {
    fail()
  }
  value_int <- as.integer(value)
  if (!is.null(minimum) && value_int < minimum) {
    fail()
  }
  value_int
}

# INTERNAL
# @title Validating integer scalar args
# @param value integer from the argument
# @param name character of the argument
# @param minimum lower bound
# @return No return value; called for side effects.
validate_integer_scalar_arg <- function(value, name, minimum = NULL) {
  validate_integer_numeric_scalar_arg(value, name, minimum = minimum)
}

# INTERNAL
# @title Validating row indexes
# @param index integer row index (0-based)
# @param name character of the argument
# @param allow_null logical
# @return No return value; called for side effects.
validate_row_index <- function(
  index,
  name = "index",
  allow_null = FALSE
) {
  validate_integer_numeric_scalar_arg(
    index,
    name,
    minimum = 0L,
    allow_null = allow_null
  )
}

# INTERNAL
# @title Validating optional numeric vectors with no missing values
# @param value numeric vector or \code{NULL}
# @param name character of the argument
# @return No return value; called for side effects.
validate_optional_numeric_vector_arg <- function(value, name) {
  if (!is.null(value) && (!is.numeric(value) || anyNA(value))) {
    stop(name, " must be NULL or a numeric vector with no NA values!")
  }
}

# INTERNAL
# @title Validating optional integer vectors with no missing values
# @param value integer vector or \code{NULL}
# @param name character of the argument
# @return No return value; called for side effects.
validate_optional_integer_vector_arg <- function(value, name) {
  int_min <- -(.Machine$integer.max) - 1
  int_max <- .Machine$integer.max
  if (is.null(value)) {
    return(invisible(NULL))
  }
  if (
    !is.numeric(value) ||
      anyNA(value) ||
      !all(is.finite(value)) ||
      any(value != trunc(value)) ||
      any(value < int_min) ||
      any(value > int_max)
  ) {
    stop(name, " must be NULL or an integer vector with no NA values!")
  }
}

# INTERNAL
# @title Validating numeric scalar args
# @param value numeric scalar
# @param name character of the argument
# @param allow_null logical
# @param allow_nan logical
# @return No return value; called for side effects.
validate_numeric_scalar_arg <- function(
  value,
  name,
  allow_null = FALSE,
  allow_nan = FALSE
) {
  if (is.null(value)) {
    if (allow_null) {
      return(invisible(NULL))
    }
    stop(name, " must be a non-NA numeric scalar!")
  }
  if (!is.numeric(value) || length(value) != 1L) {
    if (allow_null && allow_nan) {
      stop(name, " must be NaN, NULL, or a non-NA numeric scalar!")
    }
    stop(name, " must be a non-NA numeric scalar!")
  }
  if (allow_nan) {
    if (!is.na(value) || is.nan(value)) {
      return(invisible(NULL))
    }
    stop(name, " must be NaN, NULL, or a non-NA numeric scalar!")
  }
  if (is.na(value)) {
    stop(name, " must be a non-NA numeric scalar!")
  }
}

# INTERNAL
# @title Validating character scalar args
# @param value character scalar
# @param name character of the argument
# @return No return value; called for side effects.
validate_character_scalar_arg <- function(value, name) {
  if (
    is.null(value) ||
      !is.character(value) ||
      length(value) != 1L ||
      is.na(value)
  ) {
    stop(name, " must be a length-1 non-NA character string!")
  }
}

# INTERNAL
# @title Validating nullable integer scalar args with sentinel minimum
# @param value integer scalar or \code{NULL}
# @param name character of the argument
# @param minimum integer scalar sentinel minimum
# @return No return value; called for side effects.
validate_nullable_integer_scalar_arg <- function(
  value,
  name,
  minimum = -1L
) {
  validate_integer_numeric_scalar_arg(
    value,
    name,
    minimum = minimum,
    allow_null = TRUE,
    nullable_msg = TRUE
  )
}

# INTERNAL
# @title Validating metadata argument and possibly converting it to raw
# @param metadata \code{NULL}, character, or raw argument
# @return \code{NULL} when metadata is \code{NULL} and raw vector otherwise.
validate_metadata_arg <- function(metadata) {
  if (is.null(metadata)) {
    return(NULL)
  }
  if (
    is.character(metadata) &&
      length(metadata) == 1L &&
      !is.na(metadata)
  ) {
    return(charToRaw(metadata))
  }
  if (is.raw(metadata)) {
    return(metadata)
  }
  stop(
    "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
}

# INTERNAL
# @title Converting load arguments to \code{tskit} bitwise options
# @param skip_tables logical
# @param skip_reference_sequence logical
# @details Used in TableCollection and TreeSequence classes.
# @return Bitwise options.
# @examples
# load_args_to_options()
# load_args_to_options(skip_tables = TRUE)
# load_args_to_options(skip_reference_sequence = TRUE)
# load_args_to_options(skip_tables = TRUE, skip_reference_sequence = TRUE)
load_args_to_options <- function(
  skip_tables = FALSE,
  skip_reference_sequence = FALSE
) {
  validate_logical_arg(skip_tables, "skip_tables")
  validate_logical_arg(skip_reference_sequence, "skip_reference_sequence")
  options <- 0L
  if (skip_tables) {
    options <- bitwOr(options, bitwShiftL(1L, 0))
  }
  if (skip_reference_sequence) {
    options <- bitwOr(options, bitwShiftL(1L, 1))
  }
  return(options)
}

#' @title Load a tree sequence from a file
#' @param file a string specifying the full path to a tree sequence file.
#' @param skip_tables logical; if \code{TRUE}, load only non-table information.
#' @param skip_reference_sequence logical; if \code{TRUE}, skip loading
#'   reference genome sequence information.
#' @details See the \code{tskit Python} equivalent at
#'   \url{https://tskit.dev/tskit/docs/latest/python-api.html#tskit.load}.
#' @return A \code{\link{TreeSequence}} object.
#' @seealso \code{\link[=TreeSequence]{TreeSequence$new}}
#' @examples
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#' ts <- ts_load(ts_file)
#' is(ts)
#' ts
#' ts$num_nodes()
#' # Also
#' ts <- TreeSequence$new(file = ts_file)
#' is(ts)
#' @export
ts_load <- function(
  file,
  skip_tables = FALSE,
  skip_reference_sequence = FALSE
) {
  ts <- TreeSequence$new(
    file = file,
    skip_tables = skip_tables,
    skip_reference_sequence = skip_reference_sequence
  )
  return(ts)
}

#' @describeIn ts_load Alias for \code{ts_load()}
#' @export
ts_read <- ts_load

#' @title Load a table collection from a file
#' @param file a string specifying the full path to a tree sequence file.
#' @param skip_tables logical; if \code{TRUE}, load only non-table information.
#' @param skip_reference_sequence logical; if \code{TRUE}, skip loading
#'   reference genome sequence information.
#' @return A \code{\link{TableCollection}} object.
#' @details See the \code{tskit Python} equivalent at
#'   \url{https://github.com/tskit-dev/tskit/blob/dc394d72d121c99c6dcad88f7a4873880924dd72/python/tskit/tables.py#L3463}.
#'   TODO: Update URL to TableCollection.load() method #104
#'         https://github.com/HighlanderLab/RcppTskit/issues/104
#' @seealso \code{\link[=TableCollection]{TableCollection$new}}
#' @examples
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#' tc <- tc_load(ts_file)
#' is(tc)
#' tc
#' @export
tc_load <- function(
  file,
  skip_tables = FALSE,
  skip_reference_sequence = FALSE
) {
  tc <- TableCollection$new(
    file = file,
    skip_tables = skip_tables,
    skip_reference_sequence = skip_reference_sequence
  )
  return(tc)
}

#' @describeIn tc_load Alias for \code{tc_load()}
#' @export
tc_read <- tc_load

# @title Print a summary of a tree sequence and its contents
# @param ts an external pointer (\code{externalptr}) to a \code{tsk_treeseq_t}
#   object.
# @details It uses \code{\link{rtsk_treeseq_summary}} and
#   \code{\link{rtsk_treeseq_metadata_length}}.
#   Note that \code{nbytes} property is not available in \code{tskit} C API
#   compared to Python API, so also not available here.
# @return A list with two data.frames; the first contains tree sequence
#   properties and their value; the second contains the numbers of rows in
#   tables and the length of their metadata. All columns are character as they
#   contain different types of values. Use specific functions if you want to
#   obtain non-character values
# @seealso \code{\link[=TreeSequence]{TreeSequence$print}} on how this
#   function is used and presented to users.
# @examples
# ts_file <- system.file("examples/test.trees", package = "RcppTskit")
# ts_xptr <- rtsk_treeseq_load(ts_file)
# RcppTskit:::rtsk_treeseq_print(ts_xptr)
rtsk_treeseq_print <- function(ts) {
  if (!is(ts, "externalptr")) {
    stop("ts must be an object of externalptr class!")
  }
  tmp_summary <- rtsk_treeseq_summary(ts)
  tmp_metadata <- rtsk_treeseq_metadata_length(ts)
  ret <- list(
    ts = data.frame(
      property = c(
        "num_samples",
        "num_trees",
        "sequence_length",
        "discrete_genome",
        "has_reference_sequence",
        "time_units",
        "discrete_time",
        "min_time",
        "max_time",
        "has_metadata",
        "file_uuid"
      ),
      value = c(
        as.character(tmp_summary[["num_samples"]]),
        as.character(tmp_summary[["num_trees"]]),
        as.character(tmp_summary[["sequence_length"]]),
        as.character(tmp_summary[["discrete_genome"]]),
        as.character(tmp_summary[["has_reference_sequence"]]),
        as.character(tmp_summary[["time_units"]]),
        as.character(tmp_summary[["discrete_time"]]),
        as.character(tmp_summary[["min_time"]]),
        as.character(tmp_summary[["max_time"]]),
        as.character(tmp_metadata[["ts"]] > 0),
        as.character(tmp_summary[["file_uuid"]])
      )
    ),
    tables = data.frame(
      table = c(
        "provenances",
        "populations",
        "migrations",
        "individuals",
        "nodes",
        "edges",
        "sites",
        "mutations"
      ),
      number = c(
        as.character(tmp_summary[["num_provenances"]]),
        as.character(tmp_summary[["num_populations"]]),
        as.character(tmp_summary[["num_migrations"]]),
        as.character(tmp_summary[["num_individuals"]]),
        as.character(tmp_summary[["num_nodes"]]),
        as.character(tmp_summary[["num_edges"]]),
        as.character(tmp_summary[["num_sites"]]),
        as.character(tmp_summary[["num_mutations"]])
      ),
      has_metadata = c(
        NA, # provenances have no metadata
        as.character(tmp_metadata[["populations"]] > 0),
        as.character(tmp_metadata[["migrations"]] > 0),
        as.character(tmp_metadata[["individuals"]] > 0),
        as.character(tmp_metadata[["nodes"]] > 0),
        as.character(tmp_metadata[["edges"]] > 0),
        as.character(tmp_metadata[["sites"]] > 0),
        as.character(tmp_metadata[["mutations"]] > 0)
      )
    )
  )
  return(ret)
}

# @title Print a summary of a table collection and its contents
# @param tc an external pointer (\code{externalptr}) to a
#   \code{tsk_table_collection_t} object.
# @details It uses \code{\link{rtsk_table_collection_summary}} and
#   \code{\link{rtsk_table_collection_metadata_length}}.
# @return A list with two data.frames; the first contains table collection
#   properties and their value; the second contains the numbers of rows in
#   tables and the length of their metadata.  All columns are character as they
#   contain different types of values. Use specific functions if you want to
#   obtain non-character values
# @seealso \code{\link[=TableCollection]{TableCollection$print}} on how this
#   function is used and presented to users.
# @examples
# ts_file <- system.file("examples/test.trees", package = "RcppTskit")
# tc_xptr <- rtsk_table_collection_load(ts_file)
# RcppTskit:::rtsk_table_collection_print(tc_xptr)
rtsk_table_collection_print <- function(tc) {
  if (!is(tc, "externalptr")) {
    stop("tc must be an object of externalptr class!")
  }
  tmp_summary <- rtsk_table_collection_summary(tc)
  tmp_metadata <- rtsk_table_collection_metadata_length(tc)
  ret <- list(
    tc = data.frame(
      property = c(
        "sequence_length",
        "has_reference_sequence",
        "time_units",
        "has_metadata",
        "file_uuid",
        "has_index"
      ),
      value = c(
        as.character(tmp_summary[["sequence_length"]]),
        as.character(tmp_summary[["has_reference_sequence"]]),
        as.character(tmp_summary[["time_units"]]),
        as.character(tmp_metadata[["tc"]] > 0),
        as.character(tmp_summary[["file_uuid"]]),
        as.character(tmp_summary[["has_index"]])
      )
    ),
    tables = data.frame(
      table = c(
        "provenances",
        "populations",
        "migrations",
        "individuals",
        "nodes",
        "edges",
        "sites",
        "mutations"
      ),
      number = c(
        as.character(tmp_summary[["num_provenances"]]),
        as.character(tmp_summary[["num_populations"]]),
        as.character(tmp_summary[["num_migrations"]]),
        as.character(tmp_summary[["num_individuals"]]),
        as.character(tmp_summary[["num_nodes"]]),
        as.character(tmp_summary[["num_edges"]]),
        as.character(tmp_summary[["num_sites"]]),
        as.character(tmp_summary[["num_mutations"]])
      ),
      has_metadata = c(
        NA, # provenances have no metadata
        as.character(tmp_metadata[["populations"]] > 0),
        as.character(tmp_metadata[["migrations"]] > 0),
        as.character(tmp_metadata[["individuals"]] > 0),
        as.character(tmp_metadata[["nodes"]] > 0),
        as.character(tmp_metadata[["edges"]] > 0),
        as.character(tmp_metadata[["sites"]] > 0),
        as.character(tmp_metadata[["mutations"]] > 0)
      )
    )
  )
  return(ret)
}

# @title Transfer a tree sequence from R to reticulate Python
# @description This function saves a tree sequence from R to
#   temporary file on disk and reads it into reticulate Python
#   for use with \code{tskit} Python API.
# @param ts an external pointer (\code{externalptr}) to a \code{tsk_treeseq_t} object.
# @param tskit_module reticulate Python module of \code{tskit}. By default,
#   it calls \code{\link{get_tskit_py}} to obtain the module.
# @param cleanup logical; delete the temporary file at the end of the function?
# @return A tree sequence in reticulate Python.
# @details Because this transfer is via a temporary file,
#   the file UUID property changes.
# @seealso \code{\link{ts_py_to_r}}, \code{\link{ts_load}}, and
#   \code{\link[=TreeSequence]{TreeSequence$dump}} on how this function
#   is used and presented to users,
#   and \code{\link{rtsk_treeseq_py_to_r}}, \code{\link{rtsk_treeseq_load}}, and
#   \code{rtsk_treeseq_dump} (Rcpp) for underlying pointer functions.
# @examples
# \dontrun{
#   ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#   ts_r <- ts_load(ts_file)
#   ts_rtsk <- ts_r$xptr
#   is(ts_rtsk)
#   RcppTskit:::rtsk_treeseq_get_num_samples(ts_rtsk) # 16
#   # Transfer the tree sequence to reticulate Python and use tskit Python API
#   ts_py <- RcppTskit:::rtsk_treeseq_r_to_py(ts_rtsk)
#   is(ts_py)
#   ts_py$num_individuals # 8
#   ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#   ts_py$num_individuals # 8
#   ts2_py$num_individuals # 2
#   ts2_py$num_nodes # 8
#   ts2_py$tables$nodes$time # 0.0 ... 5.0093910
# }
rtsk_treeseq_r_to_py <- function(
  ts,
  tskit_module = get_tskit_py(),
  cleanup = TRUE
) {
  if (!is(ts, "externalptr")) {
    stop("ts must be an object of externalptr class!")
  }
  check_tskit_py(tskit_module, stop = TRUE)
  ts_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(file.remove(ts_file))
  }
  rtsk_treeseq_dump(ts, filename = ts_file)
  ts_py <- tskit_module$load(ts_file)
  return(ts_py)
}

# @title Transfer a table collection from R to reticulate Python
# @description This function saves a table collection from R to
#   temporary file on disk and reads it into reticulate Python
#   for use with \code{tskit} Python API.
# @param tc an external pointer (\code{externalptr}) to a
#   \code{tsk_table_collection_t} object.
# @param tskit_module reticulate Python module of \code{tskit}. By default,
#   it calls \code{\link{get_tskit_py}} to obtain the module.
# @param cleanup logical; delete the temporary file at the end of the function?
# @details See \url{https://tskit.dev/tutorials/tables_and_editing.html#tables-and-editing}
#   on what you can do with the tables.
#   Because this transfer is via a temporary file,
#   the file UUID property changes.
# @return A table collection in reticulate Python.
# @seealso \code{\link{tc_py_to_r}}, \code{\link{tc_load}}, and
#   \code{\link[=TableCollection]{TableCollection$dump}} on how this function
#   is used and presented to users,
#   and \code{\link{rtsk_table_collection_py_to_r}}, \code{\link{rtsk_table_collection_load}}, and
#   \code{rtsk_table_collection_dump} (Rcpp) for underlying pointer functions.
# @examples
# \dontrun{
#   ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#   tc_r <- tc_load(ts_file)
#   tc_rtsk <- tc_r$xptr
#   is(tc_rtsk)
#   RcppTskit:::rtsk_table_collection_summary(tc_rtsk)
#   # Transfer the table collection to reticulate Python and use tskit Python API
#   tc_py <- RcppTskit:::rtsk_table_collection_r_to_py(tc_rtsk)
#   is(tc_py)
#   tc_py$individuals$num_rows # 8
#   tmp <- tc_py$simplify(samples = c(0L, 1L, 2L, 3L))
#   tmp
#   tc_py$individuals$num_rows # 2
#   tc_py$nodes$num_rows # 8
#   tc_py$nodes$time # 0.0 ... 5.0093910
# }
rtsk_table_collection_r_to_py <- function(
  tc,
  tskit_module = get_tskit_py(),
  cleanup = TRUE
) {
  if (!is(tc, "externalptr")) {
    stop("tc must be an object of externalptr class!")
  }
  check_tskit_py(tskit_module, stop = TRUE)
  tc_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(file.remove(tc_file))
  }
  rtsk_table_collection_dump(tc, filename = tc_file)
  tc_py <- tskit_module$TableCollection$load(tc_file)
  return(tc_py)
}

# @title Transfer a tree sequence from reticulate Python to R
# @description This function saves a tree sequence from reticulate Python to
#   temporary file on disk and reads it into R for use with \code{RcppTskit}.
# @param ts tree sequence in reticulate Python.
# @param cleanup logical; delete the temporary file at the end of the function?
# @return An external pointer (\code{externalptr}) to a \code{tsk_treeseq_t} object.
# @details Because this transfer is via a temporary file,
#   the file UUID property changes.
# @seealso \code{\link[=TreeSequence]{TreeSequence$r_to_py}},
#   \code{\link{ts_load}}, and \code{\link[=TreeSequence]{TreeSequence$dump}}
#   on how this function is used and presented to users,
#   and \code{\link{rtsk_treeseq_r_to_py}}, \code{\link{rtsk_treeseq_load}}, and
#   \code{rtsk_treeseq_dump} (Rcpp) for underlying pointer functions.
# @examples
# \dontrun{
#   ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#
#   # Use the tskit Python API to work with a tree sequence (via reticulate)
#   tskit <- get_tskit_py()
#   if (check_tskit_py(tskit)) {
#     ts_py <- tskit$load(ts_file)
#     is(ts_py)
#     ts_py$num_individuals # 8
#     ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#     ts_py$num_individuals # 8
#     ts2_py$num_individuals # 2
#     ts2_py$num_nodes # 8
#     ts2_py$tables$nodes$time # 0.0 ... 5.0093910
#
#     # Transfer the tree sequence to R and use RcppTskit
#     ts2_xptr_r <- RcppTskit:::rtsk_treeseq_py_to_r(ts2_py)
#     is(ts2_xptr_r)
#     RcppTskit:::rtsk_treeseq_get_num_individuals(ts2_xptr_r) # 2
#   }
# }
rtsk_treeseq_py_to_r <- function(ts, cleanup = TRUE) {
  if (!reticulate::is_py_object(ts)) {
    stop("ts must be a reticulate Python object!")
  }
  ts_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(file.remove(ts_file))
  }
  ts$dump(ts_file)
  ts_r <- rtsk_treeseq_load(filename = ts_file)
  return(ts_r)
}

# @title Transfer a table collection from reticulate Python to R
# @description This function saves a table collection from reticulate Python to
#   temporary file on disk and reads it into R for use with \code{RcppTskit}.
# @param tc table collection in reticulate Python.
# @param cleanup logical; delete the temporary file at the end of the function?
# @return An external pointer (\code{externalptr}) to a
#   \code{tsk_table_collection_t} object.
# @details Because this transfer is via a temporary file,
#   the file UUID property changes.
# @seealso \code{\link[=TableCollection]{TableCollection$r_to_py}},
#   \code{\link{tc_load}}, and \code{\link[=TableCollection]{TableCollection$dump}}
#   on how this function is used and presented to users,
#   and \code{\link{rtsk_table_collection_r_to_py}}, \code{\link{rtsk_table_collection_load}}, and
#   \code{rtsk_table_collection_dump} (Rcpp) for underlying pointer functions.
# @examples
# \dontrun{
#   ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#
#   # Use the tskit Python API to work with a table collection (via reticulate)
#   tskit <- get_tskit_py()
#   if (check_tskit_py(tskit)) {
#     tc_py <- tskit$TableCollection$load(ts_file)
#     is(tc_py)
#     tc_py$individuals$num_rows # 8
#     tmp <- tc_py$simplify(samples = c(0L, 1L, 2L, 3L))
#     tmp
#     tc_py$individuals$num_rows # 2
#     tc_py$nodes$num_rows # 8
#     tc_py$nodes$time # 0.0 ... 5.0093910
#
#     # Transfer the table collection to R and use RcppTskit
#     tc2_xptr_r <- RcppTskit:::rtsk_table_collection_py_to_r(tc_py)
#     is(tc2_xptr_r)
#     RcppTskit:::rtsk_table_collection_summary(tc2_xptr_r)
#   }
# }
rtsk_table_collection_py_to_r <- function(tc, cleanup = TRUE) {
  if (!reticulate::is_py_object(tc)) {
    stop("tc must be a reticulate Python object!")
  }
  tc_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(file.remove(tc_file))
  }
  tc$dump(tc_file)
  tc_r <- rtsk_table_collection_load(filename = tc_file)
  return(tc_r)
}

#' @title Transfer a tree sequence from reticulate Python to R
#' @description This function saves a tree sequence from reticulate Python to
#'   temporary file on disk and reads it into R for use with \code{RcppTskit}.
#' @param ts tree sequence in reticulate Python.
#' @param cleanup logical; delete the temporary file at the end of the function?
#' @return A \code{\link{TreeSequence}} object.
#' @details Because this transfer is via a temporary file,
#'   the file UUID property changes.
#' @seealso \code{\link[=TreeSequence]{TreeSequence$r_to_py}}
#'   \code{\link{ts_load}}, and \code{\link[=TreeSequence]{TreeSequence$dump}}.
#' @examples
#' \dontrun{
#'   ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#'
#'   # Use the tskit Python API to work with a tree sequence (via reticulate)
#'   tskit <- get_tskit_py()
#'   if (check_tskit_py(tskit)) {
#'     ts_py <- tskit$load(ts_file)
#'     is(ts_py)
#'     ts_py$num_individuals # 8
#'     ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#'     ts_py$num_individuals # 8
#'     ts2_py$num_individuals # 2
#'     ts2_py$num_nodes # 8
#'     ts2_py$tables$nodes$time # 0.0 ... 5.0093910
#'
#'     # Transfer the tree sequence to R and use RcppTskit
#'     ts2_r <- ts_py_to_r(ts2_py)
#'     is(ts2_r)
#'     ts2_r$num_individuals() # 2
#'   }
#' }
#' @export
ts_py_to_r <- function(ts, cleanup = TRUE) {
  xptr <- rtsk_treeseq_py_to_r(ts = ts, cleanup = cleanup)
  ts_r <- TreeSequence$new(xptr = xptr)
  return(ts_r)
}

#' @title Transfer a table collection from reticulate Python to R
#' @description This function saves a table collection from reticulate Python
#'   to temporary file on disk and reads it into R for use with \code{RcppTskit}.
#' @param tc table collection in reticulate Python.
#' @param cleanup logical; delete the temporary file at the end of the function?
#' @return A \code{\link{TableCollection}} object.
#' @details Because this transfer is via a temporary file,
#'   the file UUID property changes.
#' @seealso \code{\link[=TableCollection]{TableCollection$r_to_py}}
#'   \code{\link{tc_load}}, and \code{\link[=TableCollection]{TableCollection$dump}}.
#' @examples
#' \dontrun{
#'   ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#'
#'   # Use the tskit Python API to work with a table collection (via reticulate)
#'   tskit <- get_tskit_py()
#'   if (check_tskit_py(tskit)) {
#'     tc_py <- tskit$TableCollection$load(ts_file)
#'     is(tc_py)
#'     tc_py$individuals$num_rows # 8
#'     tmp <- tc_py$simplify(samples = c(0L, 1L, 2L, 3L))
#'     tmp
#'     tc_py$individuals$num_rows # 2
#'     tc_py$nodes$num_rows # 8
#'     tc_py$nodes$time # 0.0 ... 5.0093910
#'
#'     # Transfer the table collection to R and use RcppTskit
#'     tc_r <- tc_py_to_r(tc_py)
#'     is(tc_r)
#'    tc_r$print()
#'   }
#' }
#' @export
tc_py_to_r <- function(tc, cleanup = TRUE) {
  xptr <- rtsk_table_collection_py_to_r(tc = tc, cleanup = cleanup)
  tc_r <- TableCollection$new(xptr = xptr)
  return(tc_r)
}
