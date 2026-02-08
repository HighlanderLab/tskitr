#ifndef RCPPTSKIT_H
#define RCPPTSKIT_H

#include <Rcpp.h>
#include <tskit.h>

// Finaliser that frees tsk_treeseq_t when it is garbage collected
// See \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_free}
// for more details.
static void RcppTskit_treeseq_xptr_delete(tsk_treeseq_t *ptr) {
  if (ptr != NULL) {
    tsk_treeseq_free(ptr);
    delete ptr;
  }
}

// Finaliser that frees tsk_table_collection_t when it is garbage collected
// See
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_table_collection_free}
// for more details.
static void
RcppTskit_table_collection_xptr_delete(tsk_table_collection_t *ptr) {
  if (ptr != NULL) {
    tsk_table_collection_free(ptr);
    delete ptr;
  }
}

// Define the external pointer type for tsk_treeseq_t with its finaliser
using RcppTskit_treeseq_xptr = Rcpp::XPtr<tsk_treeseq_t, Rcpp::PreserveStorage,
                                          RcppTskit_treeseq_xptr_delete, true>;

// Define the external pointer type for tsk_table_collection_t with its
// finaliser
using RcppTskit_table_collection_xptr =
    Rcpp::XPtr<tsk_table_collection_t, Rcpp::PreserveStorage,
               RcppTskit_table_collection_xptr_delete, true>;

#endif
