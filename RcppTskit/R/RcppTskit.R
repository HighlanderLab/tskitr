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
#' tskit <- get_tskit_py()
#' is(tskit)
#' if (check_tskit_py(tskit)) {
#'   tskit$ALLELES_01
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

# @title Validating logical args
# @param value logical from the argument
# @param name character of the argument
# @return No return value; called for side effects.
validate_logical_arg <- function(value, name) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    stop(name, " must be TRUE/FALSE!")
  }
}

# @title Converting load arguments to \code{tskit} bitwise options
# @param skip_tables logical
# @param skip_reference_sequence logical
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
#'   reference sequence information.
#' @details See the corresponding Python function at
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
#'   reference sequence information.
#' @return A \code{\link{TableCollection}} object.
#' @details See the corresponding Python function at
#'   \url{https://github.com/tskit-dev/tskit/blob/dc394d72d121c99c6dcad88f7a4873880924dd72/python/tskit/tables.py#L3463}.
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
# @details It uses \code{\link{ts_ptr_summary}} and
#   \code{\link{ts_ptr_metadata_length}}.
#   Note that \code{nbytes} property is not available in \code{tskit} C API
#   compared to Python API, so also not available here.
# @return A list with two data.frames; the first contains tree sequence
#   properties and their value; the second contains the numbers of rows in
#   tables and the length of their metadata.
# @seealso \code{\link[=TreeSequence]{TreeSequence$print}} on how this
#   function is used and presented to users.
# @examples
# ts_file <- system.file("examples/test.trees", package = "RcppTskit")
# ts_ptr <- ts_ptr_load(ts_file)
# RcppTskit:::ts_ptr_print(ts_ptr)
ts_ptr_print <- function(ts) {
  if (!is(ts, "externalptr")) {
    stop("ts must be an object of externalptr class!")
  }
  tmp_summary <- ts_ptr_summary(ts)
  tmp_metadata <- ts_ptr_metadata_length(ts)
  ret <- list(
    ts = data.frame(
      property = c(
        "num_samples",
        "sequence_length",
        "num_trees",
        "time_units",
        "min_time",
        "max_time",
        "has_metadata"
      ),
      value = c(
        tmp_summary[["num_samples"]],
        tmp_summary[["sequence_length"]],
        tmp_summary[["num_trees"]],
        tmp_summary[["time_units"]],
        tmp_summary[["min_time"]],
        tmp_summary[["max_time"]],
        tmp_metadata[["ts"]] > 0
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
        tmp_summary[["num_provenances"]],
        tmp_summary[["num_populations"]],
        tmp_summary[["num_migrations"]],
        tmp_summary[["num_individuals"]],
        tmp_summary[["num_nodes"]],
        tmp_summary[["num_edges"]],
        tmp_summary[["num_sites"]],
        tmp_summary[["num_mutations"]]
      ),
      has_metadata = c(
        NA, # provenances have no metadata
        tmp_metadata[["populations"]] > 0,
        tmp_metadata[["migrations"]] > 0,
        tmp_metadata[["individuals"]] > 0,
        tmp_metadata[["nodes"]] > 0,
        tmp_metadata[["edges"]] > 0,
        tmp_metadata[["sites"]] > 0,
        tmp_metadata[["mutations"]] > 0
      )
    )
  )
  return(ret)
}

