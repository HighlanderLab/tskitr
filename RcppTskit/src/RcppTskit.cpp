#include <RcppTskit.hpp>

namespace {
// namespace to keep the contents local to this file

constexpr tsk_flags_t kLoadSupportedOptions =
    TSK_LOAD_SKIP_TABLES | TSK_LOAD_SKIP_REFERENCE_SEQUENCE;

constexpr tsk_flags_t kCopyTablesSupportedOptions = TSK_COPY_FILE_UUID;

constexpr tsk_flags_t kTreeseqInitSupportedOptions =
    TSK_TS_INIT_BUILD_INDEXES | TSK_TS_INIT_COMPUTE_MUTATION_PARENTS;

// @title Validate load options
// @param options passed to load functions
// @param caller function name
// @details See
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_table_collection_load}.
//   The \code{ts_ptr_load} and \code{tc_ptr_load} allocate objects, so
//   we can't work with \code{TSK_NO_INIT}
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.TSK_NO_INIT}.
tsk_flags_t validate_load_options(const int options, const char *caller) {
  const tsk_flags_t load_options = static_cast<tsk_flags_t>(options);
  const tsk_flags_t unsupported = load_options & ~kLoadSupportedOptions;
  // ~ flips the bits in kLoadSupportedOptions
  if (unsupported != 0) {
    Rcpp::stop(
        "%s only supports load options TSK_LOAD_SKIP_TABLES (1 << 0) and "
        "TSK_LOAD_SKIP_REFERENCE_SEQUENCE (1 << 1); unsupported bits: 0x%X",
        caller, static_cast<unsigned int>(unsupported));
  }
  return load_options;
}

// @title Validate copy tables options
// @param options passed to load functions
// @param caller function name
// @details See
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_copy_tables}
//   and
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_table_collection_copy}.
//   The \code{ts_ptr_to_tc_ptr} allocates table collection, so
//   we can't work with \code{TSK_NO_INIT}
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.TSK_NO_INIT}.
tsk_flags_t validate_copy_tables_options(const int options,
                                         const char *caller) {
  const tsk_flags_t copy_options = static_cast<tsk_flags_t>(options);
  if (copy_options & TSK_NO_INIT) {
    Rcpp::stop("%s does not support TSK_NO_INIT because the destination table "
               "collection is newly allocated in this wrapper",
               caller);
  }
  const tsk_flags_t unsupported = copy_options & ~kCopyTablesSupportedOptions;
  if (unsupported != 0) {
    Rcpp::stop("%s only supports copy option TSK_COPY_FILE_UUID (1 << 0); "
               "unsupported bits: 0x%X",
               caller, static_cast<unsigned int>(unsupported));
  }
  return copy_options;
}

// @title Validate tree sequence initialisation options
// @param options passed to load functions
// @param caller function name
// @details See
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_init}.
//   The \code{tc_ptr_to_ts_ptr} allocates tree sequence from table collection,
//   so we can't use \code{TSK_TAKE_OWNERSHIP} as the table collection object
//   still exists on R side
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.TSK_TAKE_OWNERSHIP}.
tsk_flags_t validate_treeseq_init_options(const int options,
                                          const char *caller) {
  const tsk_flags_t init_options = static_cast<tsk_flags_t>(options);
  if (init_options & TSK_TAKE_OWNERSHIP) {
    Rcpp::stop(
        "%s does not support TSK_TAKE_OWNERSHIP because ownership/lifecycle "
        "is managed by R external pointers in this wrapper",
        caller);
  }
  const tsk_flags_t unsupported = init_options & ~kTreeseqInitSupportedOptions;
  if (unsupported != 0) {
    Rcpp::stop(
        "%s only supports init options TSK_TS_INIT_BUILD_INDEXES (1 << 0) "
        "and TSK_TS_INIT_COMPUTE_MUTATION_PARENTS (1 << 1); unsupported "
        "bits: 0x%X",
        caller, static_cast<unsigned int>(unsupported));
  }
  return init_options;
}

