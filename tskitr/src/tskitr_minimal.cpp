#include <Rcpp.h>
#include <tskit.h>

// using namespace Rcpp; // to omit Rcpp:: prefix for whole Rcpp API
// using Rcpp::IntegerVector; // to omit Rcpp:: prefix for IntegerVector

//' Report the version of installed kastore C API
//'
//' @details The version is stored in the installed header \code{kastore.h}.
//' @return A named vector with three elements \code{major}, \code{minor}, and
//'     \code{patch}.
//' @examples
//' kastore_version()
//' @export
// [[Rcpp::export]]
Rcpp::IntegerVector kastore_version() {
    // Rcpp::_["major"] is shorthand for Rcpp::Named("major")
    return Rcpp::IntegerVector::create(
        Rcpp::_["major"] = KAS_VERSION_MAJOR,
        Rcpp::_["minor"] = KAS_VERSION_MINOR,
        Rcpp::_["patch"] = KAS_VERSION_PATCH);
}

//' Report the version of installed tskit C API
//'
//' @details The version is defined in the installed header \code{tskit/core.h}.
//' @return A named vector with three elements \code{major}, \code{minor}, and
//'     \code{patch}.
//' @examples
//' tskit_version()
//' @export
// [[Rcpp::export]]
Rcpp::IntegerVector tskit_version() {
    return Rcpp::IntegerVector::create(
        Rcpp::_["major"] = TSK_VERSION_MAJOR,
        Rcpp::_["minor"] = TSK_VERSION_MINOR,
        Rcpp::_["patch"] = TSK_VERSION_PATCH);
}

// TODO: Decide what tskit functionality we want to expose as R functions #21
//       https://github.com/HighlanderLab/tskitr/issues/21
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

// Finaliser function to free tsk_treeseq_t when it is garbage collected
//
// @param xptr_sexp tree sequence as an external pointer to a \code{tsk_treeseq_t} object.
// @details Frees memory allocated to a \code{tsk_treeseq_t} object and deletes
//   its pointer by calling \code{tsk_treeseq_free()} from the tskit C API.
//   See \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_free}
//   for more details.
void treeseq_xptr_finalize(SEXP xptr_sexp) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(xptr_sexp);
    if (xptr.get() != NULL) {
        tsk_treeseq_free(xptr.get());
        delete xptr.get();
    }
}

// TODO: Rename ts_load() to ts_load_ptr() and create ts_load() returning S3/S4/R6/... object #22
//       https://github.com/HighlanderLab/tskitr/issues/22
// TODO: What would be the best class system I should use for this?
//       R6 to get pass by reference and ts$func() semantics?
//' Load a tree sequence from a file.
//'
//' @param file a string specifying the full path of the tree sequence file.
//' @param options integer bitwise options (see details).
//' @details This function calls \code{tsk_treeseq_load()} from the tskit C API.
//'   See \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_load}
//'   for more details.
//' @return Tree sequence as an external pointer to a \code{tsk_treeseq_t} object.
//' @examples
//' ts_file <- system.file("examples/test.trees", package = "tskitr")
//' ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
//' ts
//' is(ts)
//' ts_num_nodes(ts)
//' @export
// [[Rcpp::export]]
SEXP ts_load(std::string file, int options = 0) {
    tsk_treeseq_t *ts_ptr = new tsk_treeseq_t();
    int ret = tsk_treeseq_load(ts_ptr, file.c_str(), static_cast<tsk_flags_t>(options));
    if (ret != 0) {
        tsk_treeseq_free(ts_ptr);
        delete ts_ptr;
        Rcpp::stop(tsk_strerror(ret));
    }
    // Rcpp::XPtr<tsk_treeseq_t> xptr(ts_ptr, true);
    // true => delete ts_ptr on garbage collection (GC),
    // but note that GC will not call tsk_treeseq_free(),
    // which is why we need R_RegisterCFinalizerEx() below
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts_ptr, false);
    R_RegisterCFinalizerEx(xptr, treeseq_xptr_finalize, TRUE);
    return xptr;
}

