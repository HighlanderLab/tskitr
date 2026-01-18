# tskitr: R access to the `tskit` C API

## Overview

Tskit enables performant storage, manipulation, and analysis of ancestral
recombination graphs (ARGs) using succinct tree sequence encoding.
See https://tskit.dev for project news, documentation, and tutorials.
Tskit provides Python, C, and Rust APIs. The Python API can be called from R
via the `reticulate` R package to seamlessly load and analyse a tree sequence,
as described at https://tskit.dev/tutorials/tskitr.html.
`tskitr` provides R access to the `tskit` C API for use cases where the
`reticulate` approach is not optimal. For example, for high-performance and
low-level work with tree sequences. Currently, `tskitr` provides a very limited
number of R functions due to the availability of extensive Python API and
the `reticulate` approach.

See more details on the state of the tree sequence ecosystem and aims for
`tskitr` in [tskitr/inst/STATE_and_AIMS.md](tskitr/inst/STATE_and_AIMS.md),
including examples on how to use it on its own or to develop new R packages.

TODO: Think how to best point to use cases. Probably best to point to vignette!?
      TODO: add vignette issue link here

## Status

<!-- badges: start -->
  [![R-CMD-check](https://github.com/HighlanderLab/tskitr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/HighlanderLab/tskitr/actions/workflows/R-CMD-check.yaml)

  [![Codecov test coverage](https://codecov.io/gh/HighlanderLab/tskitr/graph/badge.svg)](https://app.codecov.io/gh/HighlanderLab/tskitr)
<!-- badges: end -->

TODO: Add R package badges (build status, CRAN version, etc.) to README.md #1
      https://github.com/HighlanderLab/tskitr/issues/1

## Contents

  * `extern` - Git submodule for `tskit` and instructions on obtaining the latest version and copying the `tskit` C code into `tskitr` directory. `extern` is saved outside of the `tskitr` directory because `R CMD CHECK` complains otherwise.

  * `tskitr` - R package `tskitr`.

## License

  * See `extern/LICENSE` for `tskit`.

  * See `tskitr/DESCRIPTION` and `tskitr/LICENSE` for `tskitr`.

## Installation

To install the published release from CRAN use:

```
# TODO: Publish on CRAN #14
#       https://github.com/HighlanderLab/tskitr/issues/14
# install.packages("tskitr")
```

To install a published release or specific branches from Github use the
following code. Note that you will have to compile the C/C++ code and will
hence require the complete R build toolchain, including compilers. See
https://r-pkgs.org/setup.html#setup-tools for introduction to this topic,
https://cran.r-project.org/bin/windows/Rtools for Windows tools, and
https://mac.r-project.org/tools for macOS tools.

```
# install.packages("remotes") # If you don't have it already

# Release (TODO)
# TODO: Tag a release #15
#       https://github.com/HighlanderLab/tskitr/issues/15
# remotes::install_github("HighlanderLab/tskitr/tskitr")

# Main branch
remotes::install_github("HighlanderLab/tskitr/tskitr")

# Development branch
# TODO: Create a devel branch #16
#       https://github.com/HighlanderLab/tskitr/issues/16
# remotes::install_github("HighlanderLab/tskitr/tskitr@devel")
```

## Development

First clone the repository:

```
git clone https://github.com/HighlanderLab/tskitr.git
```

If you plan to update `tskit`, follow instructions in `extern/README.md`.

Then open `tskitr` package directory in your favourite R IDE (Positron, RStudio, text-editor-of-your-choice, etc.), implement your changes and run (in R):

```
# Note that the tskitr package is in the tskitr sub-directory
setwd("path/to/tskitr/tskitr")

# Run checks of your changes, documentation, etc.
devtools::check()

# Install the package
devtools::install()
```

Alternatively you can check and install from command line:

```
# Note that the tskitr package is in the tskitr sub-directory
cd path/to/tskitr

# Run checks of your changes, documentation, etc.
R CMD build tskitr
R CMD check tskitr_*.tar.gz

# Install the package
R CMD INSTALL tskitr_*.tar.gz
```

On Windows, replace `tar.gz` with `zip`.
