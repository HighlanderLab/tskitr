#include <Rcpp.h>
#include <tskit.h>

using namespace Rcpp;

// Baby steps development to check all works well

// This one works
// [[Rcpp::export]]
List rcpp_hello_world() {
    CharacterVector x = CharacterVector::create( "foo", "bar" )  ;
    NumericVector y   = NumericVector::create( 0.0, 1.0 ) ;
    List z            = List::create( x, y ) ;
    return z ;
}

// This one works
// [[Rcpp::export]]
int tskit_version_major() {
    return TSK_VERSION_MAJOR;
}

// This one works
// [[Rcpp::export]]
int tskit_table_collection_init_ok() {
    tsk_table_collection_t tables;
    int ret = tsk_table_collection_init(&tables, 0);
    tsk_table_collection_free(&tables);
    return ret;
}

// This one works
// [[Rcpp::export]]
int tskit_table_collection_num_nodes_zero() {
    int n, ret;
    tsk_table_collection_t tables;
    ret = tsk_table_collection_init(&tables, 0);
    if (ret == 0) {
        n = (int) tables.nodes.num_rows;
    }
    tsk_table_collection_free(&tables);
    return (ret == 0) ? n : ret;
}

/*
install.packages("reticulate")
reticulate::py_require("msprime")
msprime <- reticulate::import("msprime")
ts <- msprime$sim_ancestry(80, sequence_length=1e4, recombination_rate=1e-4, random_seed=42)
ts
ts$num_nodes
ts$dump("test.trees")
tskit <- reticulate::import("tskit")
ts2 <- tskit$load("test.trees")
ts2
ts2$num_nodes
*/

// This one works
// [[Rcpp::export]]
int tskit_treeseq_num_nodes_from_file(std::string file) {
    int n, ret;
    tsk_treeseq_t ts;
    ret = tsk_treeseq_load(&ts, file.c_str(), 0);
    if (ret == 0) {
        n = (int) tsk_treeseq_get_num_nodes(&ts);
    }
    tsk_treeseq_free(&ts);
    return (ret == 0) ? n : ret;
}

/*
tskit_treeseq_num_nodes_from_file("test.trees")
*/

// This one works
// [[Rcpp::export]]
SEXP tskit_treeseq_load_xptr(std::string file) {
    tsk_treeseq_t *ts = new tsk_treeseq_t();
    int ret = tsk_treeseq_load(ts, file.c_str(), 0);
    if (ret != 0) {
        delete ts;
        Rcpp::stop(tsk_strerror(ret));
    }
    Rcpp::XPtr<tsk_treeseq_t> xp(ts, true); // true => delete on GC
    return xp;
}

// This one works
// [[Rcpp::export]]
int tskit_treeseq_num_nodes(SEXP xp) {
    Rcpp::XPtr<tsk_treeseq_t> ts(xp);
    return (int) tsk_treeseq_get_num_nodes(ts);
}

/*
ts <- tskit_treeseq_load_xptr("test.trees")
ts
is(ts)
tskit_treeseq_num_nodes(ts)
n <- tskit_treeseq_num_nodes(ts)
n
is(n)
*/
