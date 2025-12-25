#include <Rcpp.h>
#include <tskit.h>

using namespace Rcpp;

// Baby step development to check all works well

// This one works
// [[Rcpp::export]]
List rcpp_hello_world() {
    CharacterVector x = CharacterVector::create( "foo", "bar" )  ;
    NumericVector y   = NumericVector::create( 0.0, 1.0 ) ;
    List z            = List::create( x, y ) ;
    return z ;
}

// This one works
// [[Rcpp::export]]
int tskit_version_major() {
    return TSK_VERSION_MAJOR;
}

// This one works
// [[Rcpp::export]]
int tskit_table_collection_init_ok() {
    tsk_table_collection_t tables;
    int ret = tsk_table_collection_init(&tables, 0);
    tsk_table_collection_free(&tables);
    return ret;
}
