# AGENTS.md

## Scope

These notes apply to this repository root and the `RcppTskit/` package.
RcppTskit aims to provide a practical, well-tested R and C++ interface to
`tskit` while mirroring upstream APIs where practical and clearly documenting
intentional deviations.

Within this scope, we prioritise:

* aligning the tskit R API with the upstream tskit Python API;
* aligning the RcppTskit C++ API with the upstream tskit C API
  (the former is a C++ binding to the tskit C API);
* using `tskit-dev/tskit` and `tskit.dev` as primary references for API
  behavior, naming, and semantics.

## The way of working

* We strive for planned work so we have a plan of what we want to change.
* We strive for minimal changes, unless needed otherwise.
* We provide clear examples for new functionality so useRs can be quickly
  onboarded.
* We add or update tests for every behavior change.
* We run R CMD check for every code change.
* We keep local quality gates green before handoff.
* We update `RcppTskit/NEWS.md` for user-visible behavior or API changes.

## Permissions and authorization

Standing authorization for this repository:

* All commands explicitly shown in this document are pre-authorized for
  repository work (including inline commands and code-block commands,
  with task-specific substitutions where placeholders are shown).
* Agents should run these documented commands directly without asking for
  extra confirmation in chat.
* If sandboxing blocks an allowed command, agents should submit the required
  unsandboxed/escalated tool request directly with a brief justification.
* Agents should ask in chat only if a required escalation is denied or a
  platform policy still blocks execution after escalation.
* Agents may use `curl` (or equivalent read-only HTTP tools) for repository
  and upstream references on:
  `github.com`, `api.github.com`, `raw.githubusercontent.com`,
  `github.com/tskit-dev/tskit`, `tskit.dev`,
  `cran.r-project.org`, `cranchecks.info`, `badges.cranchecks.info`,
  `r-pkg.org`, `cranlogs.r-pkg.org`, `img.shields.io`,
  `codecov.io`, `app.codecov.io`, and `highlanderlab.r-universe.dev`
  (including issues, pull requests, comments, events, metadata, and docs).
* For the above domains, agents should execute `curl` directly without asking
  for extra confirmation in chat; if sandboxing requires escalation, submit the
  escalated tool request immediately and continue.
* To minimise repeated platform permission prompts, prefer these canonical
  command forms (same flags and flag order):

```sh
curl -sS --max-time 15 <url>
curl -I -sS --max-time 15 <url>
```

* This standing authorization does not override explicit user instructions or
  allow destructive commands that were not requested by the user.

## Definition of done

A task is done when all applicable items below are completed:

* Added/updated user-facing examples and tests for new functionality.
* `pre-commit run --all-files` to pass basic code checks.
* `Rscript -e "setwd('RcppTskit'); devtools::test()"`
  for interactive "mode" testing.
* `Rscript -e "setwd('RcppTskit'); devtools::check()"`
  for non-interactive "mode" testing and full package checks.
* Updated `RcppTskit/NEWS.md` for user-visible changes.

### Task-class quality gates

* For docs/config-only changes (for example `AGENTS.md`, README text, `NEWS.md`
  text-only edits, comments, formatting-only), `devtools::test()` and
  `devtools::check()` are not required unless package behavior is affected.
* For behavior-changing R/C++ work, run focused tests first (for example
  `devtools::test(filter = '...')`), then run full package checks before
  handoff (`pre-commit`, `devtools::test()`, and `devtools::check()`).
* If full checks are intentionally skipped, explicitly report what was skipped,
  why, and which focused checks were run.

## Worktree and file hygiene

Default for non-trivial code tasks is to use a dedicated git worktree:

```sh
git fetch origin --prune
git worktree add ../RcppTskit_<task> -b <branch-name> origin/main
```

Within this workflow, follow these rules:

* In the shared root worktree, limit edits to small docs/meta/config work.
* For behavior-changing R/C++ tasks, use a dedicated worktree by default.
* A branch can be checked out in only one worktree at a time.
* If the shared root is dirty or conflicting edits appear, stop and move work
  into a dedicated worktree.
