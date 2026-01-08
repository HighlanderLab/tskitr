#' @description
#' Tskit (`tskit`)  enables performant storage, manipulation, and analysis of
#' ancestral recombination graphs using succinct tree sequence encoding; see
#' https://tskit.dev.
#' Tskit provides Python, C, and Rust APIs. The Python API can be called from R
#' via the `reticulate` R package to seamlessly load and analyse a tree sequence;
#' see https://tskit.dev/tutorials/tskitr.html.
#' `tskitr` provides R access to the tskit C API for use cases where the
#' `reticulate` approach is not optimal. For example, for high-performance
#' and low-level work with tree sequences. Currently, `tskitr` provides a very
#' limited number of R functions due to the availability of extensive Python API
#' and the `reticulate` approach.
#' @keywords internal
#'
#' @useDynLib tskitr, .registration = TRUE
#' @importFrom Rcpp registerPlugin cppFunction
#' @importFrom reticulate is_py_object import py_module_available py_require
#' @importFrom Rdpack reprompt
#'
#' @examples
#' \dontshow{# Providing the examples here so we test them via R CMD check}
#' # Here are examples showcasing what you can do with tskitr
#'
#' # 1) Load a tree sequence into an R session and summarise its contents
#' ts_file <- system.file("examples/test.trees", package = "tskitr")
#' ts <- ts_load(ts_file)
#' ts_num_individuals(ts)
#'
#' # 2) Call tskit C API in C++ code in an R session
#' codeString <- '
#'   #include <tskit.h>
#'   int ts_num_individuals(SEXP ts) {
#'     int n;
#'     Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
#'     n = (int) tsk_treeseq_get_num_individuals(xptr);
#'     return n;
#'   }'
#' ts_num_individuals2 <- Rcpp::cppFunction(code=codeString, depends="tskitr", plugins="tskitr")
#' ts_file <- system.file("examples/test.trees", package="tskitr")
#' ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
#' ts_num_individuals2(ts)
#' ts_num_individuals(ts) # tskitr implementation of ts_num_individuals2()
#'
#' # 3) Call `tskit` C API in C++ code in another R package
#' state_and_aims_file <- system.file("STATE_and_AIMS.md", package = "tskitr")
#' browseURL(state_and_aims_file)
#'
#' # 4) Call `tskit` C API in R code in an R session or another R package
#' # TODO: Write STATE_and_AIMS.md file on what we want to achieve #12
#' #       https://github.com/HighlanderLab/tskitr/issues/12
#' state_and_aims_file <- system.file("STATE_and_AIMS.md", package = "tskitr")
#' browseURL(state_and_aims_file)
#'
"_PACKAGE"

#' Providing an inline plugin so we can call tskit C API with functions like
#' cppFunction() or sourceCpp(). See package files on how this is used (search
#' for cppFunction).
#
#' Studying RcppArmadillo, I don't see it uses Rcpp::registerPlugin() anywhere,
#' but an LLM suggested that this is because Armadillo is header-only library
#' so `depends = "RcppArmadillo"` adds include paths to headers, while there is
#' no library that we should link to. tskitr is different because we must link
#' against the compiled tskitr library file. The `plugins` (or `PKG_LIBS`)
#' is required for linking flags in addition to `depends` for include headers.
#' @noRd
.onLoad <- function(libname, pkgname) {
  Rcpp::registerPlugin(name = "tskitr", plugin = function() {
    # See ?Rcpp::registerPlugin and ?inline::registerPlugin on what the plugin
    # function should return (a list with additional includes, environment
    # variables, such as PKG_LIBS, and other compilation context).
    libdir <- system.file("libs", package = "tskitr")
    candidates <- c(
      "tskitr.so", # Unix/Linux and macOS
      "tskitr.dylib", # macOS (backup to tskitr.so)
      "tskitr.dll.a", # Windows (MinGW/Rtools)
      "tskitr.lib", # Windows (MSVC, backup)
      "tskitr.dll" # Windows (DLL, backup)
    )
    libpaths <- file.path(libdir, candidates)
    libfile <- libpaths[file.exists(libpaths)][1]
    if (length(libfile) < 1) {
      stop("Unable to locate the tskitr library file in ", libdir)
    }
    list(env = list(PKG_LIBS = shQuote(libfile)))
  })
}

