# Contains the package description and .onLoad() function

#' @description
#' `Tskit` enables performant storage, manipulation, and analysis of
#' ancestral recombination graphs (ARGs) using succinct tree sequence encoding.
#' See https://tskit.dev for project news, documentation, and tutorials.
#' `Tskit` provides Python, C, and Rust application programming interfaces (APIs).
#' The Python API can be called from R via the `reticulate` R package to
#' seamlessly load and analyse a tree sequence as described at
#' https://tskit.dev/tutorials/tskitr.html.
#' `RcppTskit` provides R access to the `tskit` C API for use cases where the
#' `reticulate` option is not optimal. For example, for high-performance
#' and low-level work with tree sequences. Currently, `RcppTskit` provides a
#' limited number of R functions due to the availability of extensive Python API
#' and the `reticulate` option.
#' @keywords internal
#'
#' @useDynLib RcppTskit, .registration = TRUE
#' @importFrom methods is
#' @importFrom R6 R6Class
#' @importFrom Rcpp registerPlugin cppFunction
#' @importFrom reticulate is_py_object import py_module_available py_require
#'
#' @examples
#' vignette(package="RcppTskit")
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
