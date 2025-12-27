# tskitr: R Package providing access to the `tskit` C API

`tskit` enables performant storage, manipulation and analysis of ancestral
recombination graphs using succinct tree sequence encoding; see https://tskit.dev.
`tskit` provides Python, C, and Rust APIs. The Python API can be called from R via
the `reticulate` package to seamlessly load and analyse tree sequences, see
https://tskit.dev/tutorials/tskitr.html.
`tskitr` provides R access to the `tskit` C API for use cases where the `reticulate`
approach is not suitable. For example, where high-performance and low-level work
with tree sequences is required. R access to the parts of C API is added as the
need arises.

## Contents

  * `extern` - Git submodule for `tskit` and instructions on copying C code (saved outside of `R` because `R CMD CHECK` complains otherwise)

  * `R` - R package `tskitr`

TODO: Add R package badges (build status, CRAN version, etc.) to README.md
      https://github.com/HighlanderLab/tskitr/issues/1

## License

  * See `extern/LICENSE` for `tskit`

  * See `R/DESCRIPTION` and `R/LICENSE` for `tskitr`
