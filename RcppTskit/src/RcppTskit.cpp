#include <Rcpp.h>
#include <tskit.h>

// using namespace Rcpp; // to omit Rcpp:: prefix for whole Rcpp API
// using Rcpp::IntegerVector; // to omit Rcpp:: prefix for IntegerVector

// Finaliser to free tsk_treeseq_t when it is garbage collected
// See \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_free}
// for more details.
static void RcppTskit_treeseq_xptr_delete(tsk_treeseq_t *ptr) {
  if (ptr != NULL) {
    tsk_treeseq_free(ptr);
    delete ptr;
  }
}
// Define the external pointer type for tsk_treeseq_t with the finaliser
using RcppTskit_treeseq_xptr = Rcpp::XPtr<tsk_treeseq_t, Rcpp::PreserveStorage,
                                          RcppTskit_treeseq_xptr_delete, true>;

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

//' @title Report the version of installed tskit C API
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

//' @name ts_load_ptr
//' @title Load a tree sequence from a file
//' @param file a string specifying the full path of the tree sequence file.
//' @param options integer bitwise options (see details).
//' @details This function calls tskit C API: \code{tsk_treeseq_load()}
//'   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_load}.
//' @return \code{ts_load()} returns a \code{\link{TreeSequence}} object.
//'  \code{ts_load_ptr()} returns external pointer to tree sequence as a
//'  \code{tsk_treeseq_t} object.
//' @examples
//' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
//'
//' # TreeSequence class object
//' ts <- ts_load(ts_file)
//' is(ts)
//' ts
//' ts$num_nodes()
//'
//' # External pointer object
//' ts_ptr <- ts_load_ptr(ts_file)
//' is(ts_ptr)
//' ts_ptr
//' ts_num_nodes_ptr(ts_ptr)
//'
//' # Also
//' ts <- TreeSequence$new(file = ts_file); is(ts)
//' ts <- TreeSequence$new(pointer = ts_ptr); is(ts)
//' @export
// [[Rcpp::export]]
SEXP ts_load_ptr(const std::string file, const int options = 0) {
  // tsk_treeseq_t ts; // on stack, destroyed end of func, must free resources
  tsk_treeseq_t *ts_ptr = new tsk_treeseq_t(); // on heap, persists function
  int ret =
      tsk_treeseq_load(ts_ptr, file.c_str(), static_cast<tsk_flags_t>(options));
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

//' @name ts_dump_ptr
//' @title Write a tree sequence to a file
//' @param ts tree sequence as a \code{\link{TreeSequence}} object or
//'   an external pointer to tree sequence as a \code{tsk_treeseq_t} object.
//' @param file a string specifying the full path of the tree sequence file
//' @param options integer bitwise options (see details).
//' @details This function calls the tskit C API: \code{tsk_treeseq_dump()}
//'   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_dump}.
//' @return No return value; called for side effects.
//' @examples
//' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
//'
//' # TreeSequence class object
//' ts <- ts_load(ts_file)
//' dump_file <- tempfile()
//' ts$dump(dump_file)
//'
//' # External pointer object
//' ts_ptr <- ts$pointer
//' ts_dump_ptr(ts_ptr, dump_file)
//' \dontshow{on.exit(file.remove(dump_file)) # clean up}
//' @export
// [[Rcpp::export]]
void ts_dump_ptr(const SEXP ts, const std::string file, const int options = 0) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  int ret = tsk_treeseq_dump(ts_xptr, file.c_str(),
                             static_cast<tsk_flags_t>(options));
  if (ret != 0) {
    Rcpp::stop(tsk_strerror(ret));
  }
}

//' @describeIn ts_summary_ptr Get the number of provenances in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_provenances_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_provenances(ts_xptr));
}

//' @describeIn ts_summary_ptr Get the number of populations in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_populations_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_populations(ts_xptr));
}

//' @describeIn ts_summary_ptr Get the number of migrations in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_migrations_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_migrations(ts_xptr));
}