// @title Validate tree sequence/table collection dump options
// @param options passed to dump functions
// @param caller function name
// @details See
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_dump}
//   and
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_table_collection_dump}.
//   \code{tskit} currently does not use dump options and expects \code{0}.
tsk_flags_t validate_dump_options(const int options, const char *caller) {
  const tsk_flags_t dump_options = static_cast<tsk_flags_t>(options);
  if (dump_options != 0) {
    Rcpp::stop("%s does not support non-zero options; tsk dump APIs currently "
               "require options = 0",
               caller);
  }
  return dump_options;
}

} // namespace

//' @title Report the version of installed kastore C API
//' @details The version is stored in the installed header \code{kastore.h}.
//' @return A named vector with three elements \code{major}, \code{minor}, and
//'   \code{patch}.
//' @examples
//' kastore_version()
//' @export
// [[Rcpp::export]]
Rcpp::IntegerVector kastore_version() {
  // Rcpp::_["major"] is shorthand for Rcpp::Named("major")
  return Rcpp::IntegerVector::create(Rcpp::_["major"] = KAS_VERSION_MAJOR,
                                     Rcpp::_["minor"] = KAS_VERSION_MINOR,
                                     Rcpp::_["patch"] = KAS_VERSION_PATCH);
}

//' @title Report the version of installed \code{tskit} C API
//' @details The version is defined in the installed header \code{tskit/core.h}.
//' @return A named vector with three elements \code{major}, \code{minor}, and
//'   \code{patch}.
//' @examples
//' tskit_version()
//' @export
// [[Rcpp::export]]
Rcpp::IntegerVector tskit_version() {
  return Rcpp::IntegerVector::create(Rcpp::_["major"] = TSK_VERSION_MAJOR,
                                     Rcpp::_["minor"] = TSK_VERSION_MINOR,
                                     Rcpp::_["patch"] = TSK_VERSION_PATCH);
}

// @title Load a tree sequence from a file
// @param file a string specifying the full path of the tree sequence file.
// @param options \code{tskit} bitwise flags (see details and note that only
//   \code{TSK_LOAD_SKIP_TABLES} and \code{TSK_LOAD_SKIP_REFERENCE_SEQUENCE},
//   but not \code{TSK_NO_INIT}, are supported by this wrapper).
// @details This function calls
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_load}.
// @return An external pointer to tree sequence as a \code{tsk_treeseq_t}
//   object
// @seealso \code{\link{ts_load}} and
//   \code{\link[=TreeSequence]{TreeSequence$new}} on how this function is used
//   and presented to users.
// @examples
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// ts_ptr <- RcppTskit:::ts_ptr_load(ts_file)
// is(ts_ptr)
// ts_ptr
// RcppTskit:::ts_ptr_num_nodes(ts_ptr)
// ts <- TreeSequence$new(pointer = ts_ptr)
// is(ts)
// [[Rcpp::export]]
SEXP ts_ptr_load(const std::string file, const int options = 0) {
  const tsk_flags_t load_options =
      validate_load_options(options, "ts_ptr_load");
  // tsk_treeseq_t ts; // on stack, destroyed end of func, must free resources
  tsk_treeseq_t *ts_ptr = new tsk_treeseq_t(); // on heap, persists function
  // See also https://tskit.dev/tskit/docs/stable/c-api.html#api-structure
  int ret = tsk_treeseq_load(ts_ptr, file.c_str(), load_options);
  if (ret != 0) {
    tsk_treeseq_free(ts_ptr);
    delete ts_ptr;
    Rcpp::stop(tsk_strerror(ret));
  }
  // Wrap ts_ptr for R as an external pointer
  // "true" below means that R will call finaliser on garbage collection
  RcppTskit_treeseq_xptr ts_xptr(ts_ptr, true);
  return ts_xptr;
}

