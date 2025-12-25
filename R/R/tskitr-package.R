#' @useDynLib tskitr, .registration = TRUE
#' @import Rcpp
#' @importFrom Rdpack reprompt

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
"_PACKAGE"