//' Write a tree sequence to file.
//'
//' @param ts tree sequence as an external pointer to a \code{tsk_treeseq_t} object.
//' @param file a string specifying the full path of the tree sequence file.
//' @param options integer bitwise options (see details).
//' @details This function calls \code{tsk_treeseq_dump()} from the tskit C API
//'   See \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_dump}
//'   for more details.
//' @return No return value, called for side effects.
//' @examples
//' ts_file <- system.file("examples/test.trees", package = "tskitr")
//' ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
//' ts
//' dump_file <- tempfile()
//' ts_dump(ts, dump_file)
//' @export
// [[Rcpp::export]]
void ts_dump(SEXP ts, std::string file, int options = 0) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    int ret = tsk_treeseq_dump(xptr, file.c_str(), static_cast<tsk_flags_t>(options));
    if (ret != 0) {
        Rcpp::stop(tsk_strerror(ret));
    }
}

//' @name ts_summary
//' @title Get the summary of properties and number of records in a tree sequence
//' @param ts tree sequence as an external pointer to a \code{tsk_treeseq_t} object.
//' @details These functions return the summary of properties and number of records
//'   in a tree sequence, by calling
//'   \code{tsk_treeseq_get_num_provenances()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_provenances},
//'   \code{tsk_treeseq_get_num_populations()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_populations},
//'   \code{tsk_treeseq_get_num_migrations()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_migrations},
//'   \code{tsk_treeseq_get_num_individuals()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_individuals},
//'   \code{tsk_treeseq_get_num_samples()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_samples},
//'   \code{tsk_treeseq_get_num_nodes()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_nodes},
//'   \code{tsk_treeseq_get_num_edges()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_edges},
//'   \code{tsk_treeseq_get_num_trees()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_trees},
//'   \code{tsk_treeseq_get_num_sites()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_sites},
//'   \code{tsk_treeseq_get_num_mutations()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_num_mutations},
//'   \code{tsk_treeseq_get_sequence_length()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_sequence_length},
//'   and
//'   \code{tsk_treeseq_get_time_units()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_time_units}.
//'   from the tskit C API. See the linked documentation for more details.
//' @return \code{ts_summary} returns a named list with the number/value for all items,
//'     while other functions \code{ts_num_x} etc. return the number/value of each item.
//' @examples
//' ts_file <- system.file("examples/test.trees", package = "tskitr")
//' ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
//' ts_summary(ts)
//' ts_num_provenances(ts)
//' ts_num_populations(ts)
//' ts_num_migrations(ts)
//' ts_num_individuals(ts)
//' ts_num_samples(ts)
//' ts_num_nodes(ts)
//' ts_num_edges(ts)
//' ts_num_trees(ts)
//' ts_num_sites(ts)
//' ts_num_mutations(ts)
//' ts_sequence_length(ts)
//' ts_time_units(ts)
//' @export
// [[Rcpp::export]]
Rcpp::List ts_summary(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return Rcpp::List::create(
        Rcpp::_["num_provenances"] = tsk_treeseq_get_num_provenances(xptr),
        Rcpp::_["num_populations"] = tsk_treeseq_get_num_populations(xptr),
        Rcpp::_["num_migrations"] = tsk_treeseq_get_num_migrations(xptr),
        Rcpp::_["num_individuals"] = tsk_treeseq_get_num_individuals(xptr),
        Rcpp::_["num_samples"] = tsk_treeseq_get_num_samples(xptr),
        Rcpp::_["num_nodes"] = tsk_treeseq_get_num_nodes(xptr),
        Rcpp::_["num_edges"] = tsk_treeseq_get_num_edges(xptr),
        Rcpp::_["num_trees"] = tsk_treeseq_get_num_trees(xptr),
        Rcpp::_["num_sites"] = tsk_treeseq_get_num_sites(xptr),
        Rcpp::_["num_mutations"] = tsk_treeseq_get_num_mutations(xptr),
        Rcpp::_["sequence_length"] = tsk_treeseq_get_sequence_length(xptr),
        Rcpp::_["time_units"] = tsk_treeseq_get_time_units(xptr));
}

//' @describeIn ts_summary Get the number of provenances in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_provenances(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return static_cast<int>(tsk_treeseq_get_num_provenances(xptr));
}

