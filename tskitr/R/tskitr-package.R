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
#' @importFrom Rcpp registerPlugin cppFunction
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
#' so depends = "RcppArmadillo" adds include paths to headers, while there is
#' no library that we should link to. tskitr is different because we must link
#' against the compiled tskitr library file. The plugin (or explicit PKG_LIBS)
#' is required to provide linking flags in addition to depends providing include
#' paths to headers.
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

#' @describeIn ts_load Alias for \code{ts_load()}
#' @export
ts_read <- ts_load

#' @describeIn ts_dump Alias for \code{ts_dump()}
#' @export
ts_write <- ts_dump