// @title Load a table collection from a file
// @param file a string specifying the full path of the tree sequence file.
// @param options \code{tskit} bitwise flags (see details and note that only
//   \code{TSK_LOAD_SKIP_TABLES} and \code{TSK_LOAD_SKIP_REFERENCE_SEQUENCE},
//   but not \code{TSK_NO_INIT}, are supported by this wrapper).
// @details This function calls
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_table_collection_load}.
// @return An external pointer to table collection as a
//   \code{tsk_table_collection_t} object
// @seealso \code{\link{tc_load}} and
//   \code{\link[=TableCollection]{TableCollection$new}} on how this function is
//   used and presented to users.
// @examples
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// tc_ptr <- RcppTskit:::tc_ptr_load(ts_file)
// is(tc_ptr)
// tc_ptr
// RcppTskit:::tc_ptr_print(tc_ptr)
// tc <- TableCollection$new(pointer = tc_ptr)
// is(tc)
// [[Rcpp::export]]
SEXP tc_ptr_load(const std::string file, const int options = 0) {
  const tsk_flags_t load_options =
      validate_load_options(options, "tc_ptr_load");
  tsk_table_collection_t *tc_ptr = new tsk_table_collection_t();
  int ret = tsk_table_collection_load(tc_ptr, file.c_str(), load_options);
  if (ret != 0) {
    tsk_table_collection_free(tc_ptr);
    delete tc_ptr;
    Rcpp::stop(tsk_strerror(ret));
  }
  RcppTskit_table_collection_xptr tc_xptr(tc_ptr, true);
  return tc_xptr;
}

// @title Write a tree sequence to a file
// @param ts an external pointer to tree sequence as a \code{tsk_treeseq_t}
//   object.
// @param file a string specifying the full path of the tree sequence file.
// @param options \code{tskit} bitwise flags (see details and note that
//   these options are currently unused in \code{tskit} and should be \code{0}).
// @details This function calls
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_dump}.
// @return No return value; called for side effects.
// @examples
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// ts_ptr <- RcppTskit:::ts_ptr_load(ts_file)
// dump_file <- tempfile()
// RcppTskit:::ts_ptr_dump(ts_ptr, dump_file)
// [[Rcpp::export]]
void ts_ptr_dump(const SEXP ts, const std::string file, const int options = 0) {
  const tsk_flags_t dump_options =
      validate_dump_options(options, "ts_ptr_dump");
  RcppTskit_treeseq_xptr ts_xptr(ts);
  int ret = tsk_treeseq_dump(ts_xptr, file.c_str(), dump_options);
  if (ret != 0) {
    Rcpp::stop(tsk_strerror(ret));
  }
}

// @title Write a table collection to a file
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @param file a string specifying the full path of the tree sequence file.
// @param options \code{tskit} bitwise flags (see details and note that
//   these options are currently unused in \code{tskit} and should be \code{0}).
// @details This function calls
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_table_collection_dump}.
// @return No return value; called for side effects.
// @examples
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// tc_ptr <- RcppTskit:::tc_ptr_load(ts_file)
// dump_file <- tempfile()
// RcppTskit:::tc_ptr_dump(tc_ptr, dump_file)
// [[Rcpp::export]]
void tc_ptr_dump(const SEXP tc, const std::string file, const int options = 0) {
  const tsk_flags_t dump_options =
      validate_dump_options(options, "tc_ptr_dump");
  RcppTskit_table_collection_xptr tc_xptr(tc);
  int ret = tsk_table_collection_dump(tc_xptr, file.c_str(), dump_options);
  if (ret != 0) {
    Rcpp::stop(tsk_strerror(ret));
  }
}