//' @describeIn ts_summary_ptr Get the number of individuals in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_individuals_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_individuals(ts_xptr));
}

//' @describeIn ts_summary_ptr Get the number of samples (of nodes) in a tree
//'   sequence
//' @export
// [[Rcpp::export]]
int ts_num_samples_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_samples(ts_xptr));
}

//' @describeIn ts_summary_ptr Get the number of nodes in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_nodes_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_nodes(ts_xptr));
}

//' @describeIn ts_summary_ptr Get the number of edges in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_edges_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_edges(ts_xptr));
}

//' @describeIn ts_summary_ptr Get the number of trees in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_trees_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_trees(ts_xptr));
}

//' @describeIn ts_summary_ptr Get the number of sites in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_sites_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_sites(ts_xptr));
}

//' @describeIn ts_summary_ptr Get the number of mutations in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_mutations_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return static_cast<int>(tsk_treeseq_get_num_mutations(ts_xptr));
}

//' @describeIn ts_summary_ptr Get the sequence length
//' @export
// [[Rcpp::export]]
double ts_sequence_length_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  return tsk_treeseq_get_sequence_length(ts_xptr);
}

//' @describeIn ts_summary_ptr Get the time units string
//' @export
// [[Rcpp::export]]
Rcpp::String ts_time_units_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  const char *p = tsk_treeseq_get_time_units(ts_xptr);
  tsk_size_t n = tsk_treeseq_get_time_units_length(ts_xptr);
  std::string time_units;
  if (n > 0 && p != NULL) {
    time_units.assign(p, p + n);
  }
  return Rcpp::String(time_units);
}

//' @name ts_summary_ptr
//' @title Summary of properties and number of records in a tree sequence
//' @param ts tree sequence as a \code{\link{TreeSequence}} object or
//'   an external pointer to tree sequence as a \code{tsk_treeseq_t} object.
//' @details These functions return the summary of properties and number of
//'   records in a tree sequence, by calling tskit C API:
//'   \code{tsk_treeseq_get_num_provenances()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_provenances},
//'   \code{tsk_treeseq_get_num_populations()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_populations},
//'   \code{tsk_treeseq_get_num_migrations()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_migrations},
//'   \code{tsk_treeseq_get_num_individuals()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_individuals},
//'   \code{tsk_treeseq_get_num_samples()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_samples},
//'   \code{tsk_treeseq_get_num_nodes()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_nodes},
//'   \code{tsk_treeseq_get_num_edges()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_edges},
//'   \code{tsk_treeseq_get_num_trees()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_trees},
//'   \code{tsk_treeseq_get_num_sites()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_sites},
//'   \code{tsk_treeseq_get_num_mutations()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_mutations},
//'   \code{tsk_treeseq_get_sequence_length()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_sequence_length},
//'   and
//'   \code{tsk_treeseq_get_time_units()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_time_units}.
//' @return \code{ts_summary()} and \code{ts_summary_ptr()} return
//'   a named list with the number/value for all items,
//'   while other functions \code{ts_num_x()} and \code{ts_num_x_ptr()} etc.
//'   return the number/value of each item.
//' @examples
//' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
//'
//' # TreeSequence class object
//' ts <- ts_load(ts_file)
//' ts$print()
//' ts$summary()
//' ts$num_provenances()
//' ts$num_populations()
//' ts$num_migrations()
//' ts$num_individuals()
//' ts$num_samples()
//' ts$num_nodes()
//' ts$num_edges()
//' ts$num_trees()
//' ts$num_sites()
//' ts$num_mutations()
//' ts$sequence_length()
//' ts$time_units()
//'
//' # External pointer object
//' ts_ptr <- ts$pointer
//' ts_summary_ptr(ts_ptr)
//' ts_num_provenances_ptr(ts_ptr)
//' ts_num_populations_ptr(ts_ptr)
//' ts_num_migrations_ptr(ts_ptr)
//' ts_num_individuals_ptr(ts_ptr)
//' ts_num_samples_ptr(ts_ptr)
//' ts_num_nodes_ptr(ts_ptr)
//' ts_num_edges_ptr(ts_ptr)
//' ts_num_trees_ptr(ts_ptr)
//' ts_num_sites_ptr(ts_ptr)
//' ts_num_mutations_ptr(ts_ptr)
//' ts_sequence_length_ptr(ts_ptr)
//' ts_time_units_ptr(ts_ptr)
//' @export
// [[Rcpp::export]]
Rcpp::List ts_summary_ptr(const SEXP ts) {
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
      Rcpp::_["time_units"] = ts_time_units_ptr(ts));
}

