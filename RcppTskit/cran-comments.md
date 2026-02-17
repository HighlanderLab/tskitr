## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release (v0.2.0).

* Re-submitting to CRAN.

* Submitted to CRAN on 2026-02-09 and got feedback to quote
  Python, C, and Rust and to be mindful about case sensitivity.

  I assume the case sensitivity refers to the use of
  `Tskit` and `tskit`. I am following the convention from
  https://tskit.dev to use 'Tskit' at the start of sentences and
  'tskit' otherwise. I am also following the guidance from
  the R packages manual & CRAN cookbook to quote program/package name.

  We now also quote Python, C, and Rust (also R for consistency)
  in the DESCRIPTION file.

* It passes checks on my local MacOS laptop using:
  `devtools::check()` and
  `devtools::check(remote = TRUE, manual = TRUE)`.

* It passes checks on GitHub actions on MacOS, Windows, and Linux:
  https://github.com/HighlanderLab/RcppTskit/actions/workflows/R-CMD-check.yaml.

* It passes checks on R universe on all 13 combinations:
  https://highlanderlab.r-universe.dev/RcppTskit#checktable.

* It passes on CRAN win-builder too.

* On my previous CRAN submission (v0.1.0), I got this warning:

  ```
  * checking whether package 'RcppTskit' can be installed ... WARNING
  Found the following significant warnings:
    ../inst/include/tskit/tskit/core.h:171:21: warning: C++ designated initializers only available with '-std=c++20' or '-std=gnu++20' [-Wc++20-extensions]
  ```

  I have now addressed it by setting CXX_STD = CXX20 in Makevars.in.
  Note that discussion with upstream devs of `tskit` indicates that this warning
  seems to arise from how the build tools have been built for CRAN windows,
  since we could not replicate the warning on any of platforms even when
  tweaking the flags, including Windows. See the above checks and
  https://github.com/tskit-dev/tskit/issues/3375.