// @title Copy a tree sequence's tables into a table collection
// @param ts an external pointer to tree sequence as a \code{tsk_treeseq_t}
//   object.
// @param options \code{tskit} bitwise flags (see details and note that
//   this wrapper does not support \code{TSK_NO_INIT}, but supports
//   \code{TSK_COPY_FILE_UUID}).
// @details This function calls
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_copy_tables}.
//   See also low-level Python-C call of \code{TreeSequence_dump_tables} in
//   \url{https://github.com/tskit-dev/tskit/blob/dc394d72d121c99c6dcad88f7a4873880924dd72/python/_tskitmodule.c#L5323}
// @return An external pointer to table collection as a
//   \code{tsk_table_collection_t} object
// @seealso \code{\link{tc_load}} and
//   \code{\link[=TreeSequence]{TreeSequence$dump_tables}} on how this function
//   is used and presented to users.
// @examples
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// ts_ptr <- RcppTskit:::ts_ptr_load(ts_file)
// tc_ptr <- RcppTskit:::ts_ptr_to_tc_ptr(ts_ptr)
// is(tc_ptr)
// tc_ptr
// RcppTskit:::tc_ptr_print(tc_ptr)
// [[Rcpp::export]]
SEXP ts_ptr_to_tc_ptr(const SEXP ts, const int options = 0) {
  const tsk_flags_t copy_options =
      validate_copy_tables_options(options, "ts_ptr_to_tc_ptr");
  RcppTskit_treeseq_xptr ts_xptr(ts);
  tsk_table_collection_t *tc_ptr = new tsk_table_collection_t();
  int ret = tsk_treeseq_copy_tables(ts_xptr, tc_ptr, copy_options);
  if (ret != 0) {
    tsk_table_collection_free(tc_ptr);
    delete tc_ptr;
    Rcpp::stop(tsk_strerror(ret));
  }
  RcppTskit_table_collection_xptr tc_xptr(tc_ptr, true);
  return tc_xptr;
}

// @title Initialise a tree sequence from a table collection
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @param options \code{tskit} bitwise flags (see details and note that
//   this wrapper supports
//   \code{TSK_TS_INIT_BUILD_INDEXES} and
//   \code{TSK_TS_INIT_COMPUTE_MUTATION_PARENTS}, but not
//   \code{TSK_TAKE_OWNERSHIP}).
// @details This function calls
//   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_init}.
//   See also low-level Python-C call of \code{TreeSequence_load_tables} in
//   \url{https://github.com/tskit-dev/tskit/blob/dc394d72d121c99c6dcad88f7a4873880924dd72/python/_tskitmodule.c#L5292}
// @return An external pointer to tree sequence as a \code{tsk_treeseq_t}
//   object
// @seealso \code{\link{tc_load}} and
//   \code{\link[=TableCollection]{TableCollection$tree_sequence}} on how this
//   function is used and presented to users.
// @examples
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// tc_ptr <- RcppTskit:::tc_ptr_load(ts_file)
// RcppTskit:::tc_ptr_print(tc_ptr)
// ts_ptr <- RcppTskit:::tc_ptr_to_ts_ptr(tc_ptr)
// RcppTskit:::ts_ptr_print(ts_ptr)
// [[Rcpp::export]]
SEXP tc_ptr_to_ts_ptr(const SEXP tc, const int options = 0) {
  const tsk_flags_t init_options =
      validate_treeseq_init_options(options, "tc_ptr_to_ts_ptr");
  RcppTskit_table_collection_xptr tc_xptr(tc);
  tsk_treeseq_t *ts_ptr = new tsk_treeseq_t();
  int ret = tsk_treeseq_init(ts_ptr, tc_xptr, init_options);
  if (ret != 0) {
    tsk_treeseq_free(ts_ptr);
    delete ts_ptr;
    Rcpp::stop(tsk_strerror(ret));
  }
  RcppTskit_treeseq_xptr ts_xptr(ts_ptr, true);
  return ts_xptr;
}

// See tsk_treeseq_t inst/include/tskit/tskit/trees.h on what it contains. Here
// is the Python summary
// https://tskit.dev/tskit/docs/stable/python-api.html#trees-and-tree-sequences
// See tsk_table_collection_t inst/include/tskit/tskit/tables.h on what it
// contains. Here is the Python summary
// https://tskit.dev/tskit/docs/stable/python-api.html#sec-tables-api-table-collection

// @describeIn ts_ptr_summary Get the number of provenances in a tree sequence
// [[Rcpp::export]]
int ts_ptr_num_provenances(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_provenances(ts_xptr));
}

