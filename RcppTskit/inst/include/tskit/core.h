#ifndef RCPPTSKIT_TSKIT_CORE_H
#define RCPPTSKIT_TSKIT_CORE_H

// Shim header to use tskit C API in Rcpp code in an R session or an R package
#include <tskit/tskit/core.h>

// Redefinition of tsk_bug_assert to avoid aborting R sessions with tskit C API
// (see R extensions manual).
// While tsk_bug_assert is called only in C API (atm) we provide both C and C++
// macros for completeness.
// TODO: Redefine TSK_BUG_ASSERT_MESSAGE or create RcppTskit version if we will
// use
//       tsk_bug_assert in Rcpp. Will not, yet, open GitHub issue at this stage.
#undef tsk_bug_assert
#ifdef __cplusplus
#include <Rcpp.h>
#define tsk_bug_assert(condition)                                              \
  do {                                                                         \
    if (!(condition)) {                                                        \
      Rcpp::stop("Bug detected in %s at line %d. %s", __FILE__, __LINE__,      \
                 TSK_BUG_ASSERT_MESSAGE);                                      \
    }                                                                          \
  } while (0)
#else
#include <R_ext/Error.h>
#define tsk_bug_assert(condition)                                              \
  do {                                                                         \
    if (!(condition)) {                                                        \
      Rf_error("Bug detected in %s at line %d. %s", __FILE__, __LINE__,        \
               TSK_BUG_ASSERT_MESSAGE);                                        \
    }                                                                          \
  } while (0)
#endif

// Redefinition of tsk_trace_error to avoid writing to stderr from tskit C API
// (see R extensions manual).
// While tsk_trace_error is called only in C API (atm) we provide both C and C++
// macros for completeness.
#undef tsk_trace_error
#ifdef TSK_TRACE_ERRORS
#ifdef __cplusplus
static inline int _rtsk_trace_error_cpp(int err, int line,
                                        const char *file) {
  Rcpp::warning("tskit-trace-error: %d='%s' at line %d in %s\n", err,
                tsk_strerror(err), line, file);
  return err;
}
#define tsk_trace_error(err)                                                   \
  (_rtsk_trace_error_cpp((err), __LINE__, __FILE__))
#else
static inline int _rtsk_trace_error_c(int err, int line,
                                      const char *file) {
  Rf_warning("tskit-trace-error: %d='%s' at line %d in %s\n", err,
             tsk_strerror(err), line, file);
  return err;
}
#define tsk_trace_error(err)                                                   \
  (_rtsk_trace_error_c((err), __LINE__, __FILE__))
#endif
#else
#define tsk_trace_error(err) (err)
#endif

// Discard tskit debug output to avoid using stdout, as it is not captured by R.
// (see R extensions manual).
#if defined(_WIN32)
#define RCPPTSKIT_NULL_DEVICE "NUL"
#else
#define RCPPTSKIT_NULL_DEVICE "/dev/null"
#endif

static inline FILE *rcpptskit_default_debug_stream(void) {
  return fopen(RCPPTSKIT_NULL_DEVICE, "w");
}

#undef TSK_DEFAULT_DEBUG_STREAM
#define TSK_DEFAULT_DEBUG_STREAM rcpptskit_default_debug_stream()

#endif // RCPPTSKIT_TSKIT_CORE_H