//' @describeIn ts_summary Get the number of populations in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_populations(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return static_cast<int>(tsk_treeseq_get_num_populations(xptr));
}

//' @describeIn ts_summary Get the number of migrations in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_migrations(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return static_cast<int>(tsk_treeseq_get_num_migrations(xptr));
}

//' @describeIn ts_summary Get the number of individuals in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_individuals(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return static_cast<int>(tsk_treeseq_get_num_individuals(xptr));
}

//' @describeIn ts_summary Get the number of samples (of nodes) in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_samples(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return static_cast<int>(tsk_treeseq_get_num_samples(xptr));
}

//' @describeIn ts_summary Get the number of nodes in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_nodes(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return static_cast<int>(tsk_treeseq_get_num_nodes(xptr));
}

//' @describeIn ts_summary Get the number of edges in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_edges(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return static_cast<int>(tsk_treeseq_get_num_edges(xptr));
}

//' @describeIn ts_summary Get the number of trees in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_trees(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return static_cast<int>(tsk_treeseq_get_num_trees(xptr));
}

//' @describeIn ts_summary Get the number of sites in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_sites(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return static_cast<int>(tsk_treeseq_get_num_sites(xptr));
}

//' @describeIn ts_summary Get the number of mutations in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_mutations(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return static_cast<int>(tsk_treeseq_get_num_mutations(xptr));
}

//' @describeIn ts_summary Get the sequence length
//' @export
// [[Rcpp::export]]
double ts_sequence_length(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return tsk_treeseq_get_sequence_length(xptr);
}

//' @describeIn ts_summary Get the time units string
//' @export
// [[Rcpp::export]]
Rcpp::String ts_time_units(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    const char *p = tsk_treeseq_get_time_units(xptr);
    tsk_size_t n = tsk_treeseq_get_time_units_length(xptr);
    return Rcpp::String(std::string(p, p + n));
}

// This is how we would get metadata, but it will be raw bytes,
// so would have to work with schema and codes ...
// ts_file <- system.file("examples/test.trees", package = "tskitr")
// ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
// ts_metadata(ts)
// slendr::ts_metadata(slim_ts)
Rcpp::String ts_metadata(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    const char *p = tsk_treeseq_get_metadata(xptr);
    tsk_size_t n = tsk_treeseq_get_metadata_length(xptr);
    return Rcpp::String(std::string(p, p + n));
}

//' @name ts_metadata_length
//' @title Get the length of metadata in a tree sequence and its tables
//' @param ts tree sequence as an external pointer to a \code{tsk_treeseq_t} object.
//' @details This function returns the length of metadata stored on the tree
//'   sequence and in each table by calling
//'   \code{tsk_treeseq_get_metadata_length()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_metadata_length} on tree sequence and
//    \code{ts->tables->x->metadata_length} on each table \code{x}, e.g., \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_population_table_t.metadata_length},
//'   from the tskit C API. See the linked documentation for more details.
//' @return A named list with the length of metadata.
//' @examples
//' ts_file <- system.file("examples/test.trees", package = "tskitr")
//' ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
//' ts_metadata_length(ts)
//' @export
// [[Rcpp::export]]
Rcpp::List ts_metadata_length(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    const tsk_table_collection_t *tables = xptr->tables;
    return Rcpp::List::create(
        Rcpp::_["ts"] = static_cast<int>(tsk_treeseq_get_metadata_length(xptr)),
        // The tables metadata is just the tree sequence metadata since
        // tsk_treeseq_get_metadata_length() returns self->tables->metadata_length
        // Rcpp::_["tables"] = static_cast<int>(tables->metadata_length),
        Rcpp::_["populations"] = static_cast<int>(tables->populations.metadata_length),
        Rcpp::_["migrations"] = static_cast<int>(tables->migrations.metadata_length),
        Rcpp::_["individuals"] = static_cast<int>(tables->individuals.metadata_length),
        Rcpp::_["nodes"] = static_cast<int>(tables->nodes.metadata_length),
        Rcpp::_["edges"] = static_cast<int>(tables->edges.metadata_length),
        Rcpp::_["sites"] = static_cast<int>(tables->sites.metadata_length),
        Rcpp::_["mutations"] = static_cast<int>(tables->mutations.metadata_length));
}
