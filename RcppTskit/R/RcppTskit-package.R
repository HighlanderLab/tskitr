#' @description
#' Tskit enables performant storage, manipulation, and analysis of
#' ancestral recombination graphs (ARGs) using succinct tree sequence encoding.
#' See https://tskit.dev for project news, documentation, and tutorials.
#' Tskit provides Python, C, and Rust APIs. The Python API can be called from R
#' via the `reticulate` R package to seamlessly load and analyse a tree sequence
#' as described at https://tskit.dev/tutorials/tskitr.html.
#' `RcppTskit` provides R access to the `tskit` C API for use cases where the
#' `reticulate` approach is not optimal. For example, for high-performance
#' and low-level work with tree sequences. Currently, `RcppTskit` provides a very
#' limited number of R functions due to the availability of extensive Python API
#' and the `reticulate` approach.
#' @keywords internal
#'
#' @useDynLib RcppTskit, .registration = TRUE
#' @importFrom methods is
#' @importFrom R6 R6Class
#' @importFrom Rcpp registerPlugin cppFunction
#' @importFrom reticulate is_py_object import py_module_available py_require
#'
#' @examples
#' \dontshow{# Providing the examples here so we test them via R CMD check}
#' # Here are examples showcasing what you can do with RcppTskit
#'
#' # 1) Load a tree sequence into R and summarise it
#' # Load a tree sequence
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#' ts <- ts_load(ts_file)
#'
#' # Print summary of the tree sequence
#' ts$num_individuals()
#' ts
#'
#' # 2) Pass tree sequence between R and reticulate or standard Python
#'
#' # Tree sequence in R
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#' ts <- ts_load(ts_file)
#'
#' # If you have a tree sequence in R and you want to use tskit Python API,
#' # you can write it to disk and load it into reticulate Python
#' ts_py <- ts$r_to_py()
#' # ... continue in reticulate Python ...
#' ts_py$num_individuals # 80
#' ts2_py = ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#' ts2_py$num_individuals # 2
#' # ... and to bring it back to R ...
#' ts2 <- ts_py_to_r(ts2_py)
#' ts2$num_individuals() # 2
#'
#' # If you prefer standard (non-reticulate) Python, use approach:
#' ts_file <- tempfile()
#' print(ts_file)
#' ts$dump(file = ts_file)
#' # ... continue in standard Python ...
#' # import tskit
#' # ts = tskit.load("insert_ts_file_path_here")
#' # ts.num_individuals # 80
#' # ts2 = ts.simplify(samples = [0, 1, 2, 3])
#' # ts2.num_individuals # 2
#' # ts2.dump("insert_ts_file_path_here")
#' # ... and to bring it back to R ...
#' ts2 <- ts_load(ts_file)
#' ts$num_individuals() # 2 (if you have ran the above Python code)
#' \dontshow{on.exit(file.remove(ts_file)) # clean up}
#'
#' # 3) Call tskit C API in C++ code in R session or script
#' library(Rcpp)
#' # Write and compile a C++ function
#' codeString <- '
#'   #include <tskit.h>
#'   int ts_num_individuals(SEXP ts) {
#'     Rcpp::XPtr<tsk_treeseq_t> ts_xptr(ts);
#'     return (int) tsk_treeseq_get_num_individuals(ts_xptr);
#'   }'
#' ts_num_individuals2 <- Rcpp::cppFunction(code=codeString,
#'                                          depends="RcppTskit",
#'                                          plugins="RcppTskit")
#' # We must specify both the `depends` and `plugins` arguments!
#'
#' # Load a tree sequence
#' ts_file <- system.file("examples/test.trees", package="RcppTskit")
#' ts <- ts_load(ts_file)
#'
#' # Apply the compiled function
#' ts_num_individuals2(ts$pointer)
#'
#' # An identical RcppTskit implementation
#' ts$num_individuals()
#' ts_num_individuals_ptr(ts$pointer)
#'
#' # 4) Call `tskit` C API in C++ code in another R package
#' # TODO: Show vignette here
#' #       https://github.com/HighlanderLab/RcppTskit/issues/10
"_PACKAGE"

