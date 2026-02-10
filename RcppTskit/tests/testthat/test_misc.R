test_that("kastore_version() works", {
  v <- kastore_version()
  expect_true(is.integer(v))
  expect_equal(names(v), c("major", "minor", "patch"))
})

test_that("tskit_version() works", {
  v <- tskit_version()
  expect_true(is.integer(v))
  expect_equal(names(v), c("major", "minor", "patch"))
})

test_that("tsk_bug_assert() works", {
  # jarl-ignore internal_function:  it's just a test
  expect_error(RcppTskit:::test_tsk_bug_assert_c())
  # jarl-ignore internal_function:  it's just a test
  expect_error(RcppTskit:::test_tsk_bug_assert_cpp())
})

test_that("tsk_trace_error() works", {
  t <- "You have to compile with -DTSK_TRACE_ERRORS to run these tests. See src/Makevars.in."
  # jarl-ignore internal_function:  it's just a test
  skip_if_not(RcppTskit:::tsk_trace_errors_defined(), t)
  # jarl-ignore internal_function:  it's just a test
  expect_warning(RcppTskit:::test_tsk_trace_error_c())
  # jarl-ignore internal_function:  it's just a test
  expect_warning(RcppTskit:::test_tsk_trace_error_cpp())
})