//' @name ts_metadata_length
//' @title Get the length of metadata in a tree sequence and its tables
//' @param ts tree sequence as a \code{\link{TreeSequence}} object or
//'   an external pointer to tree sequence as a \code{tsk_treeseq_t} object.
//' @details This function returns the length of metadata stored on the tree
//'   sequence and in each table by calling tskit C API:
//'   \code{tsk_treeseq_get_metadata_length()}
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_metadata_length}
//'   on tree sequence and
//'   \code{ts->tables->x->metadata_length} on each table \code{x}, e.g.,
//'\url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_population_table_t.metadata_length}.
//' @return A named list with the length of metadata.
//' @examples
//' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
//'
//' # TreeSequence class object
//' ts <- ts_load(ts_file)
//' ts$metadata_length()
//'
//' # External pointer object
//' ts_ptr <- ts$pointer
//' ts_metadata_length_ptr(ts_ptr)
//' @export
// [[Rcpp::export]]
Rcpp::List ts_metadata_length_ptr(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  const tsk_table_collection_t *tables = ts_xptr->tables;
  return Rcpp::List::create(
      Rcpp::_["ts"] =
          static_cast<int>(tsk_treeseq_get_metadata_length(ts_xptr)),
      // The tree sequence metadata is the tables collection metadata and
      // tsk_treeseq_get_metadata_length() returns self->tables->metadata_length
      // Rcpp::_["ts"] = static_cast<int>(tables->metadata_length),
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

// # nocov start
// This is how we would get metadata, but it will be raw bytes,
// so would have to work with schema and codes ... but see
// https://github.com/HighlanderLab/RcppTskit/issues/36
// ts_file <- system.file("examples/test.trees", package = "RcppTskit")
// ts_ptr <- ts_load(ts_file)
// ts_metadata_ptr(ts_ptr)
// slendr::ts_metadata(slim_ts)
Rcpp::String ts_metadata_ptr(const SEXP ts) {
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

// # nocov start
int table_collection_num_nodes_zero_check() {
  tsk_table_collection_t tables;
  int ret = tsk_table_collection_init(&tables, 0);
  if (ret != 0) {
    tsk_table_collection_free(&tables);
    Rcpp::stop(tsk_strerror(ret));
  }
  int n = static_cast<int>(tables.nodes.num_rows);
  tsk_table_collection_free(&tables);
  return n;
}
// # nocov end

// TODO: This will go into AlphaSimR
// [[Rcpp::export]]
SEXP ts_grow(SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  int ret;
  ret = 0;
  // TODO: What do we need to do here now? How do we grow a tree sequence?
  //       Look into the simple example in C code online or look into what SLiM
  //       is doing!?
  if (ret != 0) {
    // TODO: What should we do if something goes wrong? We can clearly throw an
    //       error using Rcpp::stop(), but should we also do something with the
    //       ts pointer and object? If we delete, we discard/delete past work,
    //       but if we don't, do we risk of returning a corrupted ts?
    // tsk_treeseq_free(ts_ptr);
    // delete ts_ptr;
    Rcpp::stop(tsk_strerror(ret));
  }
  return ts_xptr;
  // return ret;
}