# @title Print a summary of a table collection and its contents
# @param tc an external pointer (\code{externalptr}) to a
#   \code{tsk_table_collection_t} object.
# @details It uses \code{\link{tc_ptr_summary}} and
#   \code{\link{tc_ptr_metadata_length}}.
# @return A list with two data.frames; the first contains table collection
#   properties and their value; the second contains the numbers of rows in
#   tables and the length of their metadata.
# @seealso \code{\link[=TableCollection]{TableCollection$print}} on how this
#   function is used and presented to users.
# @examples
# ts_file <- system.file("examples/test.trees", package = "RcppTskit")
# tc_ptr <- tc_ptr_load(ts_file)
# RcppTskit:::tc_ptr_print(tc_ptr)
tc_ptr_print <- function(tc) {
  if (!is(tc, "externalptr")) {
    stop("tc must be an object of externalptr class!")
  }
  tmp_summary <- tc_ptr_summary(tc)
  tmp_metadata <- tc_ptr_metadata_length(tc)
  ret <- list(
    tc = data.frame(
      property = c(
        "sequence_length",
        "time_units",
        "has_metadata"
      ),
      value = c(
        tmp_summary[["sequence_length"]],
        tmp_summary[["time_units"]],
        tmp_metadata[["tc"]] > 0
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
        tmp_summary[["num_provenances"]],
        tmp_summary[["num_populations"]],
        tmp_summary[["num_migrations"]],
        tmp_summary[["num_individuals"]],
        tmp_summary[["num_nodes"]],
        tmp_summary[["num_edges"]],
        tmp_summary[["num_sites"]],
        tmp_summary[["num_mutations"]]
      ),
      has_metadata = c(
        NA, # provenances have no metadata
        tmp_metadata[["populations"]] > 0,
        tmp_metadata[["migrations"]] > 0,
        tmp_metadata[["individuals"]] > 0,
        tmp_metadata[["nodes"]] > 0,
        tmp_metadata[["edges"]] > 0,
        tmp_metadata[["sites"]] > 0,
        tmp_metadata[["mutations"]] > 0
      )
    )
  )
  return(ret)
}

# @title Transfer a tree sequence from R to reticulate Python
# @description This function saves a tree sequence from R to disk and
#   reads it into reticulate Python for use with \code{tskit} Python API.
# @param ts an external pointer (\code{externalptr}) to a \code{tsk_treeseq_t} object.
# @param tskit_module reticulate Python module of \code{tskit}. By default,
#   it calls \code{\link{get_tskit_py}} to obtain the module.
# @param cleanup logical; delete the temporary file at the end of the function?
# @return A tree sequence in reticulate Python.
# @seealso \code{\link{ts_py_to_r}}, \code{\link{ts_load}}, and
#   \code{\link[=TreeSequence]{TreeSequence$dump}} on how this function
#   is used and presented to users,
#   and \code{\link{ts_ptr_py_to_r}}, \code{\link{ts_ptr_load}}, and
#   \code{ts_ptr_dump} (Rcpp) for underlying pointer functions.
# @examples
# ts_file <- system.file("examples/test.trees", package = "RcppTskit")
# ts_r <- ts_load(ts_file)
# ts_r_ptr <- ts_r$pointer
# is(ts_r_ptr)
# RcppTskit:::ts_ptr_num_samples(ts_r_ptr) # 160
# # Transfer the tree sequence to reticulate Python and use tskit Python API
# ts_py <- RcppTskit:::ts_ptr_r_to_py(ts_r_ptr)
# is(ts_py)
# ts_py$num_individuals # 80
# ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
# ts_py$num_individuals # 80
# ts2_py$num_individuals # 2
# ts2_py$num_nodes # 10
# ts2_py$tables$nodes$time # 0.0 ... 7.4702817
ts_ptr_r_to_py <- function(ts, tskit_module = get_tskit_py(), cleanup = TRUE) {
  if (!is(ts, "externalptr")) {
    stop("ts must be an object of externalptr class!")
  }
  check_tskit_py(tskit_module, stop = TRUE)
  ts_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(file.remove(ts_file))
  }
  ts_ptr_dump(ts, file = ts_file)
  ts_py <- tskit_module$load(ts_file)
  return(ts_py)
}

