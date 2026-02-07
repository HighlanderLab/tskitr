# RcppTskit news

All notable changes to RcppTskit are documented in this file.
The file format is based on [Keep a Changelog](https://keepachangelog.com),
and releases adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-26

This is the first release.

### Added (new features)

- Initial version of RcppTskit using the tskit C API (1.3.0).
- TreeSequence R6 class so R code looks Pythonic.
- `ts_load()` or `TreeSequence$new()` to load a tree sequence from file into R.
- Methods to summarise a tree sequence and its contents `ts$print()`,
  `ts$num_nodes()`, etc.
- Method to save a tree sequence to a file `ts$dump()`.
- Method to push tree sequence between R and reticulate Python
  `ts$r_to_py()` and `ts_py_to_r()`.
- Most methods have an underlying (unexported) C++ function that works with
  a pointer to tree sequence object, for example, `RcppTskit:::ts_load_ptr()`.
- All implemented functionality is documented and demonstrated with a vignette.
