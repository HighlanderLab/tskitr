#include <Rcpp.h>
#include <RcppTskit.hpp>
#include <tskit/core.h>

// ----------------------------------------------------------------------------

extern "C" void rtsk_bug_assert_c(void);

// TEST-ONLY
// [[Rcpp::export]]
void test_tsk_bug_assert_c() { rtsk_bug_assert_c(); }

// TEST-ONLY
// [[Rcpp::export]]
void test_tsk_bug_assert_cpp() { tsk_bug_assert(0); }

extern "C" void rtsk_trace_error_c(void);

// TEST-ONLY
// This is tested if we compile with -DTSK_TRACE_ERRORS
// [[Rcpp::export]]
void test_tsk_trace_error_c() { rtsk_trace_error_c(); } // # nocov

// TEST-ONLY
// This is tested if we compile with -DTSK_TRACE_ERRORS
// [[Rcpp::export]]
void test_tsk_trace_error_cpp() { (void)tsk_trace_error(-1); } // # nocov

// TEST-ONLY
// [[Rcpp::export]]
bool tsk_trace_errors_defined() {
#ifdef TSK_TRACE_ERRORS
  return true;
#else
  return false;
#endif
}

// ----------------------------------------------------------------------------

// TEST-ONLY
// @title Force tskit-level error path in \code{rtsk_treeseq_copy_tables}
// @param ts an external pointer to tree sequence as a \code{tsk_treeseq_t}
//   object.
// @return No return value; called for side effects - testing.
// [[Rcpp::export]]
SEXP test_rtsk_treeseq_copy_tables_forced_error(const SEXP ts) {
  rtsk_treeseq_t ts_xptr(ts);
  tsk_node_table_t &nodes = ts_xptr->tables->nodes;
  tsk_flags_t *saved_flags = nodes.flags;
  double *saved_time = nodes.time;
  nodes.flags = NULL;
  nodes.time = NULL;
  try {
    SEXP ret = rtsk_treeseq_copy_tables(ts, 0);
    // Lines below not hit by tests because rtsk_treeseq_copy_tables() throws
    // error # nocov start
    nodes.flags = saved_flags;
    nodes.time = saved_time;
    return ret;
    // # nocov end
  } catch (...) {
    nodes.flags = saved_flags;
    nodes.time = saved_time;
    throw;
  }
}

// TEST-ONLY
// @title Force tskit-level error path in \code{rtsk_treeseq_init}
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @return No return value; called for side effects - testing.
// [[Rcpp::export]]
SEXP test_rtsk_treeseq_init_forced_error(const SEXP tc) {
  rtsk_table_collection_t tc_xptr(tc);
  tsk_node_table_t &nodes = tc_xptr->nodes;
  tsk_flags_t *saved_flags = nodes.flags;
  double *saved_time = nodes.time;
  nodes.flags = NULL;
  nodes.time = NULL;
  try {
    SEXP ret = rtsk_treeseq_init(tc, 0);
    // Lines below not hit by tests because rtsk_treeseq_copy_tables() throws
    // error # nocov start
    nodes.flags = saved_flags;
    nodes.time = saved_time;
    return ret;
    // # nocov end
  } catch (...) {
    nodes.flags = saved_flags;
    nodes.time = saved_time;
    throw;
  }
}

// TEST-ONLY
// @title Force tskit-level error path in
// \code{rtsk_table_collection_build_index}
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @return No return value; called for side effects - testing.
// @details Note that we need at least one edge row to force
// rtsk_table_collection_build_index
//   error
// [[Rcpp::export]]
void test_rtsk_table_collection_build_index_forced_error(const SEXP tc) {
  rtsk_table_collection_t tc_xptr(tc);
  tsk_edge_table_t &edges = tc_xptr->edges;
  tsk_id_t saved_parent = edges.parent[0];
  edges.parent[0] = (tsk_id_t)tc_xptr->nodes.num_rows;
  try {
    rtsk_table_collection_build_index(tc, 0);
    // Lines below not hit by tests because rtsk_table_collection_build_index()
    // throws error # nocov start
    edges.parent[0] = saved_parent;
    return;
    // # nocov end
  } catch (...) {
    edges.parent[0] = saved_parent;
    throw;
  }
}
