#include <Rcpp.h>
#include <tskit/core.h>

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
