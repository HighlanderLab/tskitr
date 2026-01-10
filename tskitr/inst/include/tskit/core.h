// Shim header to use tskit C API in Rcpp code in an R session or an R package
#include <tskit/tskit/core.h>

// Redefinition of tsk_bug_assert to avoid aborting R sessions with tskit C API
// (following R extensions manual recommendations).
// While tsk_bug_assert is called only in C API (atm) we provide both C and C++
// macros for completeness.
// TODO: Redefine TSK_BUG_ASSERT_MESSAGE or create tskitr version if we will use
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
