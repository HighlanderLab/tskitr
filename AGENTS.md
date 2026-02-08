# AGENTS.md

## Scope

These notes apply to this repository root and the `RcppTskit/` package.

## The way of working

* We strive for planned work so we know what we want to change.
* We strive for minimal changes, unless needed otherwise.
* We provide clear examples for new functionality so useRs can be quickly
  onboarded.
* We add or update tests for every behavior change.
* We run R CMD check for every code change.
* We keep local quality gates green before handoff.
* We update `RcppTskit/NEWS.md` for user-visible behavior or API changes.

## Definition of done

A task is done when all applicable items below are completed:

* Added/updated user-facing examples for new functionality.
* `pre-commit run --all-files`
* `Rscript -e "setwd('RcppTskit'); devtools::test()"`
* `Rscript -e "setwd('RcppTskit'); devtools::check()"`
* Updated `RcppTskit/NEWS.md` for user-visible changes.

## Quality toolchain

These checks mirror `README.md` guidance and enforce package quality.

### Pre-commit hooks

Install once per clone:

```sh
pre-commit install
```

Run before committing:

```sh
pre-commit run --all-files
```

Hook responsibilities:

* `air format .`: format R, Rmd, and qmd files.
* `jarl check .`: lint R, Rmd, and qmd files.
* `clang-format -i --style=file`: format C/C++ sources and headers.
* `python RcppTskit/tools/clang-tidy.py`: run clang-tidy checks for C/C++.
* Standard pre-commit hygiene hooks: whitespace, line endings, YAML checks,
  merge-conflict markers, and large-file checks.

If a required tool is not found system-wide on `PATH`, also check user-local
bin directories before assuming it is missing:

```sh
which <tool> || PATH="$HOME/.local/bin:$HOME/bin:$PATH" which <tool>
```

Useful `clang-tidy` invocations:

```sh
# Full hook set
pre-commit run --all-files

# clang-tidy only
pre-commit run clang-tidy --all-files

# clang-tidy for one file
pre-commit run clang-tidy --files RcppTskit/src/RcppTskit.cpp
```

If `clang-tidy` is not on `PATH` (for example Homebrew LLVM on macOS), set:

```sh
export CLANG_TIDY="$(brew --prefix llvm)/bin/clang-tidy"
```

Then you can run the wrapper script directly:

```sh
python RcppTskit/tools/clang-tidy.py RcppTskit/src/RcppTskit.cpp
```

### Coverage with covr

Use `covr` for test-coverage checks on behavior-changing work:

```sh
Rscript -e "setwd('RcppTskit'); cov <- covr::package_coverage(clean = TRUE); print(cov); covr::report(cov)"
```

### GitHub Actions (CI)

CI runs on push and pull request and acts as the remote quality gate:

* `.github/workflows/R-CMD-check.yaml`: multi-platform R CMD check matrix.
* `.github/workflows/test-coverage.yaml`: `covr` coverage run and Codecov upload.

Local work should pass local checks before relying on CI feedback.

## Generated files and source-of-truth rules

Do not edit generated files by hand:

* `RcppTskit/R/RcppExports.R`
* `RcppTskit/src/RcppExports.cpp`
* `RcppTskit/NAMESPACE`
* Files in `RcppTskit/man/` generated from roxygen comments

Regenerate as needed:

```sh
Rscript -e "setwd('RcppTskit'); Rcpp::compileAttributes()"
Rscript -e "setwd('RcppTskit'); devtools::document()"
```

## Vendored tskit code boundary

* `extern/tskit` is the upstream submodule.
* `RcppTskit/src/tskit/` and `RcppTskit/inst/include/tskit/` are vendored copies.
* Update vendored `tskit` files only via `extern/README.md` workflow.
* Avoid ad-hoc manual edits in vendored files.

## R CMD Check

### Preferred way to R CMD Check

Run package checks from the package directory:

```sh
Rscript -e "setwd('RcppTskit'); devtools::check()"
```

Run this for every code change so changes are evaluated in the same package
context (build, docs, vignettes, and tests).

### Permission

The user explicitly allows unsandboxed/escalated execution for:

- `Rscript -e "setwd('RcppTskit'); devtools::check()"`

### Codex runner caveat: build-tools detection

In the sandboxed agent runner, `devtools::check()` may fail early with:

- `Could not find tools necessary to compile a package`

even when compilers are installed. This is caused by sandbox restrictions around
`callr`/`processx` compiler probing, not by a missing local toolchain.

Use unsandboxed/escalated execution for full package checks.

### Quarto caveat (why it can work interactively but fail in agent runs)

`which quarto` can return `quarto not found`, yet `devtools::check()` may still
work in interactive Positron/R sessions.

On a Mac, Positron bundles Quarto at:

`/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto`

Interactive IDE sessions may discover this automatically; non-IDE agent runs
usually do not. For reliable agent checks, prepend this directory to `PATH`:

```sh
Rscript -e "Sys.setenv(PATH=paste('/Applications/Positron.app/Contents/Resources/app/quarto/bin', Sys.getenv('PATH'), sep=':')); setwd('RcppTskit'); devtools::check()"
```

### Current expected check outcome

`devtools::check()` completes in this environment.

## Testing

We strive for very good testing with `testthat`.

- Add or update `testthat` tests for every behavior change.
- Prefer focused regression tests for bug fixes.
- Keep tests runnable via package checks (`devtools::check()`).
- Guard environment-dependent tests with explicit skips (for example Python
  availability, network availability, and CRAN restrictions).

### Permission

The user explicitly allows unsandboxed/escalated execution for:

- `Rscript -e "setwd('RcppTskit'); devtools::test()"` or variants of this one, such as `Rscript -e "setwd('RcppTskit'); devtools::test(filter = 'TableCollection')`
