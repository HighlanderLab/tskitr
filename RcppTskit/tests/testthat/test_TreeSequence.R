test_that("TreeSequence$new() works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  expect_error(
    TreeSequence$new(),
    regexp = "Provide a file or an external pointer \\(xptr\\)!"
  )
  expect_error(
    TreeSequence$new(file = "xyz", xptr = "y"),
    regexp = "Provide either a file or an external pointer \\(xptr\\), but not both!"
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
    TreeSequence$new(xptr = 1L),
    regexp = "external pointer \\(xptr\\) must be an object of externalptr class!"
  )
})

test_that("TreeSequence$variants() iterates over sites", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)
  n_sites <- as.integer(ts$num_sites())

  it <- ts$variants()
  seen <- 0L
  repeat {
    v <- it$next_variant()
    if (is.null(v)) {
      break
    }
    seen <- seen + 1L
    expect_equal(
      sort(names(v)),
      c("alleles", "genotypes", "has_missing_data", "position", "site_id")
    )
  }
  expect_equal(seen, n_sites)
})

test_that("TreeSequence$variants() supports interval and samples", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)

  full_it <- ts$variants()
  first <- full_it$next_variant()
  second <- full_it$next_variant()
  expect_false(is.null(first))
  expect_false(is.null(second))

  it_interval <- ts$variants(
    left = first$position,
    right = second$position + 1e-12
  )
  v1 <- it_interval$next_variant()
  v2 <- it_interval$next_variant()
  v3 <- it_interval$next_variant()
  expect_equal(v1$site_id, first$site_id)
  expect_equal(v2$site_id, second$site_id)
  expect_null(v3)

  it_samples <- ts$variants(samples = c(0L, 1L, 2L))
  v_samples <- it_samples$next_variant()
  expect_length(v_samples$genotypes, 3L)
})

test_that("TreeSequence$variants() validates compatibility args", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)

  expect_error(ts$variants(copy = NA), "copy must be TRUE/FALSE")
  expect_error(ts$variants(copy = "yes"), "copy must be TRUE/FALSE")
  expect_error(ts$variants(copy = FALSE), "copy = FALSE is not supported yet")
  expect_error(
    ts$variants(impute_missing_data = NA),
    "impute_missing_data must be TRUE/FALSE or NULL"
  )
  expect_error(
    ts$variants(impute_missing_data = "yes"),
    "impute_missing_data must be TRUE/FALSE or NULL"
  )
  expect_warning(
    ts$variants(impute_missing_data = TRUE),
    "impute_missing_data is deprecated"
  )
  expect_error(
    ts$variants(isolated_as_missing = TRUE, impute_missing_data = TRUE),
    "inconsistent"
  )
})