# @title Transfer a table collection from R to reticulate Python
# @description This function saves a table collection from R to disk and
#   reads it into reticulate Python for use with \code{tskit} Python API.
# @param tc an external pointer (\code{externalptr}) to a
#   \code{tsk_table_collection_t} object.
# @param tskit_module reticulate Python module of \code{tskit}. By default,
#   it calls \code{\link{get_tskit_py}} to obtain the module.
# @param cleanup logical; delete the temporary file at the end of the function?
# @details See \url{https://tskit.dev/tutorials/tables_and_editing.html#tables-and-editing}
#   on what you can do with the tables.
# @return A table collection in reticulate Python.
# @seealso \code{\link{tc_py_to_r}}, \code{\link{tc_load}}, and
#   \code{\link[=TableCollection]{TableCollection$dump}} on how this function
#   is used and presented to users,
#   and \code{\link{tc_ptr_py_to_r}}, \code{\link{tc_ptr_load}}, and
#   \code{tc_ptr_dump} (Rcpp) for underlying pointer functions.
# @examples
# ts_file <- system.file("examples/test.trees", package = "RcppTskit")
# tc_r <- tc_load(ts_file)
# tc_r_ptr <- tc_r$pointer
# is(tc_r_ptr)
# RcppTskit:::tc_ptr_summary(tc_r_ptr)
# # Transfer the table collection to reticulate Python and use tskit Python API
# tc_py <- RcppTskit:::tc_ptr_r_to_py(tc_r_ptr)
# is(tc_py)
# tc_py$individuals$num_rows # 80
# tmp <- tc_py$simplify(samples = c(0L, 1L, 2L, 3L))
# tmp
# tc_py$individuals$num_rows # 2
# tc_py$nodes$num_rows # 10
# tc_py$nodes$time # 0.0 ... 7.4702817
tc_ptr_r_to_py <- function(tc, tskit_module = get_tskit_py(), cleanup = TRUE) {
  if (!is(tc, "externalptr")) {
    stop("tc must be an object of externalptr class!")
  }
  check_tskit_py(tskit_module, stop = TRUE)
  tc_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(file.remove(tc_file))
  }
  tc_ptr_dump(tc, file = tc_file)
  tc_py <- tskit_module$TableCollection$load(tc_file)
  return(tc_py)
}

# @title Transfer a tree sequence from reticulate Python to R
# @description This function saves a tree sequence from reticulate Python to disk
#   and reads it into R for use with \code{RcppTskit}.
# @param ts tree sequence in reticulate Python.
# @param cleanup logical; delete the temporary file at the end of the function?
# @return An external pointer (\code{externalptr}) to a \code{tsk_treeseq_t} object.
# @seealso \code{\link[=TreeSequence]{TreeSequence$r_to_py}},
#   \code{\link{ts_load}}, and \code{\link[=TreeSequence]{TreeSequence$dump}}
#   on how this function is used and presented to users,
#   and \code{\link{ts_ptr_r_to_py}}, \code{\link{ts_ptr_load}}, and
#   \code{ts_ptr_dump} (Rcpp) for underlying pointer functions.
# @examples
# ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#
# # Use the tskit Python API to work with a tree sequence (via reticulate)
# tskit <- get_tskit_py()
# if (check_tskit_py(tskit)) {
#   ts_py <- tskit$load(ts_file)
#   is(ts_py)
#   ts_py$num_individuals # 80
#   ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#   ts_py$num_individuals # 80
#   ts2_py$num_individuals # 2
#   ts2_py$num_nodes # 10
#   ts2_py$tables$nodes$time # 0.0 ... 7.4702817
#
#   # Transfer the tree sequence to R and use RcppTskit
#   ts2_ptr_r <- RcppTskit:::ts_ptr_py_to_r(ts2_py)
#   is(ts2_ptr_r)
#   RcppTskit:::ts_ptr_num_individuals(ts2_ptr_r) # 2
# }
ts_ptr_py_to_r <- function(ts, cleanup = TRUE) {
  if (!reticulate::is_py_object(ts)) {
    stop("ts must be a reticulate Python object!")
  }
  ts_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(file.remove(ts_file))
  }
  ts$dump(ts_file)
  ts_r <- ts_ptr_load(ts_file)
  return(ts_r)
}

