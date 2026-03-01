#include <Rcpp.h>
#include <RcppTskit.hpp>
#include <tskit/core.h>

// ----------------------------------------------------------------------------

extern "C" void RcppTskit_bug_assert_c(void);

// TEST-ONLY
// [[Rcpp::export]]
void test_tsk_bug_assert_c() { RcppTskit_bug_assert_c(); }

// TEST-ONLY
// [[Rcpp::export]]
void test_tsk_bug_assert_cpp() { tsk_bug_assert(0); }

extern "C" void RcppTskit_trace_error_c(void);

// TEST-ONLY
// This is tested if we compile with -DTSK_TRACE_ERRORS
// [[Rcpp::export]]
void test_tsk_trace_error_c() { RcppTskit_trace_error_c(); } // # nocov

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

// Declarations for wrappers implemented in RcppTskit.cpp.
SEXP ts_xptr_to_tc_xptr(const SEXP ts, const int options);
SEXP tc_xptr_to_ts_xptr(const SEXP tc, const int options);

// TEST-ONLY
// @title Force tskit-level error path in \code{ts_xptr_to_tc_xptr}
// @param ts an external pointer to tree sequence as a \code{tsk_treeseq_t}
//   object.
// @return No return value; called for side effects - testing.
// [[Rcpp::export]]
SEXP test_ts_xptr_to_tc_xptr_forced_error(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  tsk_node_table_t &nodes = ts_xptr->tables->nodes;
  tsk_flags_t *saved_flags = nodes.flags;
  double *saved_time = nodes.time;
  nodes.flags = NULL;
  nodes.time = NULL;
  try {
    SEXP ret = ts_xptr_to_tc_xptr(ts, 0);
    // Lines below not hit by tests because ts_xptr_to_tc_xptr() throws error
    // # nocov start
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
// @title Force tskit-level error path in \code{tc_xptr_to_ts_xptr}
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @return No return value; called for side effects - testing.
// [[Rcpp::export]]
SEXP test_tc_xptr_to_ts_xptr_forced_error(const SEXP tc) {
  RcppTskit_table_collection_xptr tc_xptr(tc);
  tsk_node_table_t &nodes = tc_xptr->nodes;
  tsk_flags_t *saved_flags = nodes.flags;
  double *saved_time = nodes.time;
  nodes.flags = NULL;
  nodes.time = NULL;
  try {
    SEXP ret = tc_xptr_to_ts_xptr(tc, 0);
    // Lines below not hit by tests because ts_xptr_to_tc_xptr() throws error
    // # nocov start
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
