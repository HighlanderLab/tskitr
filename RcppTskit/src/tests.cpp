#include <Rcpp.h>
#include <RcppTskit.hpp>
#include <tskit/core.h>

// ----------------------------------------------------------------------------

extern "C" void RcppTskit_bug_assert_c(void);

// [[Rcpp::export]]
void test_tsk_bug_assert_c() { RcppTskit_bug_assert_c(); }

// [[Rcpp::export]]
void test_tsk_bug_assert_cpp() { tsk_bug_assert(0); }

extern "C" void RcppTskit_trace_error_c(void);

// This is tested if we compile with -DTSK_TRACE_ERRORS
// [[Rcpp::export]]
void test_tsk_trace_error_c() { RcppTskit_trace_error_c(); } // # nocov

// This is tested if we compile with -DTSK_TRACE_ERRORS
// [[Rcpp::export]]
void test_tsk_trace_error_cpp() { (void)tsk_trace_error(-1); } // # nocov

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
SEXP ts_ptr_to_tc_ptr(const SEXP ts, const int options);
SEXP tc_ptr_to_ts_ptr(const SEXP tc, const int options);

// @title Force tskit-level error path in \code{ts_ptr_to_tc_ptr}
// @param ts an external pointer to tree sequence as a \code{tsk_treeseq_t}
//   object.
// @return No return value; called for side effects - testing.
// [[Rcpp::export]]
SEXP test_ts_ptr_to_tc_ptr_forced_error(const SEXP ts) {
  RcppTskit_treeseq_xptr ts_xptr(ts);
  tsk_node_table_t &nodes = ts_xptr->tables->nodes;
  tsk_flags_t *saved_flags = nodes.flags;
  double *saved_time = nodes.time;
  nodes.flags = NULL;
  nodes.time = NULL;
  try {
    SEXP ret = ts_ptr_to_tc_ptr(ts, 0);
    // Lines below not hit by tests because ts_ptr_to_tc_ptr() throws error
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

// @title Force tskit-level error path in \code{tc_ptr_to_ts_ptr}
// @param tc an external pointer to table collection as a
//   \code{tsk_table_collection_t} object.
// @return No return value; called for side effects - testing.
// [[Rcpp::export]]
SEXP test_tc_ptr_to_ts_ptr_forced_error(const SEXP tc) {
  RcppTskit_table_collection_xptr tc_xptr(tc);
  tsk_node_table_t &nodes = tc_xptr->nodes;
  tsk_flags_t *saved_flags = nodes.flags;
  double *saved_time = nodes.time;
  nodes.flags = NULL;
  nodes.time = NULL;
  try {
    SEXP ret = tc_ptr_to_ts_ptr(tc, 0);
    // Lines below not hit by tests because ts_ptr_to_tc_ptr() throws error
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
