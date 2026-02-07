test_that("TreeSequence$new() works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  expect_error(TreeSequence$new(), regexp = "Provide a file name or a pointer!")
  expect_error(
    TreeSequence$new(file = "xyz", pointer = "y"),
    regexp = "Provide either a file name or a pointer, but not both!"
  )
  expect_error(
    TreeSequence$new(file = 1L),
    regexp = "file must be a character string!"
  )
  expect_error(
    TreeSequence$new(file = "bla", options = "y"),
    regexp = "options must be numeric/integer!"
  )
  expect_no_error(
    TreeSequence$new(file = ts_file, options = 0)
  )
  expect_no_error(TreeSequence$new(ts_file))
  expect_error(
    TreeSequence$new(pointer = 1L),
    regexp = "pointer must be an object of externalptr class!"
  )
})
