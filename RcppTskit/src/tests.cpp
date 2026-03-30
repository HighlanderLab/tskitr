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
//   \code{rtsk_table_collection_build_index}
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

// TEST-ONLY
// @title Force tskit-level error path in \code{rtsk_individual_table_add_row}
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @return No return value; called for side effects - testing.
// [[Rcpp::export]]
void test_rtsk_individual_table_add_row_forced_error(const SEXP tc) {
  rtsk_table_collection_t tc_xptr(tc);
  tsk_individual_table_t &individuals = tc_xptr->individuals;
  tsk_size_t saved_max_rows = individuals.max_rows;
  tsk_size_t saved_max_rows_increment = individuals.max_rows_increment;
  individuals.max_rows = 1;
  individuals.max_rows_increment = static_cast<tsk_size_t>(TSK_MAX_ID) + 1;
  try {
    (void)rtsk_individual_table_add_row(tc);
    // Lines below not hit by tests because rtsk_individual_table_add_row()
    // throws error # nocov start
    individuals.max_rows = saved_max_rows;
    individuals.max_rows_increment = saved_max_rows_increment;
    return;
    // # nocov end
  } catch (...) {
    individuals.max_rows = saved_max_rows;
    individuals.max_rows_increment = saved_max_rows_increment;
    throw;
  }
}

// TEST-ONLY
// @title Force tskit-level error path in \code{rtsk_node_table_add_row}
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @return No return value; called for side effects - testing.
// [[Rcpp::export]]
void test_rtsk_node_table_add_row_forced_error(const SEXP tc) {
  rtsk_table_collection_t tc_xptr(tc);
  tsk_node_table_t &nodes = tc_xptr->nodes;
  tsk_size_t saved_max_rows = nodes.max_rows;
  tsk_size_t saved_max_rows_increment = nodes.max_rows_increment;
  nodes.max_rows = 1;
  nodes.max_rows_increment = static_cast<tsk_size_t>(TSK_MAX_ID) + 1;
  try {
    (void)rtsk_node_table_add_row(tc);
    // Lines below not hit by tests because rtsk_node_table_add_row()
    // throws error # nocov start
    nodes.max_rows = saved_max_rows;
    nodes.max_rows_increment = saved_max_rows_increment;
    return;
    // # nocov end
  } catch (...) {
    nodes.max_rows = saved_max_rows;
    nodes.max_rows_increment = saved_max_rows_increment;
    throw;
  }
}

// TEST-ONLY
// @title Force tskit-level error path in \code{rtsk_edge_table_add_row}
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @return No return value; called for side effects - testing.
// [[Rcpp::export]]
void test_rtsk_edge_table_add_row_forced_error(const SEXP tc) {
  rtsk_table_collection_t tc_xptr(tc);
  tsk_edge_table_t &edges = tc_xptr->edges;
  tsk_size_t saved_max_rows = edges.max_rows;
  tsk_size_t saved_max_rows_increment = edges.max_rows_increment;
  edges.max_rows = 1;
  edges.max_rows_increment = static_cast<tsk_size_t>(TSK_MAX_ID) + 1;
  try {
    (void)rtsk_edge_table_add_row(tc, 0, 1, static_cast<int>(edges.parent[0]),
                                  static_cast<int>(edges.child[0]), R_NilValue);
    // Lines below not hit by tests because rtsk_edge_table_add_row()
    // throws error # nocov start
    edges.max_rows = saved_max_rows;
    edges.max_rows_increment = saved_max_rows_increment;
    return;
    // # nocov end
  } catch (...) {
    edges.max_rows = saved_max_rows;
    edges.max_rows_increment = saved_max_rows_increment;
    throw;
  }
}

// TEST-ONLY
// @title Force tskit-level error path in \\code{rtsk_site_table_add_row}
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @return No return value; called for side effects - testing.
// [[Rcpp::export]]
void test_rtsk_site_table_add_row_forced_error(const SEXP tc) {
  rtsk_table_collection_t tc_xptr(tc);
  tsk_site_table_t &sites = tc_xptr->sites;
  tsk_size_t saved_max_rows = sites.max_rows;
  tsk_size_t saved_max_rows_increment = sites.max_rows_increment;
  sites.max_rows = 1;
  sites.max_rows_increment = static_cast<tsk_size_t>(TSK_MAX_ID) + 1;
  const Rcpp::RawVector ancestral_state = Rcpp::RawVector::create('A');
  try {
    (void)rtsk_site_table_add_row(tc, 0.5, ancestral_state, R_NilValue);
    // Lines below not hit by tests because rtsk_site_table_add_row()
    // throws error # nocov start
    sites.max_rows = saved_max_rows;
    sites.max_rows_increment = saved_max_rows_increment;
    return;
    // # nocov end
  } catch (...) {
    sites.max_rows = saved_max_rows;
    sites.max_rows_increment = saved_max_rows_increment;
    throw;
  }
}

// TEST-ONLY
// @title Force tskit-level error path in \\code{rtsk_mutation_table_add_row}
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @return No return value; called for side effects - testing.
// [[Rcpp::export]]
void test_rtsk_mutation_table_add_row_forced_error(const SEXP tc) {
  rtsk_table_collection_t tc_xptr(tc);
  tsk_mutation_table_t &mutations = tc_xptr->mutations;
  tsk_size_t saved_max_rows = mutations.max_rows;
  tsk_size_t saved_max_rows_increment = mutations.max_rows_increment;
  mutations.max_rows = 1;
  mutations.max_rows_increment = static_cast<tsk_size_t>(TSK_MAX_ID) + 1;
  const tsk_id_t site =
      mutations.num_rows > 0 ? mutations.site[0] : static_cast<tsk_id_t>(0);
  const tsk_id_t node =
      mutations.num_rows > 0 ? mutations.node[0] : static_cast<tsk_id_t>(0);
  const Rcpp::RawVector derived_state = Rcpp::RawVector::create('T');
  try {
    (void)rtsk_mutation_table_add_row(
        tc, static_cast<int>(site), static_cast<int>(node), -1,
        TSK_UNKNOWN_TIME, derived_state, R_NilValue);
    // Lines below not hit by tests because rtsk_mutation_table_add_row()
    // throws error # nocov start
    mutations.max_rows = saved_max_rows;
    mutations.max_rows_increment = saved_max_rows_increment;
    return;
    // # nocov end
  } catch (...) {
    mutations.max_rows = saved_max_rows;
    mutations.max_rows_increment = saved_max_rows_increment;
    throw;
  }
}
