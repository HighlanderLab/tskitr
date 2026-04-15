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

test_that("validate_options() branches are covered", {
  # jarl-ignore internal_function: it's just a test
  expect_equal(RcppTskit:::test_validate_options(0L, 0L), 0L)

  # negative options branch
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_validate_options(-1L, 0L),
    regexp = "test_validate_options does not support negative options"
  )

  # unsupported bits branch
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_validate_options(1L, 0L),
    regexp = "test_validate_options only supports options"
  )

  # non-zero supported flags branch
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_validate_options(1L, 1L),
    regexp = "test_validate_options does not support non-zero options"
  )
})

test_that("R-side integer and row-index validators cover message branches", {
  # jarl-ignore internal_function: it's just a test
  expect_no_error(RcppTskit:::validate_integer_scalar_arg(1, "x"))
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_integer_scalar_arg(1.5, "x"),
    regexp = "x must be a non-NA integer scalar!"
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_integer_scalar_arg(1L, "x", minimum = 2L),
    regexp = "x must be a non-NA integer scalar >= 2!"
  )
  # jarl-ignore internal_function: it's just a test
  expect_no_error(
    RcppTskit:::validate_optional_integer_vector_arg(c(1, 2, 3), "ids")
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_optional_integer_vector_arg(c(1, 2.5), "ids"),
    regexp = "ids must be NULL or an integer vector with no NA values!"
  )
  # jarl-ignore internal_function: it's just a test
  expect_no_error(RcppTskit:::validate_row_index(NULL, allow_null = TRUE))
})

test_that("TSK_NO_CHECK_INTEGRITY constant wrapper returns integer", {
  # jarl-ignore internal_function: it's just a test
  v <- RcppTskit:::rtsk_const_tsk_no_check_integrity()
  expect_true(is.integer(v))
  expect_equal(length(v), 1L)
  expect_true(v > 0L)
})

test_that("rtsk_wrap_tsk_size_t_as_integer64() works", {
  # jarl-ignore internal_function: it's just a test
  x <- RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("0")
  expect_true(bit64::is.integer64(x))
  expect_equal(x, bit64::as.integer64("0"))

  # jarl-ignore internal_function: it's just a test
  x <- RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("42")
  expect_true(bit64::is.integer64(x))
  expect_equal(as.character(x), "42")

  # max signed 64-bit integer (limit of bit64::integer64)
  max_i64 <- "9223372036854775807"
  # jarl-ignore internal_function: it's just a test
  x <- RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64(max_i64)
  expect_true(bit64::is.integer64(x))
  expect_equal(as.character(x), max_i64)

  # first value above signed 64-bit range
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("9223372036854775808"),
    regexp = "exceeds bit64::integer64 maximum"
  )

  # invalid numeric format
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("not_a_number"),
    regexp = "base-10 unsigned integer string"
  )

  # parsed prefix only; remaining characters should fail strict parse check
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("123abc"),
    regexp = "base-10 unsigned integer string"
  )

  # force range-check branch (test-only path)
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("1", TRUE),
    regexp = "value is out of range for tsk_size_t"
  )
})