* In a dedicated worktree, edit only task-related files and do not revert or
  overwrite unrelated edits.
* If syncing an existing branch before substantial work, run:

```sh
git fetch origin --prune
git rebase origin/main
```

* If there are local uncommitted edits, use `--autostash` or an explicit stash.
* If conflicts occur, preserve local edits, resolve conflicts carefully, and
  report conflicted files plus the chosen resolution.
* By default, edit files freely but do not run `git add`, `git commit`,
  or `git push` unless explicitly requested.
* If a command leaves files staged unintentionally, report that in handoff.

Worktree cleanup after merge/finish:

```sh
git worktree remove ../RcppTskit_<task>
git worktree prune
```

## Issue triage workflow

For issue exploration, closure recommendations, or "what is left to do?" tasks:

* Read issue body, comments, and events/timeline.
* Check linked commits/PRs and map issue checklist items to current files/tests.
* Report what is done, what is missing, and a concrete recommendation
  (close, keep open, or split follow-up issue).
* Include direct references to supporting files/tests/commits.

## API parity decision rubric

When adding or changing API surface:

* Default to upstream naming, argument semantics, defaults, and error behavior.
* Mirror upstream examples/docs where practical for user familiarity.
* If deviation is intentional (R idioms, safety, performance, or technical
  constraints), document the rationale in code comments and issue/PR notes,
  add tests for the chosen behavior, and record user-visible deviations in
  `RcppTskit/NEWS.md`.

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
* Standard pre-commit hygiene hooks:
  whitespace, line endings, YAML checks,
  merge-conflict markers, and large-file checks.

If a required tool is not found system-wide on `PATH`,
also check user-local bin directories
before assuming it is missing:

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

Run faster package checks from the package directory:

```sh
Rscript -e "setwd('RcppTskit'); devtools::check(vignette = FALSE)"
```
Run this for every code change so changes are evaluated
in the same package context (build, docs, and tests).

Run slower package checks from the package directory:

```sh
Rscript -e "setwd('RcppTskit'); devtools::check()"
```

### Codex runner caveat: build-tools detection

In the sandboxed agent runner, `devtools::check()` may fail early with:

- `Could not find tools necessary to compile a package`

even when compilers are installed. This is caused by sandbox
restrictions around `callr`/`processx` compiler probing,
not by a missing local toolchain.

Use unsandboxed/escalated execution for full package checks.

### Quarto caveat (why it can work interactively but fail in agent runs)

`which quarto` can return `quarto not found`,
yet `devtools::check()` may still work
in interactive Positron/R sessions.

On a Mac, Positron bundles Quarto at:

`/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto`

Interactive IDE sessions may discover this automatically;
non-IDE agent runs usually do not.
For reliable agent checks, prepend this directory to `PATH`:

```sh
Rscript -e "Sys.setenv(PATH=paste('/Applications/Positron.app/Contents/Resources/app/quarto/bin', Sys.getenv('PATH'), sep=':')); setwd('RcppTskit'); devtools::check()"
```

### Current expected check outcome

`devtools::check()` completes in this environment.

## Testing

We strive for very good testing with `testthat`.

- Add or update `testthat` tests for every behavior change.
- Prefer focused regression tests for bug fixes.
- Keep tests runnable via package tests and checks.
- Guard environment-dependent tests with explicit skips
  (for example Python availability, network availability, and CRAN restrictions).

For testing use:
- `Rscript -e "setwd('RcppTskit'); devtools::test()"`
  for interactive "mode" testing, or variants of this one, such as
  `Rscript -e "setwd('RcppTskit'); devtools::test(filter = 'TableCollection')`.

Tests are also run as part of R CMD check.

## Proofreading

If asked to proofread, act as an expert proofreader and editor
with a deep understanding of clear, engaging, and well-structured writing.
Work paragraph by paragraph,
always starting by making a TODO list
that includes individual items for each heading.
Fix spelling, grammar, and other minor problems without asking. Label any unclear, confusing, or ambiguous sentences with
a TODO comment.
Only report what you have changed.
