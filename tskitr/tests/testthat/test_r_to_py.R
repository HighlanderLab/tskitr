context("test_r_to_py_and_py_to_r")

skip_if_no_tskit_py <- function() {
  # To get_tskit_py() we need internet connection
  skip_if_offline()
  if (!reticulate::py_module_available("tskit")) {
    skip("tskit reticulate Python module not available for testing!")
  }
}

test_that("ts_r_to_py() and ts_py_to_r() work", {
  skip_if_no_tskit_py()

  # ---- ts_r_to_py() ----

  ts_file <- system.file("examples/test.trees", package = "tskitr")
  ts_r <- ts_load(ts_file)
  n <- ts_summary(ts_r)
  m <- ts_metadata_length(ts_r)

  expect_error(
    ts_r_to_py(ts_r, tskit_module = "bla"),
    regexp = "tskit_module must be a reticulate Python module object!"
  )
  ts_py <- ts_r_to_py(ts_r)

  # Simple comparison of summaries and of the lengths of metadata
  expect_equal(ts_py$num_provenances, n$num_provenances)
  expect_equal(ts_py$num_populations, n$num_populations)
  expect_equal(ts_py$num_migrations, n$num_migrations)
  expect_equal(ts_py$num_individuals, n$num_individuals)
  expect_equal(ts_py$num_samples, n$num_samples)
  expect_equal(ts_py$num_nodes, n$num_nodes)
  expect_equal(ts_py$num_edges, n$num_edges)
  expect_equal(ts_py$num_trees, n$num_trees)
  expect_equal(ts_py$num_sites, n$num_sites)
  expect_equal(ts_py$num_mutations, n$num_mutations)
  expect_equal(ts_py$sequence_length, n$sequence_length)
  expect_equal(ts_py$time_units, n$time_units)

  expect_equal(reticulate::py_len(ts_py$metadata), m$ts)
  expect_equal(reticulate::py_len(ts_py$tables$metadata), m$ts)
  expect_equal(length(ts_py$tables$populations$metadata), m$populations)
  expect_equal(length(ts_py$tables$migrations$metadata), m$migrations)
  expect_equal(length(ts_py$tables$individuals$metadata), m$individuals)
  expect_equal(length(ts_py$tables$nodes$metadata), m$nodes)
  expect_equal(length(ts_py$tables$edges$metadata), m$edges)
  expect_equal(length(ts_py$tables$sites$metadata), m$sites)
  expect_equal(length(ts_py$tables$mutations$metadata), m$mutations)

  # ---- ts_py_to_r() ----

  expect_error(
    ts_py_to_r(1L),
    regexp = "ts must be a reticulate Python object!"
  )
  expect_error(
    ts_py_to_r(ts_r),
    regexp = "ts must be a reticulate Python object!"
  )
  ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
  ts2_r <- ts_py_to_r(ts2_py)
  n2 <- ts_summary(ts2_r)
  m2 <- ts_metadata_length(ts2_r)

  # Simple comparison of summaries and of the lengths of metadata
  expect_equal(ts2_py$num_provenances, n2$num_provenances)
  expect_equal(ts2_py$num_populations, n2$num_populations)
  expect_equal(ts2_py$num_migrations, n2$num_migrations)
  expect_equal(ts2_py$num_individuals, n2$num_individuals)
  expect_equal(ts2_py$num_samples, n2$num_samples)
  expect_equal(ts2_py$num_nodes, n2$num_nodes)
  expect_equal(ts2_py$num_edges, n2$num_edges)
  expect_equal(ts2_py$num_trees, n2$num_trees)
  expect_equal(ts2_py$num_sites, n2$num_sites)
  expect_equal(ts2_py$num_mutations, n2$num_mutations)
  expect_equal(ts2_py$sequence_length, n2$sequence_length)
  expect_equal(ts2_py$time_units, n2$time_units)

  expect_equal(reticulate::py_len(ts2_py$metadata), m2$ts)
  expect_equal(length(ts2_py$tables$populations$metadata), m2$populations)
  expect_equal(length(ts2_py$tables$migrations$metadata), m2$migrations)
  expect_equal(length(ts2_py$tables$individuals$metadata), m2$individuals)
  expect_equal(length(ts2_py$tables$nodes$metadata), m2$nodes)
  expect_equal(length(ts2_py$tables$edges$metadata), m2$edges)
  expect_equal(length(ts2_py$tables$sites$metadata), m2$sites)
  expect_equal(length(ts2_py$tables$mutations$metadata), m2$mutations)
})
