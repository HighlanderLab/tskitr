# RcppTskit news

All notable changes to RcppTskit are documented in this file.
The file format is based on [Keep a Changelog](https://keepachangelog.com),
and releases adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-02-13

### Added (new features)

- Added TableCollection R6 class alongside `tc_load()` or `TableCollection$new()`,
  as well as `dump()`, `tree_sequence()`, and `print()` methods.

- Added `TreeSequence$dump_tables()` to copy tables into a TableCollection.

- Added TableCollection and reticulate Python round-trip helpers:
  `TableCollection$r_to_py()` and `tc_py_to_r()`.

- Changed the R API to follow tskit Python API for loading:
  `ts_load()`, `tc_load()`, `TreeSequence$new()`, and `TableCollection$new()`
  now use `skip_tables` and `skip_reference_sequence` logical arguments instead
  of an integer `options` bitmask.

- Removed user-facing `options` from `TreeSequence$dump()`,
  `TreeSequence$dump_tables()`, `TableCollection$dump()`, and
  `TableCollection$tree_sequence()` to match R API with the tskit Python API,
  while C++ API has the bitwise `options` like the tskit C API.

- The bitwise options passed to C++ are now validated.

### Changed

- We now specify C++20 standard to go around the CRAN Windows issue,
  see #63 for further details.

### Maintenance

- Delete temporary files in examples and tests after use.

- Renamed unexported functions from `RcppTskit:::ts_load_ptr()` to
  `RcppTskit:::ts_ptr_load()`.

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
  a pointer to tree sequence object, for example, `RcppTskit:::ts_ptr_load()`.

- All implemented functionality is documented and demonstrated with a vignette.
