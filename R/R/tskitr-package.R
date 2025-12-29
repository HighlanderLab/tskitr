#' @description
#' Tskit enables performant storage, manipulation and analysis of ancestral
#' recombination graphs using succinct tree sequence encoding; see https://tskit.dev.
#' Tskit provides Python, C, and Rust APIs. The Python API can be called from R
#' via the `reticulate` package to seamlessly load and analyse tree sequences;
#' see https://tskit.dev/tutorials/tskitr.html.
#' `tskitr` provides R access to the tskit C API for use cases where the
#' `reticulate` approach is not suitable. For example, where high-performance
#' and low-level work with tree sequences is required. R access to the parts of
#' C API is added as the need arises.
#' @keywords internal
#'
#' @useDynLib tskitr, .registration = TRUE
#' @import Rcpp
#' @importFrom Rcpp registerPlugin
#' @importFrom Rdpack reprompt
#'
#' @examples
#' # Here are two examples showcasing what you can do with tskitr
#'
#' # 1) Load a tree sequence into an R session and summarise its contents
#' ts_file <- system.file("examples", "test.trees", package = "tskitr")
#' ts <- ts_load(ts_file)
#' ts_num_individuals(ts)
#'
#' # 2) Call tskit C API in C++ code within an R session
#' library(Rcpp)
#' codeString <- '
#'     #include <tskit.h>
#'     int ts_num_individuals(SEXP ts) {
#'         int n;
#'         Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
#'         n = (int) tsk_treeseq_get_num_individuals(xptr);
#'         return n;
#'     }'
#' get_num_individuals <- cppFunction(code=codeString, depends="tskitr", plugins="tskitr")
#' ts_file <- system.file("examples", "test.trees", package="tskitr")
#' ts <- tskitr::ts_load(ts_file)
#' get_num_individuals(ts)
#' ts_num_individuals(ts) # tskitr implementation of get_num_individuals()
#'
#' # For use in an R package, see the vignette TODO
"_PACKAGE"

#' Providing an inline plugin so we can call tskit C API with functions like
#' cppFunction() or sourceCpp(). See package files on how this is used
#' (search for cppFunction).
#
#' Studying RcppArmadillo, I don't see it uses Rcpp::registerPlugin() anywhere,
#' but an LLM suggested that this is because Armadillo is header-only library
#' so depends = "RcppArmadillo" adds include paths and there is no library to
#' link. tskitr is different because we must link against the compiled tskitr
#' shared object (or a static library). The plugin (or explicit PKG_LIBS) is
#' required since depends only sets include paths, not linker flags.
#' @noRd
.onLoad <- function(libname, pkgname) {
  Rcpp::registerPlugin(name = "tskitr", plugin = function() {
    libdir <- system.file("libs", package = "tskitr")
    libnames <- c(
      "tskitr.dylib",
      "tskitr.so",
      "tskitr.dll.a",
      "tskitr.lib",
      "tskitr.dll"
    )
    libpaths <- file.path(libdir, libnames)
    libfile <- libpaths[file.exists(libpaths)][1]
    if (is.na(libfile)) {
      stop("Unable to locate the tskitr shared library in ", libdir)
    }
    list(env = list(PKG_LIBS = paste0(shQuote(libfile))))
  })
}
