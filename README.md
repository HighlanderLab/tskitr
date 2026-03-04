# `RcppTskit`: `R` access to the `tskit C` API

## Overview

<!-- keep in sync with DESCRIPTION file but use `` and Markdown URLs for DOIs -->

`Tskit` enables performant storage, manipulation, and analysis of ancestral
recombination graphs (ARGs) using succinct tree sequence encoding.
The tree sequence encoding of an ARG is
described in Wong et al. (2024)
<[doi:10.1093/genetics/iyae100](https://doi.org/10.1093/genetics/iyae100)>,
while `tskit` project is described in Jeffrey et al. (2026)
<[doi:10.48550/arXiv.2602.09649](https://doi.org/10.48550/arXiv.2602.09649)>.
See https://tskit.dev for project news, documentation, and tutorials.
`Tskit` provides `Python`, `C`, and `Rust` application programming interfaces (APIs).
The `Python` API can be called from `R` via the `reticulate` `R` package to
seamlessly load and analyse a tree sequence, as described at
https://tskit.dev/tutorials/RcppTskit.html.
`RcppTskit` provides `R` access to the `tskit C` API for use cases where the
`reticulate` option is not optimal.
For example, for high-performance and low-level work with tree sequences.
Currently, `RcppTskit` provides a limited number of functions
due to the availability of extensive `Python` API and the `reticulate` option.
The provided `RcppTskit R` API mirrors the `tskit Python` API,
while the `RcppTskit C++` API mirrors the `tskit C` API.

See more details on the state of the tree sequence ecosystem and aims of
`RcppTskit` in [the introduction vignette](https://highlanderlab.r-universe.dev/articles/RcppTskit/RcppTskit_intro.html) ([source](RcppTskit/vignettes/RcppTskit_intro.qmd)).
The vignette also shows examples on how to use `RcppTskit` on its own or
to develop new `R` packages that can leverage `RcppTskit`.

## Status

<!-- badges: start -->

<!-- Row 1 -->
General: [![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental) <!-- Col-1-End -->
[![Development](https://img.shields.io/badge/development-active-blue.svg)](https://github.com/HighlanderLab/RcppTskit?tab=readme-ov-file#development) <!-- Col-2-End -->
[![Licence](https://img.shields.io/badge/licence-MIT-blue.svg)](https://opensource.org/licenses/MIT) <!-- Col-3-End -->

<!-- Row 2 -->
Release: [![CRAN version](https://www.r-pkg.org/badges/version/RcppTskit)](https://CRAN.R-project.org/package=RcppTskit) <!-- Col-1-End -->
[![Downloads - total](https://cranlogs.r-pkg.org/badges/grand-total/RcppTskit)](https://cranlogs.r-pkg.org/#rpackage) <!-- Col-2-End -->
[![GitHub version (main)](https://img.shields.io/github/r-package/v/HighlanderLab/RcppTskit/main?filename=RcppTskit%2FDESCRIPTION&label=Github)](https://github.com/HighlanderLab/RcppTskit) <!-- Col-3-End -->

<!-- Row 3 -->
R CMD checks: [![CRAN summary](https://badges.cranchecks.info/summary/RcppTskit.svg)](https://cran.r-project.org/web/checks/check_results_RcppTskit.html) <!-- Col-1-End -->
[![CRAN worst](https://badges.cranchecks.info/worst/RcppTskit.svg)](https://cran.r-project.org/web/checks/check_results_RcppTskit.html) <!-- Col-2-End -->
[![R universe](https://highlanderlab.r-universe.dev/RcppTskit/badges/checks?label=R-universe)](https://highlanderlab.r-universe.dev/RcppTskit) <!-- Col-3-End -->
[![GitHub](https://img.shields.io/github/actions/workflow/status/HighlanderLab/RcppTskit/R-CMD-check.yaml?label=GitHub)](https://github.com/HighlanderLab/RcppTskit/actions/workflows/R-CMD-check.yaml) <!-- Col-4-End -->

<!-- Row 4 -->
Code quality: [![Codecov test coverage](https://codecov.io/gh/HighlanderLab/RcppTskit/graph/badge.svg)](https://app.codecov.io/gh/HighlanderLab/RcppTskit) <!-- Col-1-End -->

<!-- badges: end -->

## Contents

  * `extern` - Git submodule for `tskit` and instructions on
    obtaining the latest version and copying the `tskit C` code into
    `RcppTskit` directory.
    `extern` is saved outside of the `RcppTskit` directory
    because `R CMD CHECK` complains otherwise (even with `.Rbuildignore`).

  * `RcppTskit` - `R` package `RcppTskit`.

## License

  * See `extern/LICENSE` for `tskit`.

  * See `RcppTskit/LICENSE*` for `RcppTskit`.

## Installation

To install the published release from
[CRAN](https://cran.r-project.org/package=RcppTskit) use:

```
# Install
install.packages("RcppTskit")

# Read the introduction to RcppTskit
vignette("RcppTskit_intro")
```

To install the latest development version (possibly unstable!) from
[R universe](https://r-universe.dev) use:

```
# Install
r_universe_and_cran <- c(
  "https://highlanderlab.r-universe.dev",
  "https://cloud.r-project.org"
  )
install.packages("RcppTskit", repos = r_universe_and_cran)

# Read the introduction to RcppTskit
vignette("RcppTskit_intro")
```

To install the latest development version (possibly unstable!) from Github
use the following code.
Note that you will have to compile the `C/C++` code and vignette,
so you will require the complete build toolchain,
including compilers, other `R` packages, and `quarto`.
See
https://r-pkgs.org/setup.html#setup-tools for introduction to this topic,
https://cran.r-project.org/bin/windows/Rtools for Windows tools, and
https://mac.r-project.org/tools for macOS tools.

```
# install.packages("remotes") # If you don't have it already

# Install the main branch
remotes::install_github("HighlanderLab/RcppTskit/RcppTskit@main",
  build_vignettes=TRUE)

# Install the development branch
remotes::install_github("HighlanderLab/RcppTskit/RcppTskit@devel",
  build_vignettes=TRUE)

# Install a specific release (say, v0.2.0)
remotes::install_github("HighlanderLab/RcppTskit/RcppTskit@v0.2.0")

# Read the introduction to RcppTskit
vignette("RcppTskit_intro")
```

## Development

See [README_DEVEL.md](README_DEVEL.md)
