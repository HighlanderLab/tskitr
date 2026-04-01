# RcppTskit news

All notable changes to `RcppTskit` are documented in this file.
The file format is based on [Keep a Changelog](https://keepachangelog.com),
and releases adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] 2026-03-02

### Added (new features)

- Added the following scalar getters to match `tskit C/Python` API
  - `TreeSequence$discrete_genome()` to query whether genome coordinates
    are discrete integer values.
  - `TreeSequence$has_reference_sequence()` to query whether a tree sequence
    contains a reference genome sequence.
  - `TreeSequence$discrete_time()` to query whether time values are discrete
    integer values.
  - `TreeSequence$file_uuid()` to query the UUID of the source `.trees` file.
  - `TableCollection$has_reference_sequence()` to query whether a table
    collection contains a reference genome sequence.
  - `TableCollection$file_uuid()` to query the UUID of the source `.trees`
    file.
  - `TableCollection$sequence_length()` to query the sequence length.
  - `TableCollection$time_units()` to query the time units.
  - `TableCollection$has_index()` to query whether edge indexes are present.
- Added a public header and defaults for downstream use of `C++` functions in
  `inst/include/RcppTskit_public.hpp`, included by `inst/include/RcppTskit.hpp`.
- Added `TableCollection$build_index()` to build indexes and
  `TableCollection$drop_index()` to drop indexes.
- Added ``TableCollection$num_*()` getters for the number of rows in the tables.
- Added `rtsk_individual_table_add_row()` and
  `TableCollection$individual_table_add_row()` to append individual rows from
  \code{R}, mirroring `tsk_individual_table_add_row()`.
- Added `rtsk_node_table_add_row()` and `TableCollection$node_table_add_row()`
  to append node rows from \code{R}, mirroring `tsk_node_table_add_row()`.
- Added `rtsk_edge_table_add_row()` and `TableCollection$edge_table_add_row()`
  to append edge rows from \code{R}, mirroring `tsk_edge_table_add_row()`.
- Added `rtsk_site_table_add_row()` and `TableCollection$site_table_add_row()`
  to append site rows from \code{R}, mirroring `tsk_site_table_add_row()`.
- Added `rtsk_mutation_table_add_row()` and
  `TableCollection$mutation_table_add_row()` to append mutation rows from
  \code{R}, mirroring `tsk_mutation_table_add_row()`.
- Added `rtsk_node_table_get_row()` and `TableCollection$node_table_get_row()`
  to retrieve node-table rows by 0-based row ID.
- Added `rtsk_table_collection_sort()` and `TableCollection$sort()` to sort
  table collections with 0-based `edge_start` semantics.
- Added low-level variant iterators
  (`rtsk_variant_iterator_init()`/`rtsk_variant_iterator_next()`) and a
  user-facing `TreeSequence$variants()` method to iterate over decoded
  site-by-site variants from \code{R}, aligned with `tskit` Python API
  semantics for `samples`, `isolated_as_missing`, `alleles`, and
  `left`/`right` intervals.
- Added `rtsk_treeseq_get_samples()` and `TreeSequence$samples()` to retrieve
  sample node IDs from a tree sequence.
- TODO

### Changed

- Renamed low-level C++ and R API names such that we map onto `tskit C` API,
  for example, `RcppTskit` functions are named `rtsk_treeseq_load()`,
  while `tskit C` name is `tsk_treeseq_load()`.
  This is an internal breaking change, but in a good direction now that the
  package is still young and in experimental mode.
- Renamed `TreeSequence` and `TableCollection` external-pointer field from
  `pointer` to `xptr`.
- Ensured `TableCollection$tree_sequence()` matches `tskit Python` API:
  it now builds indexes on the `TableCollection`, if indexes are not present.
- We now use `bit64::integer64` (signed 64 bit integer) instead of `int` aiming
  to approach `tsk_size_t` in `tskit C` (unsigned 64 bit integer); in low-level
  `rtsk_treeseq_get_num_*()` wrappers and count/metadata-length fields.
- TODO

### Maintenance

- Turn vignette URL as hyperlinks and similar cosmetics.
- State mirroring of the `R/Python` APIs and `C++/C` APIs across the package.
- Update tskit C to 1.3.1
- TODO

## [0.2.0] - 2026-02-22

### Added (new features)

- Added `TableCollection` `R6` class alongside `tc_load()` or
  `TableCollection$new()`, as well as `dump()`, `tree_sequence()`, and
  `print()` methods.

- Added `TreeSequence$dump_tables()` to copy tables into a `TableCollection`.

- Added `TableCollection` and reticulate `Python` round-trip helpers:
  `TableCollection$r_to_py()` and `tc_py_to_r()`.

- Changed the `R` API to follow `tskit Python` API for loading:
  `ts_load()`, `tc_load()`, `TreeSequence$new()`, and `TableCollection$new()`
  now use `skip_tables` and `skip_reference_sequence` logical arguments instead
  of an integer `options` bitmask.

- Removed user-facing `options` from `TreeSequence$dump()`,
  `TreeSequence$dump_tables()`, `TableCollection$dump()`, and
  `TableCollection$tree_sequence()` to match `R` API with the `tskit Python` API,
  while `C++` API has the bitwise `options` like the `tskit C` API.

- The bitwise options passed to `C++` are now validated.

### Changed

- We now specify `C++20` standard to go around the CRAN Windows issue,
  see #63 for further details.

### Maintenance

- Used `\dontrun{}` with `get_tskit_py()` calls in examples to
  further reduce `R CMD check time` on CRAN.

- Reduced bundled example tree-sequence sizes in `inst/examples/test.trees`
  and `inst/examples/test2.trees` to speed up examples and checks.

- Delete temporary files in examples and tests after use.

- Renamed unexported functions from `RcppTskit:::ts_load_ptr()` to
  `RcppTskit:::ts_ptr_load()` style.

## [0.1.0] - 2026-01-26

This is the first release.

### Added (new features)

- Initial version of `RcppTskit` using the `tskit C` API (1.3.0).

- `TreeSequence R6` class so `R` code looks Pythonic.

- `ts_load()` or `TreeSequence$new()` to load a tree sequence from file into `R`.

- Methods to summarise a tree sequence and its contents `ts$print()`,
  `ts$num_nodes()`, etc.

- Method to save a tree sequence to a file `ts$dump()`.

- Method to push tree sequence between `R` and reticulate `Python`
  `ts$r_to_py()` and `ts_py_to_r()`.

- Most methods have an underlying (unexported) `C++` function that works with
  a pointer to tree sequence object, for example, `RcppTskit:::ts_ptr_load()`.

- All implemented functionality is documented and demonstrated with a vignette.
