#ifndef RCPPTSKIT_PUBLIC_H
#define RCPPTSKIT_PUBLIC_H

#include <Rcpp.h>

// PUBLIC functions (in order as in the .cpp files)
// Sync the defaults between the .cpp files and declarations below!

// RcppTskit.cpp
Rcpp::IntegerVector kastore_version();
Rcpp::IntegerVector tskit_version();
int rtsk_const_tsk_no_check_integrity();

// sync default options with .cpp!
SEXP rtsk_treeseq_load(const std::string &filename, int options = 0);
SEXP rtsk_table_collection_load(const std::string &filename, int options = 0);
void rtsk_treeseq_dump(SEXP ts, const std::string &filename, int options = 0);
void rtsk_table_collection_dump(SEXP tc, const std::string &filename,
                                int options = 0);
SEXP rtsk_treeseq_copy_tables(SEXP ts, int options = 0);
SEXP rtsk_treeseq_init(SEXP tc, int options = 0);
SEXP rtsk_variant_iterator_init(
    SEXP ts, Rcpp::Nullable<Rcpp::IntegerVector> samples = R_NilValue,
    bool isolated_as_missing = true,
    Rcpp::Nullable<Rcpp::CharacterVector> alleles = R_NilValue,
    double left = 0.0, double right = NA_REAL);
SEXP rtsk_variant_iterator_next(SEXP iterator);

SEXP rtsk_treeseq_get_num_provenances(SEXP ts);
SEXP rtsk_treeseq_get_num_populations(SEXP ts);
SEXP rtsk_treeseq_get_num_migrations(SEXP ts);
SEXP rtsk_treeseq_get_num_individuals(SEXP ts);
SEXP rtsk_treeseq_get_num_samples(SEXP ts);
Rcpp::IntegerVector rtsk_treeseq_get_samples(SEXP ts);
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
void rtsk_table_collection_sort(SEXP tc, int edge_start = 0, int site_start = 0,
                                int mutation_start = 0, int options = 0);
Rcpp::List rtsk_table_collection_summary(SEXP tc);
Rcpp::List rtsk_table_collection_metadata_length(SEXP tc);
int rtsk_individual_table_add_row(
    SEXP tc, int flags = 0,
    Rcpp::Nullable<Rcpp::NumericVector> location = R_NilValue,
    Rcpp::Nullable<Rcpp::IntegerVector> parents = R_NilValue,
    Rcpp::Nullable<Rcpp::RawVector> metadata = R_NilValue);
Rcpp::List rtsk_individual_table_get_row(SEXP tc, int index);
int rtsk_node_table_add_row(
    SEXP tc, int flags = 0, double time = 0, int population = -1,
    int individual = -1, Rcpp::Nullable<Rcpp::RawVector> metadata = R_NilValue);
Rcpp::List rtsk_node_table_get_row(SEXP tc, int index);
int rtsk_edge_table_add_row(
    SEXP tc, double left, double right, int parent, int child,
    Rcpp::Nullable<Rcpp::RawVector> metadata = R_NilValue);
Rcpp::List rtsk_edge_table_get_row(SEXP tc, int index);
int rtsk_site_table_add_row(
    SEXP tc, double position, const std::string &ancestral_state,
    Rcpp::Nullable<Rcpp::RawVector> metadata = R_NilValue);
Rcpp::List rtsk_site_table_get_row(SEXP tc, int index);
int rtsk_mutation_table_add_row(
    SEXP tc, int site, int node, int parent, double time,
    const std::string &derived_state,
    Rcpp::Nullable<Rcpp::RawVector> metadata = R_NilValue);
Rcpp::List rtsk_mutation_table_get_row(SEXP tc, int index);
int rtsk_population_table_add_row(
    SEXP tc, Rcpp::Nullable<Rcpp::RawVector> metadata = R_NilValue);
Rcpp::List rtsk_population_table_get_row(SEXP tc, int index);
int rtsk_migration_table_add_row(
    SEXP tc, double left, double right, int node, int source, int dest,
    double time, Rcpp::Nullable<Rcpp::RawVector> metadata = R_NilValue);
Rcpp::List rtsk_migration_table_get_row(SEXP tc, int index);
int rtsk_provenance_table_add_row(SEXP tc, const std::string &timestamp,
                                  const std::string &record);
Rcpp::List rtsk_provenance_table_get_row(SEXP tc, int index);

#endif