// @describeIn ts_ptr_summary Get the number of populations in a tree sequence
// [[Rcpp::export]]
int ts_ptr_num_populations(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_populations(ts_xptr));
}

// @describeIn ts_ptr_summary Get the number of migrations in a tree sequence
// [[Rcpp::export]]
int ts_ptr_num_migrations(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_migrations(ts_xptr));
}

// @describeIn ts_ptr_summary Get the number of individuals in a tree sequence
// [[Rcpp::export]]
int ts_ptr_num_individuals(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_individuals(ts_xptr));
}

// @describeIn ts_ptr_summary Get the number of samples (of nodes) in a tree
//   sequence
// [[Rcpp::export]]
int ts_ptr_num_samples(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_samples(ts_xptr));
}

// @describeIn ts_ptr_summary Get the number of nodes in a tree sequence
// [[Rcpp::export]]
int ts_ptr_num_nodes(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_nodes(ts_xptr));
}

// @describeIn ts_ptr_summary Get the number of edges in a tree sequence
// [[Rcpp::export]]
int ts_ptr_num_edges(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_edges(ts_xptr));
}

// @describeIn ts_ptr_summary Get the number of trees in a tree sequence
// [[Rcpp::export]]
int ts_ptr_num_trees(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_trees(ts_xptr));
}

// @describeIn ts_ptr_summary Get the number of sites in a tree sequence
// [[Rcpp::export]]
int ts_ptr_num_sites(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_sites(ts_xptr));
}

// @describeIn ts_ptr_summary Get the number of mutations in a tree sequence
// [[Rcpp::export]]
int ts_ptr_num_mutations(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_mutations(ts_xptr));
}

// @describeIn ts_ptr_summary Get the sequence length
// [[Rcpp::export]]
double ts_ptr_sequence_length(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return tsk_treeseq_get_sequence_length(ts_xptr);
}

// @describeIn ts_ptr_summary Get the time units string
// [[Rcpp::export]]
Rcpp::String ts_ptr_time_units(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  const char *p = tsk_treeseq_get_time_units(ts_xptr);
  tsk_size_t n = tsk_treeseq_get_time_units_length(ts_xptr);
  std::string time_units;
  if (n > 0 && p != NULL) {
    time_units.assign(p, p + n);
  }
  return Rcpp::String(time_units);
}

// @describeIn ts_ptr_summary Get the min time in node table and mutation table
// [[Rcpp::export]]
double ts_ptr_min_time(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return tsk_treeseq_get_min_time(ts_xptr);
}

// @describeIn ts_ptr_summary Get the max time in node table and mutation table
// [[Rcpp::export]]
double ts_ptr_max_time(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return tsk_treeseq_get_max_time(ts_xptr);
}

