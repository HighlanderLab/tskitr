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
    return Rcpp::IntegerVector::create(Rcpp::_["major"] = KAS_VERSION_MAJOR,
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
    return Rcpp::IntegerVector::create(Rcpp::_["major"] = TSK_VERSION_MAJOR,
                                       Rcpp::_["minor"] = TSK_VERSION_MINOR,
                                       Rcpp::_["patch"] = TSK_VERSION_PATCH);
}

// TODO: Decide what tskit functionality we want to expose as R functions #21
//       https://github.com/HighlanderLab/tskitr/issues/21
int table_collection_num_nodes_zero_check() {
    int n, ret;
    tsk_table_collection_t tables;
    ret = tsk_table_collection_init(&tables, 0);
    if (ret != 0) {
        tsk_table_collection_free(&tables);
        Rcpp::stop(tsk_strerror(ret));
    }
    n = (int) tables.nodes.num_rows;
    tsk_table_collection_free(&tables);
    return n;
}

//' Finalizer function to free tsk_treeseq_t when it is garbage collected
//'
//' @param xptr_sexp an external pointer to a \code{tsk_treeseq_t} object.
//' @details Frees memory allocated to a \code{tsk_treeseq_t} object and deletes
//'   its pointer by calling \code{tsk_treeseq_free()} from the tskit C API.
//'   See \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_free}
//'   for more details.
void treeseq_xptr_finalize(SEXP xptr_sexp) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(xptr_sexp);
    if (xptr.get() != NULL) {
        tsk_treeseq_free(xptr.get());
        delete xptr.get();
    }
}

// TODO: Rename ts_load() to ts_load_ptr() and create ts_load() returning S3/S4 object #22
//       https://github.com/HighlanderLab/tskitr/issues/22
// TODO: What would be the best class system I should use for this?
//       R6 to get pass by reference and ts$func() semantics?
//' Load a tree sequence from a file.
//'
//' @param file a string specifying the full path of the tree sequence file.
//' @param options integer bitwise options (see details).
//' @return An external pointer to a \code{tsk_treeseq_t} object.
//' @details This function calls \code{tsk_treeseq_load()} from the tskit C API.
//'   See \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_load}
//'   for more details.
//' @examples
//' ts_file <- system.file("examples/test.trees", package = "tskitr")
//' ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
//' ts
//' is(ts)
//' ts_num_nodes(ts)
//' @export
// [[Rcpp::export]]
SEXP ts_load(std::string file, int options = 0) {
    int ret;
    tsk_treeseq_t *ts_ptr = new tsk_treeseq_t();
    ret = tsk_treeseq_load(ts_ptr, file.c_str(), static_cast<tsk_flags_t>(options));
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
//' @param ts an external pointer to a \code{tsk_treeseq_t} object.
//' @param file a string specifying the full path of the tree sequence file.
//' @param options integer bitwise options (see details).
//' @details This function calls \code{tsk_treeseq_dump()} from the tskit C API
//'   See \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_dump}
//'   for more details.
//' @examples
//' ts_file <- system.file("examples/test.trees", package = "tskitr")
//' ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
//' ts
//' dump_file <- tempfile()
//' ts_dump(ts, dump_file)
//' @export
// [[Rcpp::export]]
void ts_dump(SEXP ts, std::string file, int options = 0) {
    int ret;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    ret = tsk_treeseq_dump(xptr, file.c_str(), static_cast<tsk_flags_t>(options));
    if (ret != 0) {
        Rcpp::stop(tsk_strerror(ret));
    }
}

//' @name ts_num
//' @title Get the number of records in a tree sequence
//' @details These functions return the number of various items in a tree
//'     sequence, including provenances, populations, migrations, individuals,
//'     samples, nodes, edges, trees, sites, and mutations.
//' @param ts an external pointer to a \code{tsk_treeseq_t} object.
//' @details These functions call
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
//'   and
//'   \code{tsk_treeseq_get_sequence_length()} \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_get_sequence_length}
//'   from the tskit C API. See the linked documentation for more details.
//' @return \code{ts_num} returns a named list with the numbers of each item,
//'     while \code{ts_num_x} return the number of each item. All numbers are
//'     returned as integers.
//' @examples
//' ts_file <- system.file("examples/test.trees", package = "tskitr")
//' ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
//' ts_num(ts)
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
//' @export
// [[Rcpp::export]]
Rcpp::List ts_num(SEXP ts) {
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    return Rcpp::List::create(Rcpp::_["num_provenances"] = (int) tsk_treeseq_get_num_provenances(xptr),
                              Rcpp::_["num_populations"] = (int) tsk_treeseq_get_num_populations(xptr),
                              Rcpp::_["num_migrations"] = (int) tsk_treeseq_get_num_migrations(xptr),
                              Rcpp::_["num_individuals"] = (int) tsk_treeseq_get_num_individuals(xptr),
                              Rcpp::_["num_samples"] = (int) tsk_treeseq_get_num_samples(xptr),
                              Rcpp::_["num_nodes"] = (int) tsk_treeseq_get_num_nodes(xptr),
                              Rcpp::_["num_edges"] = (int) tsk_treeseq_get_num_edges(xptr),
                              Rcpp::_["num_trees"] = (int) tsk_treeseq_get_num_trees(xptr),
                              Rcpp::_["num_sites"] = (int) tsk_treeseq_get_num_sites(xptr),
                              Rcpp::_["num_mutations"] = (int) tsk_treeseq_get_num_mutations(xptr),
                              Rcpp::_["sequence_length"] = (int) tsk_treeseq_get_sequence_length(xptr));
}

//' @describeIn ts_num Get the number of provenances in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_provenances(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_provenances(xptr);
    return n;
}

//' @describeIn ts_num Get the number of populations in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_populations(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_populations(xptr);
    return n;
}

//' @describeIn ts_num Get the number of migrations in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_migrations(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_migrations(xptr);
    return n;
}

//' @describeIn ts_num Get the number of individuals in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_individuals(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_individuals(xptr);
    return n;
}

//' @describeIn ts_num Get the number of samples in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_samples(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_samples(xptr);
    return n;
}

//' @describeIn ts_num Get the number of nodes in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_nodes(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_nodes(xptr);
    return n;
}

//' @describeIn ts_num Get the number of edges in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_edges(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_edges(xptr);
    return n;
}

//' @describeIn ts_num Get the number of trees in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_trees(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_trees(xptr);
    return n;
}

//' @describeIn ts_num Get the number of sites in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_sites(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_sites(xptr);
    return n;
}

//' @describeIn ts_num Get the number of mutations in a tree sequence
//' @export
// [[Rcpp::export]]
int ts_num_mutations(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_mutations(xptr);
    return n;
}

//' @describeIn ts_num Get the sequence length
//' @export
// [[Rcpp::export]]
double ts_sequence_length(SEXP ts) {
    double n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = tsk_treeseq_get_sequence_length(xptr);
    return n;
}