#' Providing an inline plugin so we can call tskit C API with functions like
#' cppFunction() or sourceCpp(). See package files on how this is used (search
#' for cppFunction).
#
#' Studying RcppArmadillo, I don't see it uses Rcpp::registerPlugin() anywhere,
#' but an LLM suggested that this is because Armadillo is header-only library
#' so `depends = "RcppArmadillo"` adds include paths to headers, while there is
#' no library that we should link to. RcppTskit is different because we must link
#' against the compiled RcppTskit library file. The `plugins` (or `PKG_LIBS`)
#' is required for linking flags in addition to `depends` for include headers.
#' @noRd
.onLoad <- function(libname, pkgname) {
  # nocov start
  Rcpp::registerPlugin(name = "RcppTskit", plugin = function() {
    # See ?Rcpp::registerPlugin and ?inline::registerPlugin on what the plugin
    # function should return (a list with additional includes, environment
    # variables, such as PKG_LIBS, and other compilation context).
    libdir <- system.file("libs", package = "RcppTskit")
    if (!nzchar(libdir)) {
      stop("Unable to locate the RcppTskit libs directory!")
    }
    libdirs <- libdir
    if (.Platform$OS.type == "windows") {
      libdirs <- c(libdirs, file.path(libdir, .Platform$r_arch))
    }
    candidates <- c(
      "RcppTskit.so", # Unix/Linux and macOS
      "RcppTskit.dylib", # macOS (backup to RcppTskit.so)
      "RcppTskit.dll.a", # Windows (MinGW/Rtools)
      "RcppTskit.lib", # Windows (MSVC, backup)
      "RcppTskit.dll" # Windows (DLL, backup)
    )
    libpaths <- sapply(
      libdirs,
      function(dir) file.path(dir, candidates),
      USE.NAMES = FALSE
    )
    libfile <- libpaths[file.exists(libpaths)][1]
    if (is.na(libfile) || !nzchar(libfile)) {
      stop(
        "Unable to locate the RcppTskit library file in: ",
        paste(libdirs, collapse = ", ")
      )
    }
    list(env = list(PKG_LIBS = shQuote(libfile)))
  })
} # nocov end

#' @title Get the reticulate Python tskit module
#' @description This function imports the reticulate Python \code{tskit} module
#'   and if it is not yet installed, then it attempts to install it first.
#' @param obj_name character name of the object holding \code{tskit} reticulate
#'   Python module. If this object exists in the global R environment and is a
#'   reticulate Python object, then it is returned. Otherwise, the function
#'   attempts to install and import tskit before returning it. If \code{NULL},
#'   then the function directly attempts to install and import tskit before
#'   returning it.
#' @details This function is meant for users running \code{tskit <- get_tskit_py()}
#'   or similar code, but also by other functions in this package that need the
#'   \code{tskit} reticulate Python module. The point of \code{get_tskit_py} is
#'   to avoid importing the module repeatedly, if it already has been imported.
#' @return \code{tskit} reticulate Python module.
#' @examples
#' tskit <- get_tskit_py()
#' is(tskit)
#' tskit$ALLELES_01
#' @export
get_tskit_py <- function(obj_name = "tskit") {
  test <- !is.null(obj_name) &&
    exists(obj_name, envir = .GlobalEnv, inherits = FALSE)
  if (test) {
    tskit <- get(obj_name, envir = .GlobalEnv, inherits = FALSE)
    test <- reticulate::is_py_object(tskit) &&
      is(tskit) == "python.builtin.module"
    if (test) {
      return(tskit)
    } else {
      txt <- paste0(
        "Object '",
        obj_name,
        "' exists in the global environment but is not a reticulate Python module"
      )
      stop(txt)
    }
  }
  # else
  # These lines are hard to hit with tests with cached reticulate Python and modules
  # nocov start
  if (!reticulate::py_module_available("tskit")) {
    txt <- "Python module 'tskit' is not available. Attempting to install it ..."
    cat(txt)
    reticulate::py_require("tskit")
  }
  # nocov end
  return(reticulate::import("tskit", delay_load = TRUE))
}

#' @describeIn ts_load_ptr Load a tree sequence from a file
#' @export
ts_load <- function(file, options = 0L) {
  ts <- TreeSequence$new(file = file, options = options)
  return(ts)
}

#' @describeIn ts_load_ptr Alias for \code{ts_load()}
#' @export
ts_read <- ts_load

#' @describeIn ts_load_ptr Alias for \code{ts_load_ptr()}
#' @export
ts_read_ptr <- ts_load_ptr

#' @describeIn ts_dump_ptr Alias for \code{ts_dump_ptr()}
#' @export
ts_write_ptr <- ts_dump_ptr

