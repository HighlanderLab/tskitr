#ifndef RCPPTSKIT_PUBLIC_H
#define RCPPTSKIT_PUBLIC_H

#include <Rcpp.h>

// PUBLIC functions (in order as in the .cpp files)
// Sync the defaults between the .cpp files and declarations below!

// RcppTskit.cpp
Rcpp::IntegerVector kastore_version();
Rcpp::IntegerVector tskit_version();

// sync default options with .cpp!
SEXP rtsk_treeseq_load(std::string &filename, int options = 0);
SEXP rtsk_table_collection_load(std::string &filename, int options = 0);
void rtsk_treeseq_dump(SEXP ts, std::string &filename, int options = 0);
void rtsk_table_collection_dump(SEXP tc, std::string &filename,
                                int options = 0);
SEXP rtsk_treeseq_copy_tables(SEXP ts, int options = 0);
SEXP rtsk_treeseq_init(SEXP tc, int options = 0);

SEXP rtsk_treeseq_get_num_provenances(SEXP ts);
SEXP rtsk_treeseq_get_num_populations(SEXP ts);
SEXP rtsk_treeseq_get_num_migrations(SEXP ts);
SEXP rtsk_treeseq_get_num_individuals(SEXP ts);
SEXP rtsk_treeseq_get_num_samples(SEXP ts);
SEXP rtsk_treeseq_get_num_nodes(SEXP ts);
SEXP rtsk_treeseq_get_num_edges(SEXP ts);
SEXP rtsk_treeseq_get_num_trees(SEXP ts);
SEXP rtsk_treeseq_get_num_sites(SEXP ts);
SEXP rtsk_treeseq_get_num_mutations(SEXP ts);
double rtsk_treeseq_get_sequence_length(SEXP ts);
bool rtsk_treeseq_get_discrete_genome(SEXP ts);
bool rtsk_treeseq_has_reference_sequence(SEXP ts);
Rcpp::String rtsk_treeseq_get_time_units(SEXP ts);
bool rtsk_treeseq_get_discrete_time(SEXP ts);
double rtsk_treeseq_get_min_time(SEXP ts);
double rtsk_treeseq_get_max_time(SEXP ts);
Rcpp::String rtsk_treeseq_get_file_uuid(SEXP ts);
Rcpp::List rtsk_treeseq_summary(SEXP ts);
Rcpp::List rtsk_treeseq_metadata_length(SEXP ts);

SEXP rtsk_table_collection_get_num_provenances(SEXP tc);
SEXP rtsk_table_collection_get_num_populations(SEXP tc);
SEXP rtsk_table_collection_get_num_migrations(SEXP tc);
SEXP rtsk_table_collection_get_num_individuals(SEXP tc);
SEXP rtsk_table_collection_get_num_nodes(SEXP tc);
SEXP rtsk_table_collection_get_num_edges(SEXP tc);
SEXP rtsk_table_collection_get_num_sites(SEXP tc);
SEXP rtsk_table_collection_get_num_mutations(SEXP tc);
double rtsk_table_collection_get_sequence_length(SEXP tc);
bool rtsk_table_collection_has_reference_sequence(SEXP tc);
Rcpp::String rtsk_table_collection_get_time_units(SEXP tc);
Rcpp::String rtsk_table_collection_get_file_uuid(SEXP tc);
bool rtsk_table_collection_has_index(SEXP tc, int options = 0);
void rtsk_table_collection_build_index(SEXP tc, int options = 0);
void rtsk_table_collection_drop_index(SEXP tc, int options = 0);
Rcpp::List rtsk_table_collection_summary(SEXP tc);
Rcpp::List rtsk_table_collection_metadata_length(SEXP tc);
int rtsk_individual_table_add_row(
    SEXP tc, int flags = 0,
    Rcpp::Nullable<Rcpp::NumericVector> location = R_NilValue,
    Rcpp::Nullable<Rcpp::IntegerVector> parents = R_NilValue,
    Rcpp::Nullable<Rcpp::RawVector> metadata = R_NilValue);
int rtsk_node_table_add_row(
    SEXP tc, int flags = 0, double time = 0, int population = -1,
    int individual = -1, Rcpp::Nullable<Rcpp::RawVector> metadata = R_NilValue);
int rtsk_edge_table_add_row(
    SEXP tc, double left, double right, int parent, int child,
    Rcpp::Nullable<Rcpp::RawVector> metadata = R_NilValue);

#endif