// @name ts_ptr_summary
// @title Summary of properties and number of records in a tree sequence
// @param ts an external pointer to tree sequence as a \code{tsk_treeseq_t}
//   object.
// @details These functions return the summary of properties and number of
//   records in a tree sequence, by calling
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_provenances},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_populations},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_migrations},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_individuals},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_samples},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_nodes},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_edges},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_trees},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_sites},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_mutations},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_sequence_length},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_time_units},
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_min_time},
//   and
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_max_time},
// @return A named list with the number/value for all items,
//   while other functions \code{ts_num_x} and \code{ts_ptr_num_x} etc.
//   return the number/value of each item.
// @examples
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// ts_ptr <- RcppTskit:::ts_ptr_load(ts_file)
// RcppTskit:::ts_ptr_summary(ts_ptr)
// RcppTskit:::ts_ptr_num_provenances(ts_ptr)
// RcppTskit:::ts_ptr_num_populations(ts_ptr)
// RcppTskit:::ts_ptr_num_migrations(ts_ptr)
// RcppTskit:::ts_ptr_num_individuals(ts_ptr)
// RcppTskit:::ts_ptr_num_samples(ts_ptr)
// RcppTskit:::ts_ptr_num_nodes(ts_ptr)
// RcppTskit:::ts_ptr_num_edges(ts_ptr)
// RcppTskit:::ts_ptr_num_trees(ts_ptr)
// RcppTskit:::ts_ptr_num_sites(ts_ptr)
// RcppTskit:::ts_ptr_num_mutations(ts_ptr)
// RcppTskit:::ts_ptr_sequence_length(ts_ptr)
// RcppTskit:::ts_ptr_time_units(ts_ptr)
// RcppTskit:::ts_ptr_min_time(ts_ptr)
// RcppTskit:::ts_ptr_max_time(ts_ptr)
// [[Rcpp::export]]
Rcpp::List ts_ptr_summary(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return Rcpp::List::create(
      Rcpp::_["num_provenances"] = tsk_treeseq_get_num_provenances(ts_xptr),
      Rcpp::_["num_populations"] = tsk_treeseq_get_num_populations(ts_xptr),
      Rcpp::_["num_migrations"] = tsk_treeseq_get_num_migrations(ts_xptr),
      Rcpp::_["num_individuals"] = tsk_treeseq_get_num_individuals(ts_xptr),
      Rcpp::_["num_samples"] = tsk_treeseq_get_num_samples(ts_xptr),
      Rcpp::_["num_nodes"] = tsk_treeseq_get_num_nodes(ts_xptr),
      Rcpp::_["num_edges"] = tsk_treeseq_get_num_edges(ts_xptr),
      Rcpp::_["num_trees"] = tsk_treeseq_get_num_trees(ts_xptr),
      Rcpp::_["num_sites"] = tsk_treeseq_get_num_sites(ts_xptr),
      Rcpp::_["num_mutations"] = tsk_treeseq_get_num_mutations(ts_xptr),
      Rcpp::_["sequence_length"] = tsk_treeseq_get_sequence_length(ts_xptr),
      Rcpp::_["time_units"] = ts_ptr_time_units(ts),
      Rcpp::_["min_time"] = ts_ptr_min_time(ts),
      Rcpp::_["max_time"] = ts_ptr_max_time(ts));
}

// @title Summary of properties and number of records in a table collection
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @return A named list with the number/value for all items.
// @examples
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// tc_ptr <- RcppTskit:::tc_ptr_load(ts_file)
// RcppTskit:::tc_ptr_summary(tc_ptr)
// [[Rcpp::export]]
Rcpp::List tc_ptr_summary(const SEXP tc) {
  RcppTskit_table_collection_xptr tc_xptr(tc);
  const tsk_table_collection_t *tables = tc_xptr;
  std::string time_units;
  if (tables->time_units_length > 0 && tables->time_units != NULL) {
    time_units.assign(tables->time_units,
                      tables->time_units + tables->time_units_length);
  }
  return Rcpp::List::create(
      Rcpp::_["num_provenances"] = tables->provenances.num_rows,
      Rcpp::_["num_populations"] = tables->populations.num_rows,
      Rcpp::_["num_migrations"] = tables->migrations.num_rows,
      Rcpp::_["num_individuals"] = tables->individuals.num_rows,
      Rcpp::_["num_nodes"] = tables->nodes.num_rows,
      Rcpp::_["num_edges"] = tables->edges.num_rows,
      Rcpp::_["num_sites"] = tables->sites.num_rows,
      Rcpp::_["num_mutations"] = tables->mutations.num_rows,
      Rcpp::_["sequence_length"] = tables->sequence_length,
      Rcpp::_["time_units"] = time_units);
}

