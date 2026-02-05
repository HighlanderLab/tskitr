# RcppTskit: R access to the `tskit` C API

## Overview

`Tskit` enables performant storage, manipulation, and analysis of ancestral
recombination graphs (ARGs) using succinct tree sequence encoding.
The tree sequence encoding of an ARG is
described in Wong et al. (2024) <doi:10.1093/genetics/iyae100>.
See https://tskit.dev for project news, documentation, and tutorials.
`Tskit` provides Python, C, and Rust application programming interfaces (APIs).
The Python API can be called from R via the `reticulate` R package to
seamlessly load and analyse a tree sequence, as described at
https://tskit.dev/tutorials/RcppTskit.html.
`RcppTskit` provides R access to the `tskit` C API for use cases where the
`reticulate` option is not optimal. For example, for high-performance and
low-level work with tree sequences. Currently, `RcppTskit` provides a limited
number of R functions due to the availability of extensive Python API and
the `reticulate` option.

See more details on the state of the tree sequence ecosystem and aims of
`RcppTskit` in [the introduction vignette](https://highlanderlab.r-universe.dev/articles/RcppTskit/RcppTskit_intro.html) ([source](RcppTskit/vignettes/RcppTskit_intro.qmd)).
The vignette also shows examples on how to use `RcppTskit` on its own or
to develop new R packages.

## Status

<!-- badges: start -->

<!-- Row 1 -->
General: [![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental) <!-- Col-1-End -->
[![Development](https://img.shields.io/badge/development-active-blue.svg)](https://img.shields.io/badge/development-active-blue.svg) <!-- Col-2-End -->
[![Licence](https://img.shields.io/badge/licence-MIT-blue.svg)](https://opensource.org/licenses/MIT) <!-- Col-3-End -->

<!-- Row 2 -->
Release: [![CRAN version](https://www.r-pkg.org/badges/version/RcppTskit)](https://CRAN.R-project.org/package=RcppTskit) <!-- Col-1-End -->
[![Downloads - total](https://cranlogs.r-pkg.org/badges/grand-total/RcppTskit)](https://cranlogs.r-pkg.org/badges/grand-total/RcppTskit) <!-- Col-2-End -->
![GitHub version (main)](https://img.shields.io/github/r-package/v/HighlanderLab/RcppTskit/main?filename=RcppTskit%2FDESCRIPTION&label=Github) <!-- Col-3-End -->

<!-- Row 3 -->
R CMD checks: [![CRAN](https://cranchecks.info/badges/summary/RcppTskit?label=CRAN)](https://cran.r-project.org/web/checks/check_results_RcppTskit.html) <!-- Col-1-End -->
[![R universe](https://highlanderlab.r-universe.dev/RcppTskit/badges/checks?label=R-universe)](https://highlanderlab.r-universe.dev/RcppTskit) <!-- Col-2-End -->
[![GitHub](https://img.shields.io/github/actions/workflow/status/HighlanderLab/RcppTskit/R-CMD-check.yaml?label=GitHub)](https://github.com/HighlanderLab/RcppTskit/actions/workflows/R-CMD-check.yaml) <!-- Col-3-End -->

<!-- Row 4 -->
Code quality: [![Codecov test coverage](https://codecov.io/gh/HighlanderLab/RcppTskit/graph/badge.svg)](https://app.codecov.io/gh/HighlanderLab/RcppTskit) <!-- Col-1-End -->

<!-- badges: end -->

## Contents

  * `extern` - Git submodule for `tskit` and instructions on
    obtaining the latest version and copying the `tskit` C code into
    `RcppTskit` directory.
    `extern` is saved outside of the `RcppTskit` directory
    because `R CMD CHECK` complains otherwise (even with `.Rbuildignore`).

  * `RcppTskit` - R package `RcppTskit`.

## License

  * See `extern/LICENSE` for `tskit`.

  * See `RcppTskit/DESCRIPTION` and `RcppTskit/LICENSE` for `RcppTskit`.

## Installation

To install the published release from CRAN use:

```
# TODO: Publish on CRAN #14
#       https://github.com/HighlanderLab/RcppTskit/issues/14
# install.packages("RcppTskit")
```

To install a published release or specific branches from Github use the
following code. Note that you will have to compile the C/C++ code and will
hence require the complete R build toolchain, including compilers. See
https://r-pkgs.org/setup.html#setup-tools for introduction to this topic,
https://cran.r-project.org/bin/windows/Rtools for Windows tools, and
https://mac.r-project.org/tools for macOS tools.

```
# install.packages("remotes") # If you don't have it already

# Release
# TODO: Tag a release #15
#       https://github.com/HighlanderLab/RcppTskit/issues/15
# remotes::install_github("HighlanderLab/RcppTskit/RcppTskit")

# Main branch
remotes::install_github("HighlanderLab/RcppTskit/RcppTskit@main")

# Development branch
remotes::install_github("HighlanderLab/RcppTskit/RcppTskit@devel")
```

## Development

### Code of Conduct

Please note that the `RcppTskit` project is released with a
[Contributor Code of Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.

### Clone

First clone the repository and step into the directory:

```
git clone https://github.com/HighlanderLab/RcppTskit.git
cd RcppTskit
```

### Pre-commit install

We use [pre-commit](https://pre-commit.com) hooks to ensure code quality.
Specifically, we use:
* [air](https://github.com/posit-dev/air) to format R code,
* [jarl](https://github.com/etiennebacher/jarl) to lint R code,
* [clang-format](https://clang.llvm.org/docs/ClangFormat.html) to format C/C++ code, and
* [clang-tidy](https://clang.llvm.org/extra/clang-tidy/) to lint C/C++ code.

To install the hooks, run:

```
pre-commit install
```

### tskit

If you plan to update `tskit`, follow instructions in `extern/README.md`.

### RcppTskit

Then open `RcppTskit` package directory in your favourite R IDE
(Positron, RStudio, text-editor-of-your-choice, etc.) and implement your changes.

You should routinely check your changes (in R):

```
# Note that the RcppTskit R package is in the RcppTskit sub-directory
setwd("path/to/RcppTskit/RcppTskit")

# Check
devtools::check()

# Install
devtools::install()

# Test
devtools::test()

# Test coverage
cov <- covr::package_coverage(clean = TRUE)
covr::report(cov)
```

Alternatively check your changes from the command line:

```
# Note that the RcppTskit package is in the RcppTskit sub-directory
cd path/to/RcppTskit/RcppTskit

# Check
R CMD build RcppTskit
R CMD check RcppTskit_*.tar.gz

# Install
R CMD INSTALL RcppTskit_*.tar.gz
```

On Windows, replace `tar.gz` with `zip`.

### Pre-commit run

Before committing your changes, run the pre-commit hooks to ensure code quality:

```
# pre-commit autoupdate # to update the hooks
pre-commit run --all-files
# pre-commit run <hook_id>
```

### Continuous integration

We use Github Actions to run continuous integration (CI) checks
on each push and pull request.
Specifically, we run:
* [R CMD check](.github/workflows/R-CMD-check.yaml) on multiple platforms and
* [covr test coverage](.github/workflows/covr.yaml).
