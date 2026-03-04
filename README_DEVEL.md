# `RcppTskit` development

## Code of Conduct

Please note that the `RcppTskit` project is released with a
[Contributor Code of Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project,
you agree to abide by its terms.

## Introduction

This document shows how to setup development environment.
It assumes that you are familiar working with a terminal
and terminal-based tools.
The document uses `MacOS` to show the workflow and
does not try to be exhaustive.
`Unix/Linux` workflows will be very similar,
likely also `Windows` with `Linux subsystem`.

## Setup

The next set of steps should be done once.
That is, all the steps before the `RcppTskit changes and checks` section.

### Fork and clone `RcppTskit` (with `gh`)

Use these commands:

```sh
gh auth login
gh repo fork HighlanderLab/RcppTskit --clone --remote=true
cd RcppTskit
git remote -v
ls -1
```

### Fork and clone `RcppTskit` (with `git`)

First fork the repo on `GitHub` (using the `Fork` button),
then clone the repository and step into the directory:

```sh
git clone https://github.com/HighlanderLab/RcppTskit.git
cd RcppTskit
```

Set remotes
`upstream` to `HighlanderLab/RcppTskit.git` and
`origin` to `<your-github-username>/RcppTskit.git`:

```sh
git remote rename origin upstream
git remote add origin git@github.com:<your-github-username>/RcppTskit.git
git fetch upstream
git fetch origin
git remote -v
ls -1
```

### Git remote repositories

From the above `git remote -v` command you should see an output like this:

```
upstream git@github.com:HighlanderLab/RcppTskit.git (fetch)
upstream git@github.com:HighlanderLab/RcppTskit.git (push)
origin   git@github.com::<your-github-username>/RcppTskit.git (fetch)
origin   git@github.com::<your-github-username>/RcppTskit.git (push)
```

From the above `ls -1` command you should see an output like this:

```
CODE_OF_CONDUCT.md
extern
RcppTskit
README.md
README_DEVEL.md
```

### `pre-commit` and code quality tools

We use [pre-commit](https://pre-commit.com) hooks to ensure code quality.
These hooks run various code quality tools before you commit and/or push
your changes to the repository.
Specifically, we use:
* [air](https://github.com/posit-dev/air) to format `R` code,
* [jarl](https://github.com/etiennebacher/jarl) to lint `R` code,
* [clang-format](https://clang.llvm.org/docs/ClangFormat.html) to format `C/C++` code, and
* [clang-tidy](https://clang.llvm.org/extra/clang-tidy/) to lint `C/C++` code.

So, you will have to install these tools
before you will be able to contribute.
There are many ways to install these tools.
On a Mac at the time of writing this text (2026-03-04),
this was achieved with:

```sh
# Install pre-commit
brew install pre-commit

# Install air
brew install air

# Install jarl
# See jarl GitHub or website on how to install it

# Install clang-format
brew install clang-format

# Install clang-tidy (it's part of llvm)
brew install llvm
# Add clang-tidy to PATH variable
echo 'export PATH="/opt/homebrew/opt/llvm/bin:$PATH"' >> ~/.zshrc
```

Restart your terminal so the `PATH` variable is updated.

Then, to install the hooks and activate them for pre-push, run:

```sh
pre-commit install --install-hooks
pre-commit install --hook-type pre-push
```

This completes the Setup section!

## `RcppTskit` changes, checks, and contributing

Now that you have forked, cloned, and set-remotes,
you are ready to contribute by changing the code.

### Open an issue

Announce your planned changes
by creating an issue at
<https://github.com/HighlanderLab/RcppTskit/issues>.
Provide
1) a clear issue title and
2) some details.
Make a note of the issue number (starting with `#`).

### Ensure you branch from & rebase to `upstream/main`

***Before implementing the changes,
always create a branch and
ensure you rebase your branch against the latest `main` or `devel` branches
in the `upstream`***
(see <https://github.com/HighlanderLab/RcppTskit/tree/main> and
<https://github.com/HighlanderLab/RcppTskit/tree/devel>),
whichever is more appropriate for your workplan.
Currently, majority of the development is on the `main` branch.

```sh
# See current branches
git branch

# Get the latest changes from origin and upstream
git fetch origin main
git fetch upstream main

# Create a new branch and switch to it
# ... replace bugfix with something appropriate for your case
# ... issueNUM is one option
git branch bugfix
git switch bugfix

# Rebase the branch to to upstream main
git rebase upstream/main

# Check the state of your HEAD
git log
```

From the above `git log` you should see you should see an output like this:

```
commit ... (HEAD -> bugfix, upstream/main, upstream/HEAD, main)
Author: ...
Date: ...

    ...
```

With `...` being something else,
but the key point is that our `HEAD` state of the repository
is pointing to the `bugfix` branch,
which is aligned with the `upstream/main`,
which is also where the `HEAD` state of the `upstream` is.

If there is active development `upstream` and/or
you are taking long time to implement your changes,
you will have to `git rebase` to keep up with the `upstream`.

### Implement changes

Open `RcppTskit` package directory in your favourite `R` editor,
explore the code, and implement your changes.

### Testing changes

We use `testthat` unit testing framework.
See the `tests/testthat` directory.
You should ensure your changes are unit tested,
but this can be done in an interative way.
See below on how to run tests and
asses unit testing coverage.

### `R CMD check`

You should routinely `R CMD check` your changes.

In `R` we recommend:

```R
# Note that the RcppTskit R package is in the RcppTskit sub-directory!
# That is,
# the first RcppTskit below is the git repository directory and
# the scond RcppTskit below is the R package directory within the first.
setwd("path/to/RcppTskit/RcppTskit")

# Check
devtools::check()

# Install
devtools::install()

# Run unit tests
devtools::test()

# Asses unit test coverage
cov <- covr::package_coverage(clean = TRUE)
covr::report(cov)
```

Alternatively `R CMD check` your changes in terminal:

```sh
# Note that the RcppTskit package is in the RcppTskit sub-directory
cd path/to/RcppTskit/RcppTskit

# Check
R CMD build RcppTskit
R CMD check RcppTskit_*.tar.gz

# Install
R CMD INSTALL RcppTskit_*.tar.gz
```

On Windows, replace `tar.gz` with `zip`.

The above does not give you insight into test coverage.

### Contributing your changes

Once you implement the changes and
the `R CMD check` is passing,
your are ready to contribute the changes.
It is useful if you tag the issue in your commit message
by adding `#NUM` at the end.

```sh
git add the_files_you_changed
git commit -m "A clear short message #NUM"
git log
```

The above `git commit` will produce something like:

```
> git commit -m "Implemented foo() #123"
trim trailing whitespace..................................................Passed
fix end of files..........................................................Passed
mixed line ending.........................................................Passed
check yaml............................................(no files to check)Skipped
check for added large files...............................................Passed
check for merge conflicts.................................................Passed
air format................................................................Passed
jarl lint.................................................................Passed
clang-format..........................................(no files to check)Skipped
clang-tidy for RcppTskit..............................(no files to check)Skipped
check sync between cpp and hpp options and defaults...(no files to check)Skipped
[bugfix 1dc2232] Implemented foo()
 1 file changed, 1 insertion(+)
 create mode 100644 foo.txt
```

And `git log` will now show:

```
commit ... (HEAD -> bugfix)
Author: ...
Date: ...

    Implemented foo() #123

commit ... (HEAD -> bugfix, upstream/main, upstream/HEAD, main)
Author: ...
Date: ...

    ...
```

Indicating that we have moved the `bugfix` branch onwards for one commit.

### Pre-commit

As you see from the above,
when committing your changes,
`pre-commit` hooks should kick-in automatically
to ensure code quality.
Manually, you can run them using:

```sh
pre-commit autoupdate # to update the hooks
pre-commit run # on changed files
pre-commit run --all-files # on all files
pre-commit run <hook_id> # just a specific hook
pre-commit run <hook_id> --all-files # ... on all files
# see also --hook-stage option
```

### Pushing to origin and requesting a pull to upstream

You can now push your changes to remote repositories:

```sh
git push origin bugfix
```

Which will printout an URL like
<https://github.com/<your-github-username>/RcppTskit/pull/new/bugfix>.
Open that link and click `Create pull request` (PR).
You also have an option to `Create a draft pull request`
to share your work early and get early feedback from maintainers.
There is a number of options to discuss and evaluate your changes in the PR.
Please mention the issue number `#NUM` (including the `#`)
in the body of the PR,
so tha GitHub can link the PR with the issue.
PR will also obtain a number you can refer to as and when needed.

Note that while the PR is open,
you can continue your work on your branch,
commit new changes,
push them to your `origin/bugfix`, and
all these commits will automatically be included in the PR.

### Continuous integration

When you open a pull request,
you wil trigger a number of Github Actions
that perform continuous integration (CI) checks
on each push and pull request.
Specifically, we perform:
* [R CMD check](.github/workflows/R-CMD-check.yaml) on multiple platforms
  (see curent status [here](https://github.com/HighlanderLab/RcppTskit/actions/workflows/R-CMD-check.yaml)),
* [documentation generation](.github/workflows/document.yaml)
  (see current status [here](https://github.com/HighlanderLab/RcppTskit/actions/workflows/document.yaml)),
* [pre-commit hooks](.github/workflows/pre-commit.yaml)
  (see current status [here](https://github.com/HighlanderLab/RcppTskit/actions/workflows/pre-commit.yaml)), and
* [test coverage](.github/workflows/test-coverage.yaml)
  (see current status [here](https://github.com/HighlanderLab/RcppTskit/actions/workflows/test-coverage.yaml)).

[R universe for RcppTskit](https://highlanderlab.r-universe.dev/RcppTskit)
also provides another set of checks - see [here](https://highlanderlab.r-universe.dev/RcppTskit#checktable).
These are provided after new code is pushed or merged into this repository.

### Squashing commits

It is common to have a number of commits when implementing changes.
To have a clean commit history on the `upstream/main` branch,
we should squash these commits into one
before merging your PR into the `upstream/main`.
This is achieved by:

```sh
git reset --soft HEAD~n
git commit -m "A clear short message #NUM"
git push --force-with-lease origin bugfix
```

where you replace `n` with the number of commits you want to squash.
You can find this number in the PR.

This completes the `RcppTskit` changes, checks, and contributing section!

## `tskit C` update

If you plan to update `tskit C` library,
follow instructions in `extern/README.md`.