# TODO: Do we need/want any other summary functions/methods on ts? #25
#       https://github.com/HighlanderLab/RcppTskit/issues/25
#       # TODO: add min and max time?
#
#' @name ts_print
#' @title Print a summary of a tree sequence and its contents
#' @param ts tree sequence as a \code{\link{TreeSequence}} object or
#'   an external pointer (\code{externalptr}) to a \code{tsk_treeseq_t} object.
#' @details It uses \code{\link{ts_summary}()} and
#'   \code{\link{ts_metadata_length}()}.
#'   Note that \code{nbytes} property is not available in \code{tskit} C API
#'   compared to Python API, so also not available here.
#' @return list with two data.frames; the first contains tree sequence
#'   properties and their value; the second contains the numbers of rows in
#'   tables and the length of their metadata.
#' @examples
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#'
#' # TreeSequence class object
#' ts <- ts_load(ts_file)
#' ts$print()
#' ts
#'
#' # External pointer object
#' ts_ptr <- ts$pointer
#' ts_print_ptr(ts_ptr)
#' @export
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
        # TODO: add min and max time? #25
        "has_metadata"
      ),
      value = c(
        tmp_summary[["num_samples"]],
        tmp_summary[["sequence_length"]],
        tmp_summary[["num_trees"]],
        tmp_summary[["time_units"]],
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

#' @name ts_r_to_py
#' @title Transfer a tree sequence from R to reticulate Python
#' @description This function saves a tree sequence from R to disk and
#'   reads it into reticulate Python for use with \code{tskit} Python API.
#' @param ts tree sequence as a \code{\link{TreeSequence}} object or
#'   external pointer (\code{externalptr}) to a \code{tsk_treeseq_t} object.
#' @param tskit_module reticulate Python module of \code{tskit}. By default,
#'   it calls \code{\link{get_tskit_py}()} to obtain the module.
#' @param cleanup logical delete the temporary file at the end of the function?
#' @return Tree sequence in reticulate Python.
#' @seealso \code{\link{ts_py_to_r}()}, \code{\link{ts_load}()}, and
#'   \code{\link{ts_dump}()}.
#' @examples
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#'
#' # TreeSequence class object
#' # ... Use RcppTskit to work with a tree sequence
#' ts_r <- ts_load(ts_file)
#' is(ts_r)
#' ts_r$num_samples() # 160
#' # ... Transfer the tree sequence to reticulate Python and use tskit Python API
#' ts_py <- ts_r$r_to_py()
#' is(ts_py)
#' ts_py$num_samples # 160
#' ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#' ts2_py$num_samples # 4
#'
#' # External pointer object
#' # ... Use RcppTskit to work with a tree sequence
#' ts_r_ptr <- ts_r$pointer
#' is(ts_r_ptr)
#' ts_num_samples_ptr(ts_r_ptr) # 160
#' # ... Now transfer the tree sequence to reticulate Python and use tskit Python API
#' ts_py <- ts_r_to_py_ptr(ts_r_ptr)
#' is(ts_py)
#' ts_py$num_samples # 160
#' ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#' ts2_py$num_samples # 4
#' @export
ts_r_to_py_ptr <- function(ts, tskit_module = get_tskit_py(), cleanup = TRUE) {
  if (!is(ts, "externalptr")) {
    stop("ts must be an object of externalptr class!")
  }
  if (!reticulate::is_py_object(tskit_module)) {
    stop("tskit_module must be a reticulate Python module object!")
  }
  ts_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(file.remove(ts_file))
  }
  ts_dump_ptr(ts, file = ts_file)
  ts_py <- tskit_module$load(ts_file)
  return(ts_py)
}

#' @name ts_py_to_r
#' @title Transfer a tree sequence from reticulate Python to R
#' @description This function saves a tree sequence from reticulate Python to disk
#'   and reads it into R for use with \code{RcppTskit}.
#' @param ts tree sequence in reticulate Python.
#' @param cleanup logical delete the temporary file at the end of the function?
#' @return tree sequence as a \code{\link{TreeSequence}} object or
#'   external pointer (\code{externalptr}) to a \code{tsk_treeseq_t} object.
#' @seealso \code{\link{ts_r_to_py}()}, \code{\link{ts_load}()}, and
#'   \code{\link{ts_dump}()}.
#' @examples
#' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
#'
#' # Use the tskit Python API to work with a tree sequence (via reticulate)
#' tskit <- get_tskit_py()
#' ts_py <- tskit$load(ts_file)
#' is(ts_py)
#' ts_py$num_samples # 160
#' ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
#' ts2_py$num_samples # 4
#'
#' # Transfer the tree sequence to R and use RcppTskit
#'
#' # TreeSequence object
#' ts2_r <- ts_py_to_r(ts2_py)
#' is(ts2_r)
#' ts2_r$num_samples() # 4
#'
#' # External pointer object
#' ts2_r_ptr <- ts_py_to_r_ptr(ts2_py)
#' is(ts2_r)
#' ts_num_samples_ptr(ts2_r_ptr) # 4
#' @export
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

#' @describeIn ts_py_to_r Transfer a tree sequence from reticulate Python to R
#' @export
ts_py_to_r <- function(ts, cleanup = TRUE) {
  ptr <- ts_py_to_r_ptr(ts = ts, cleanup = cleanup)
  ts_r <- TreeSequence$new(pointer = ptr)
  return(ts_r)
}
