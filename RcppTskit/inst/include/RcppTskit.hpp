#ifndef RCPPTSKIT_H
#define RCPPTSKIT_H

#include <Rcpp.h>
#include <tskit.h>

// Finaliser that frees tsk_treeseq_t when it is garbage collected
// See \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_free}
// for more details.
static void rtsk_treeseq_free(tsk_treeseq_t *ptr) {
  if (ptr != NULL) {
    tsk_treeseq_free(ptr);
    delete ptr;
  }
}

// Finaliser that frees tsk_table_collection_t when it is garbage collected
// See
// \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_table_collection_free}
// for more details.
static void rtsk_table_collection_free(tsk_table_collection_t *ptr) {
  if (ptr != NULL) {
    tsk_table_collection_free(ptr);
    delete ptr;
  }
}

// Define the external pointer type for tsk_treeseq_t with its finaliser
using rtsk_treeseq_t =
    Rcpp::XPtr<tsk_treeseq_t, Rcpp::PreserveStorage, rtsk_treeseq_free, true>;

// Define the external pointer type for tsk_table_collection_t with its
// finaliser
using rtsk_table_collection_t =
    Rcpp::XPtr<tsk_table_collection_t, Rcpp::PreserveStorage,
               rtsk_table_collection_free, true>;

// Package implementation files define RCPPTSKIT_IMPL to avoid pulling
// PUBLIC declarations with default args into the same translation unit
#ifndef RCPPTSKIT_IMPL
#include "RcppTskit_public.hpp"
#endif

#endif
