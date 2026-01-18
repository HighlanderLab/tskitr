#include <Rcpp.h>
#include <tskit/core.h>

extern "C" void tskitr_bug_assert_c(void);

// [[Rcpp::export]]
void test_tsk_bug_assert_c() { tskitr_bug_assert_c(); }

// [[Rcpp::export]]
void test_tsk_bug_assert_cpp() { tsk_bug_assert(0); }

extern "C" void tskitr_trace_error_c(void);

// This is tested if we compile with -DTSK_TRACE_ERRORS
// [[Rcpp::export]]
void test_tsk_trace_error_c() { tskitr_trace_error_c(); } // # nocov

// This is tested if we compile with -DTSK_TRACE_ERRORS
// [[Rcpp::export]]
void test_tsk_trace_error_cpp() { (void)tsk_trace_error(-1); } // # nocov