// @title Get the length of metadata in a tree sequence and its tables
// @param ts tree sequence as a \code{\link{TreeSequence}} object or
//   an external pointer to tree sequence as a \code{tsk_treeseq_t} object.
// @details This function returns the length of metadata stored on the tree
//   sequence and in each table by calling
//   \code{ts->tables->metadata_length} and
//   \code{ts->tables->x->metadata_length} on each table \code{x}, e.g.,
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_population_table_t.metadata_length}.
// @return A named list with the length of metadata.
// @examples
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// ts_ptr <- RcppTskit:::ts_ptr_load(ts_file)
// RcppTskit:::ts_ptr_metadata_length(ts_ptr)
// [[Rcpp::export]]
Rcpp::List ts_ptr_metadata_length(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  const tsk_table_collection_t *tables = ts_xptr->tables;
  return Rcpp::List::create(
      // The tree sequence metadata is the tables collection metadata and
      // tsk_treeseq_get_metadata_length() returns self->tables->metadata_length
      // Rcpp::_["ts"] =
      //    static_cast<int>(tsk_treeseq_get_metadata_length(ts_xptr)),
      Rcpp::_["ts"] = static_cast<int>(tables->metadata_length),
      Rcpp::_["populations"] =
          static_cast<int>(tables->populations.metadata_length),
      Rcpp::_["migrations"] =
          static_cast<int>(tables->migrations.metadata_length),
      Rcpp::_["individuals"] =
          static_cast<int>(tables->individuals.metadata_length),
      Rcpp::_["nodes"] = static_cast<int>(tables->nodes.metadata_length),
      Rcpp::_["edges"] = static_cast<int>(tables->edges.metadata_length),
      Rcpp::_["sites"] = static_cast<int>(tables->sites.metadata_length),
      Rcpp::_["mutations"] =
          static_cast<int>(tables->mutations.metadata_length));
}

// @title Get the length of metadata in a table collection and its tables
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @return A named list with the length of metadata.
// @examples
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// tc_ptr <- RcppTskit:::tc_ptr_load(ts_file)
// RcppTskit:::tc_ptr_metadata_length(tc_ptr)
// [[Rcpp::export]]
Rcpp::List tc_ptr_metadata_length(const SEXP tc) {
  RcppTskit_table_collection_xptr tc_xptr(tc);
  return Rcpp::List::create(
      Rcpp::_["tc"] = static_cast<int>(tc_xptr->metadata_length),
      Rcpp::_["populations"] =
          static_cast<int>(tc_xptr->populations.metadata_length),
      Rcpp::_["migrations"] =
          static_cast<int>(tc_xptr->migrations.metadata_length),
      Rcpp::_["individuals"] =
          static_cast<int>(tc_xptr->individuals.metadata_length),
      Rcpp::_["nodes"] = static_cast<int>(tc_xptr->nodes.metadata_length),
      Rcpp::_["edges"] = static_cast<int>(tc_xptr->edges.metadata_length),
      Rcpp::_["sites"] = static_cast<int>(tc_xptr->sites.metadata_length),
      Rcpp::_["mutations"] =
          static_cast<int>(tc_xptr->mutations.metadata_length));
}

// # nocov start
// This is how we would get metadata, but it will be raw bytes,
// so would have to work with schema and codes ... but see
// https://github.com/HighlanderLab/RcppTskit/issues/36
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// ts_ptr <- RcppTskit:::ts_ptr_load(ts_file)
// RcppTskit:::ts_ptr_metadata(ts_ptr)
// slendr::ts_metadata(slim_ts)
Rcpp::String ts_ptr_metadata(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  const char *p = tsk_treeseq_get_metadata(ts_xptr);
  tsk_size_t n = tsk_treeseq_get_metadata_length(ts_xptr);
  std::string metadata;
  if (n > 0 && p != NULL) {
    metadata.assign(p, p + n);
  }
  return Rcpp::String(metadata);
}
// # nocov end
