context("test_cppFunction_compilation")

test_that("compilation via cppFunction() works", {
  # TODO: Time unittests to decide which tests will be active on CRAN #20
  #       https://github.com/HighlanderLab/tskitr/issues/20
  # skip_on_cran()
  codeString <- '
    #include <tskit.h>
    int ts_num_individuals(SEXP ts) {
    int n;
    Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
    n = (int) tsk_treeseq_get_num_individuals(xptr);
    return n;
  }'
  ts_num_individuals2 <- Rcpp::cppFunction(
    code = codeString,
    depends = "tskitr",
    plugins = "tskitr"
  )
  ts_file <- system.file("examples/test.trees", package = "tskitr")
  ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
  expect_equal(ts_num_individuals(ts), ts_num_individuals2(ts))
})
