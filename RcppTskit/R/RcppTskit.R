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
      return(out) # hard to hit with tests!
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

#' @title Load a tree sequence from a file
#' @param file a string specifying the full path to a tree sequence file.
#' @param options integer bitwise options (see details at
#'   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_load}).
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
ts_load <- function(file, options = 0L) {
  ts <- TreeSequence$new(file = file, options = options)
  return(ts)
}

#' @describeIn ts_load Alias for \code{ts_load()}
#' @export
ts_read <- ts_load

# @title Print a summary of a tree sequence and its contents
# @param ts an external pointer (\code{externalptr}) to a \code{tsk_treeseq_t}
#   object.
# @details It uses \code{\link{ts_summary_ptr}} and
#   \code{\link{ts_metadata_length_ptr}}.
#   Note that \code{nbytes} property is not available in \code{tskit} C API
#   compared to Python API, so also not available here.
# @return list with two data.frames; the first contains tree sequence
#   properties and their value; the second contains the numbers of rows in
#   tables and the length of their metadata.
# @seealso \code{\link[=TreeSequence]{TreeSequence$print}} on how this
#   function is used and presented to users.
# @examples
# ts_file <- system.file("examples/test.trees", package = "RcppTskit")
# ts_ptr <- ts_load_ptr(ts_file)
# RcppTskit:::ts_print_ptr(ts_ptr)
ts_print_ptr <- function(ts) {
  if (!is(ts, "externalptr")) {
    stop("ts must be an object of externalptr class!")
  }
  tmp_summary <- ts_summary_ptr(ts)
  tmp_metadata <- ts_metadata_length_ptr(ts)
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

# @title Transfer a tree sequence from R to reticulate Python
# @description This function saves a tree sequence from R to disk and
#   reads it into reticulate Python for use with \code{tskit} Python API.
# @param ts an external pointer (\code{externalptr}) to a \code{tsk_treeseq_t} object.
# @param tskit_module reticulate Python module of \code{tskit}. By default,
#   it calls \code{\link{get_tskit_py}} to obtain the module.
# @param cleanup logical; delete the temporary file at the end of the function?
# @return Tree sequence in reticulate Python.
# @seealso \code{\link{ts_py_to_r}}, \code{\link{ts_load}}, and
#   \code{\link[=TreeSequence]{TreeSequence$dump}} on how this function
#   is used and presented to users,
#   and \code{\link{ts_py_to_r_ptr}}, \code{\link{ts_load_ptr}}, and
#   \code{ts_dump_ptr} (Rcpp) for underlying pointer functions.
# @examples
# ts_file <- system.file("examples/test.trees", package = "RcppTskit")
# ts_r <- ts_load(ts_file)
# ts_r_ptr <- ts_r$pointer
# is(ts_r_ptr)
# RcppTskit:::ts_num_samples_ptr(ts_r_ptr) # 160
# # Transfer the tree sequence to reticulate Python and use tskit Python API
# ts_py <- RcppTskit:::ts_r_to_py_ptr(ts_r_ptr)
# is(ts_py)
# ts_py$num_samples # 160
# ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
# ts2_py$num_samples # 4
ts_r_to_py_ptr <- function(ts, tskit_module = get_tskit_py(), cleanup = TRUE) {
  if (!is(ts, "externalptr")) {
    stop("ts must be an object of externalptr class!")
  }
  check_tskit_py(tskit_module, stop = TRUE)
  ts_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(file.remove(ts_file))
  }
  ts_dump_ptr(ts, file = ts_file)
  ts_py <- tskit_module$load(ts_file)
  return(ts_py)
}

# @title Transfer a tree sequence from reticulate Python to R
# @description This function saves a tree sequence from reticulate Python to disk
#   and reads it into R for use with \code{RcppTskit}.
# @param ts tree sequence in reticulate Python.
# @param cleanup logical; delete the temporary file at the end of the function?
# @return A \code{\link{TreeSequence}} object or
#   external pointer (\code{externalptr}) to a \code{tsk_treeseq_t} object.
# @seealso \code{\link[=TreeSequence]{TreeSequence$r_to_py}},
#   \code{\link{ts_load}}, and \code{\link[=TreeSequence]{TreeSequence$dump}}
#   on how this function is used and presented to users,
#   and \code{\link{ts_r_to_py_ptr}}, \code{\link{ts_load_ptr}}, and
#   \code{ts_dump_ptr} (Rcpp) for underlying pointer functions.
# @examples
# ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#
# # Use the tskit Python API to work with a tree sequence (via reticulate)
# tskit <- get_tskit_py()
# if (check_tskit_py(tskit)) {
#   ts_py <- tskit$load(ts_file)
#   is(ts_py)
#   ts_py$num_samples # 160
#   ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#   ts2_py$num_samples # 4
#
#   # Transfer the tree sequence to R and use RcppTskit
#   ts2_ptr_r <- RcppTskit:::ts_py_to_r_ptr(ts2_py)
#   is(ts2_ptr_r)
#   RcppTskit:::ts_num_samples_ptr(ts2_ptr_r) # 4
# }
ts_py_to_r_ptr <- function(ts, cleanup = TRUE) {
  if (!reticulate::is_py_object(ts)) {
    stop("ts must be a reticulate Python object!")
  }
  ts_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(file.remove(ts_file))
  }
  ts$dump(ts_file)
  ts_r <- ts_load_ptr(ts_file)
  return(ts_r)
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
#'   ts_py$num_samples # 160
#'   ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#'   ts2_py$num_samples # 4
#'
#'   # Transfer the tree sequence to R and use RcppTskit
#'   ts2_r <- ts_py_to_r(ts2_py)
#'   is(ts2_r)
#'   ts2_r$num_samples() # 4
#' }
#' @export
ts_py_to_r <- function(ts, cleanup = TRUE) {
  ptr <- ts_py_to_r_ptr(ts = ts, cleanup = cleanup)
  ts_r <- TreeSequence$new(pointer = ptr)
  return(ts_r)
}
