test_that("public C++ wrappers compile for downstream-style usage", {
  skip_on_cran()
  skip_if_not(
    nzchar(system.file("libs", package = "RcppTskit")),
    "Requires installed package libs for the RcppTskit plugin."
  )

  tc_public_scalars <- Rcpp::cppFunction(
    code = '
      #include <RcppTskit.hpp>
      Rcpp::List tc_public_scalars(SEXP tc) {
        return Rcpp::List::create(
          Rcpp::_["has_reference_sequence"] =
            tc_xptr_has_reference_sequence(tc),
          Rcpp::_["time_units"] = tc_xptr_time_units(tc),
          Rcpp::_["file_uuid"] = tc_xptr_file_uuid(tc),
          Rcpp::_["has_index"] = tc_xptr_has_index(tc)
        );
      }',
    depends = "RcppTskit",
    plugins = "RcppTskit"
  )

  ts_public_summary <- Rcpp::cppFunction(
    code = '
      #include <RcppTskit.hpp>
      Rcpp::List ts_public_summary(SEXP ts) {
        return ts_xptr_summary(ts);
      }',
    depends = "RcppTskit",
    plugins = "RcppTskit"
  )

  tc_public_summary <- Rcpp::cppFunction(
    code = '
      #include <RcppTskit.hpp>
      Rcpp::List tc_public_summary(SEXP tc) {
        return tc_xptr_summary(tc);
      }',
    depends = "RcppTskit",
    plugins = "RcppTskit"
  )

  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  # jarl-ignore internal_function:  it's just a test
  ts_xptr <- RcppTskit:::ts_xptr_load(ts_file)
  # jarl-ignore internal_function:  it's just a test
  tc_xptr <- RcppTskit:::tc_xptr_load(ts_file)

  tc_scalars <- tc_public_scalars(tc_xptr)
  # jarl-ignore internal_function:  it's just a test
  expect_identical(
    tc_scalars$has_reference_sequence,
    RcppTskit:::tc_xptr_has_reference_sequence(tc_xptr)
  )
  # jarl-ignore internal_function:  it's just a test
  expect_identical(
    tc_scalars$time_units,
    RcppTskit:::tc_xptr_time_units(tc_xptr)
  )
  # jarl-ignore internal_function:  it's just a test
  expect_identical(tc_scalars$file_uuid, RcppTskit:::tc_xptr_file_uuid(tc_xptr))
  # jarl-ignore internal_function:  it's just a test
  expect_identical(tc_scalars$has_index, RcppTskit:::tc_xptr_has_index(tc_xptr))
  # jarl-ignore internal_function:  it's just a test
  expect_equal(ts_public_summary(ts_xptr), RcppTskit:::ts_xptr_summary(ts_xptr))
  # jarl-ignore internal_function:  it's just a test
  expect_equal(tc_public_summary(tc_xptr), RcppTskit:::tc_xptr_summary(tc_xptr))
})