# @title Transfer a table collection from reticulate Python to R
# @description This function saves a table collection from reticulate Python to
#   disk and reads it into R for use with \code{RcppTskit}.
# @param tc table collection in reticulate Python.
# @param cleanup logical; delete the temporary file at the end of the function?
# @return An external pointer (\code{externalptr}) to a
#   \code{tsk_table_collection_t} object.
# @seealso \code{\link[=TableCollection]{TableCollection$r_to_py}},
#   \code{\link{tc_load}}, and \code{\link[=TableCollection]{TableCollection$dump}}
#   on how this function is used and presented to users,
#   and \code{\link{tc_ptr_r_to_py}}, \code{\link{tc_ptr_load}}, and
#   \code{tc_ptr_dump} (Rcpp) for underlying pointer functions.
# @examples
# ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#
# # Use the tskit Python API to work with a table collection (via reticulate)
# tskit <- get_tskit_py()
# if (check_tskit_py(tskit)) {
#   tc_py <- tskit$TableCollection$load(ts_file)
#   is(tc_py)
#   tc_py$individuals$num_rows # 80
#   tmp <- tc_py$simplify(samples = c(0L, 1L, 2L, 3L))
#   tmp
#   tc_py$individuals$num_rows # 2
#   tc_py$nodes$num_rows # 10
#   tc_py$nodes$time # 0.0 ... 7.4702817
#
#   # Transfer the table collection to R and use RcppTskit
#   tc2_ptr_r <- RcppTskit:::tc_ptr_py_to_r(tc_py)
#   is(tc2_ptr_r)
#   RcppTskit:::tc_ptr_summary(tc2_ptr_r)
# }
tc_ptr_py_to_r <- function(tc, cleanup = TRUE) {
  if (!reticulate::is_py_object(tc)) {
    stop("tc must be a reticulate Python object!")
  }
  tc_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(file.remove(tc_file))
  }
  tc$dump(tc_file)
  tc_r <- tc_ptr_load(tc_file)
  return(tc_r)
}

#' @title Transfer a tree sequence from reticulate Python to R
#' @description This function saves a tree sequence from reticulate Python to disk
#'   and reads it into R for use with \code{RcppTskit}.
#' @param ts tree sequence in reticulate Python.
#' @param cleanup logical; delete the temporary file at the end of the function?
#' @return A \code{\link{TreeSequence}} object.
#' @seealso \code{\link[=TreeSequence]{TreeSequence$r_to_py}}
#'   \code{\link{ts_load}}, and \code{\link[=TreeSequence]{TreeSequence$dump}}.
#' @examples
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#'
#' # Use the tskit Python API to work with a tree sequence (via reticulate)
#' tskit <- get_tskit_py()
#' if (check_tskit_py(tskit)) {
#'   ts_py <- tskit$load(ts_file)
#'   is(ts_py)
#'   ts_py$num_individuals # 80
#'   ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#'   ts_py$num_individuals # 80
#'   ts2_py$num_individuals # 2
#'   ts2_py$num_nodes # 10
#'   ts2_py$tables$nodes$time # 0.0 ... 7.4702817
#'
#'   # Transfer the tree sequence to R and use RcppTskit
#'   ts2_r <- ts_py_to_r(ts2_py)
#'   is(ts2_r)
#'   ts2_r$num_individuals() # 2
#' }
#' @export
ts_py_to_r <- function(ts, cleanup = TRUE) {
  ptr <- ts_ptr_py_to_r(ts = ts, cleanup = cleanup)
  ts_r <- TreeSequence$new(pointer = ptr)
  return(ts_r)
}

#' @title Transfer a table collection from reticulate Python to R
#' @description This function saves a table collection from reticulate Python
#'   to disk and reads it into R for use with \code{RcppTskit}.
#' @param tc table collection in reticulate Python.
#' @param cleanup logical; delete the temporary file at the end of the function?
#' @return A \code{\link{TableCollection}} object.
#' @seealso \code{\link[=TableCollection]{TableCollection$r_to_py}}
#'   \code{\link{tc_load}}, and \code{\link[=TableCollection]{TableCollection$dump}}.
#' @examples
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#'
#' # Use the tskit Python API to work with a table collection (via reticulate)
#' tskit <- get_tskit_py()
#' if (check_tskit_py(tskit)) {
#'   tc_py <- tskit$TableCollection$load(ts_file)
#'   is(tc_py)
#'   tc_py$individuals$num_rows # 80
#'   tmp <- tc_py$simplify(samples = c(0L, 1L, 2L, 3L))
#'   tmp
#'   tc_py$individuals$num_rows # 2
#'   tc_py$nodes$num_rows # 10
#'   tc_py$nodes$time # 0.0 ... 7.4702817
#'
#'   # Transfer the table collection to R and use RcppTskit
#'   tc_r <- tc_py_to_r(tc_py)
#'   is(tc_r)
#'   tc_r$print()
#' }
#' @export
tc_py_to_r <- function(tc, cleanup = TRUE) {
  ptr <- tc_ptr_py_to_r(tc = tc, cleanup = cleanup)
  tc_r <- TableCollection$new(pointer = ptr)
  return(tc_r)
}
