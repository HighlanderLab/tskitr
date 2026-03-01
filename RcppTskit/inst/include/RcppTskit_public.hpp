#ifndef RCPPTSKIT_PUBLIC_H
#define RCPPTSKIT_PUBLIC_H

#include <Rcpp.h>

// PUBLIC functions (in order as in the .cpp files)
// Sync the defaults between the .cpp files and declarations below!

// RcppTskit.cpp
Rcpp::IntegerVector kastore_version();
Rcpp::IntegerVector tskit_version();

// sync default options with .cpp!
SEXP ts_xptr_load(std::string file, int options = 0);
SEXP tc_xptr_load(std::string file, int options = 0);
void ts_xptr_dump(SEXP ts, std::string file, int options = 0);
void tc_xptr_dump(SEXP tc, std::string file, int options = 0);
SEXP ts_xptr_to_tc_xptr(SEXP ts, int options = 0);
SEXP tc_xptr_to_ts_xptr(SEXP tc, int options = 0);

int ts_xptr_num_provenances(SEXP ts);
int ts_xptr_num_populations(SEXP ts);
int ts_xptr_num_migrations(SEXP ts);
int ts_xptr_num_individuals(SEXP ts);
int ts_xptr_num_samples(SEXP ts);
int ts_xptr_num_nodes(SEXP ts);
int ts_xptr_num_edges(SEXP ts);
int ts_xptr_num_trees(SEXP ts);
int ts_xptr_num_sites(SEXP ts);
int ts_xptr_num_mutations(SEXP ts);
double ts_xptr_sequence_length(SEXP ts);
bool ts_xptr_discrete_genome(SEXP ts);
bool ts_xptr_has_reference_sequence(SEXP ts);
Rcpp::String ts_xptr_time_units(SEXP ts);
bool ts_xptr_discrete_time(SEXP ts);
double ts_xptr_min_time(SEXP ts);
double ts_xptr_max_time(SEXP ts);
Rcpp::String ts_xptr_file_uuid(SEXP ts);
Rcpp::List ts_xptr_summary(SEXP ts);
Rcpp::List ts_xptr_metadata_length(SEXP ts);

double tc_xptr_sequence_length(SEXP tc);
bool tc_xptr_has_reference_sequence(SEXP tc);
Rcpp::String tc_xptr_time_units(SEXP tc);
Rcpp::String tc_xptr_file_uuid(SEXP tc);
bool tc_xptr_has_index(SEXP tc);
Rcpp::List tc_xptr_summary(SEXP tc);
Rcpp::List tc_xptr_metadata_length(SEXP tc);

#endif