#' Get the reticulate Python tskit module
#'
#' @description This function imports the reticulate Python \code{tskit} module
#'   and if it is not yet installed, then it attempts to install it first.
#' @param obj_name character name of the object holding \code{tskit} reticulate
#'   Python module. If this object exists in the global R environment and is a
#'   reticulate Python object, then it is returned. Otherwise, the function
#'   attempts to install and import the module before returning it. If
#'   \code{NULL}, then the function directly attempts to install and import the
#'   module before returning it.
#' @details This function is meant for users running \code{tskit <- get_tskit()}
#'   or similar, but also by other functions in this package that need the
#'   \code{tskit} reticulate Python module and we don't want to keep importing
#'   it if it already has been imported.
#' @return \code{tskit} reticulate Python module.
#' @examples
#' tskit <- get_tskit()
#' is(tskit)
#' tskit$ALLELES_01
#' @export
get_tskit <- function(obj_name = "tskit") {
  if (
    !is.null(obj_name) && exists(obj_name, envir = .GlobalEnv, inherits = FALSE)
  ) {
    tskit <- get(obj_name, envir = .GlobalEnv, inherits = FALSE)
    if (!reticulate::is_py_object(tskit)) {
      stop(
        "Object '",
        obj_name,
        "' exists in the global environment but is not a reticulate Python module"
      )
    }
    return(tskit)
  }
  # else
  if (!reticulate::py_module_available("tskit")) {
    warning(
      "Python module 'tskit' is not available. Attempting to install it ..."
    )
    reticulate::py_require("tskit")
  }
  return(reticulate::import("tskit", delay_load = TRUE))
}

#' @describeIn ts_load Alias for \code{ts_load()}
#' @export
ts_read <- ts_load

#' @describeIn ts_dump Alias for \code{ts_dump()}
#' @export
ts_write <- ts_dump

# TODO: Do we need/want any other summary functions/methods on ts? #25
#       https://github.com/HighlanderLab/tskitr/issues/25
#       # TODO: add min and max time?
#
#' Print a summary of a tree sequence and its contents
#'
#' @param ts tree sequence as an external pointer to a \code{tsk_treeseq_t} object.
#' @details It uses \code{\link{ts_summary}()} and
#'   \code{\link{ts_metadata_length}()}.
#'   Note that \code{nbytes} property is not available in
#'   \code{tskit} C API compared to Python API.
#' @return list with two data.frames; the first contains tree sequence
#'   properties and their value; the second contains number of rows in
#'   tables and the length of their metadata.
#' @examples
#' ts_file <- system.file("examples/test.trees", package = "tskitr")
#' ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
#' ts_print(ts)
#' ts
#' @export
ts_print <- function(ts) {
  tmp_summary <- ts_summary(ts)
  tmp_metadata <- ts_metadata_length(ts)
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

#' Transfer a tree sequence from R to reticulate Python
#'
#' @description This function saves a tree sequence from R to disk and
#'   reads it into reticulate Python so that we can use \code{tskit} Python API on it.
#' @param ts tree sequence as an external pointer to a \code{tsk_treeseq_t} object.
#' @param tskit_module reticulate Python module of \code{tskit}. By default,
#'   it calls \code{\link{get_tskit}()} to obtain the module.
#' @param cleanup logical delete the temporary file at the end of the function?
#' @return Tree sequence in reticulate Python.
#' @seealso \code{\link{ts_py_to_r}()} and \code{\link{ts_dump}()}.
#' @examples
#' ts_file <- system.file("examples/test.trees", package = "tskitr")
#' # Use the tskitr R API to work with a tree sequence
#' r_ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
#' is(r_ts)
#' ts_num_samples(r_ts) # 160
#' # Now transfer the tree sequence to reticulate Python and use tskit Python API on it
#' py_ts <- ts_r_to_py(r_ts)
#' is(py_ts)
#' py_ts$num_samples # 160
#' @export
ts_r_to_py <- function(ts, tskit_module = get_tskit(), cleanup = TRUE) {
  ts_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(unlink(ts_file))
  }
  ts_dump(ts, file = ts_file)
  if (!reticulate::is_py_object(tskit_module)) {
    stop("tskit_module must be a Python module/object!")
  }
  py_ts <- tskit_module$load(ts_file)
  return(py_ts)
}

#' Transfer a tree sequence from reticulate Python to R
#'
#' @description This function saves a tree sequence from reticulate Python to disk
#'   and reads it into R so that we can use \code{tskitr} R/C++ API on it.
#' @param ts tree sequence in reticulate Python.
#' @param cleanup logical delete the temporary file at the end of the function?
#' @return Tree sequence as an external pointer to a \code{tsk_treeseq_t} object.
#' @seealso \code{\link{ts_r_to_py}()} and \code{\link{ts_dump}()}.
#' @examples
#' ts_file <- system.file("examples/test.trees", package = "tskitr")
#' # Use the tskit Python API to work with a tree sequence (via reticulate)
#' tskit <- get_tskit()
#' py_ts <- tskit$load(ts_file)
#' is(py_ts)
#' py_ts$num_samples # 160
#' py_ts2 <- py_ts$simplify(samples = c(0L, 1L, 2L, 3L))
#' py_ts2$num_samples # 4
#' # Now transfer the tree sequence to R and use tskitr R/C++ API on it
#' r_ts2 <- ts_py_to_r(py_ts2)
#' is(r_ts2)
#' ts_num_samples(r_ts2) # 4
#' @export
ts_py_to_r <- function(ts, cleanup = TRUE) {
  ts_file <- tempfile(fileext = ".trees")
  if (cleanup) {
    on.exit(unlink(ts_file))
  }
  if (!reticulate::is_py_object(ts)) {
    stop("ts must be a Python object!")
  }
  ts$dump(ts_file)
  r_ts <- ts_load(ts_file)
  return(r_ts)
}
