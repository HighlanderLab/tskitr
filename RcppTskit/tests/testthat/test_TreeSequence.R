test_that("TreeSequence$new() works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  expect_error(TreeSequence$new(), regexp = "Provide a file or a pointer!")
  expect_error(
    TreeSequence$new(file = "xyz", pointer = "y"),
    regexp = "Provide either a file or a pointer, but not both!"
  )
  expect_error(
    TreeSequence$new(file = 1L),
    regexp = "file must be a character string!"
  )
  expect_error(
    TreeSequence$new(file = "bla", skip_tables = "y"),
    regexp = "skip_tables must be TRUE/FALSE!"
  )
  expect_error(
    TreeSequence$new(file = "bla", skip_reference_sequence = 1),
    regexp = "skip_reference_sequence must be TRUE/FALSE!"
  )
  expect_no_error(
    TreeSequence$new(
      file = ts_file,
      skip_tables = FALSE,
      skip_reference_sequence = FALSE
    )
  )
  expect_no_error(
    TreeSequence$new(
      file = ts_file,
      skip_tables = TRUE,
      skip_reference_sequence = TRUE
    )
  )
  expect_no_error(TreeSequence$new(ts_file))
  expect_error(
    TreeSequence$new(pointer = 1L),
    regexp = "pointer must be an object of externalptr class!"
  )
})
