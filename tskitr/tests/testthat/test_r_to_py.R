context("test_r_to_py_and_py_to_r")

skip_if_no_tskit <- function() {
  if (!reticulate::py_module_available("tskit")) {
    skip("tskit not available for testing!")
  }
}

test_that("ts_r_to_py() and ts_py_to_r() work", {
  skip_if_no_tskit()

  # ---- ts_r_to_py() ----

  ts_file <- system.file("examples/test.trees", package = "tskitr")
  r_ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!
  n <- ts_summary(r_ts)
  m <- ts_metadata_length(r_ts)

  py_ts <- ts_r_to_py(r_ts)

  # Simple comparison of summaries and of the lengths of metadata
  expect_equal(py_ts$num_provenances, n$num_provenances)
  expect_equal(py_ts$num_populations, n$num_populations)
  expect_equal(py_ts$num_migrations, n$num_migrations)
  expect_equal(py_ts$num_individuals, n$num_individuals)
  expect_equal(py_ts$num_samples, n$num_samples)
  expect_equal(py_ts$num_nodes, n$num_nodes)
  expect_equal(py_ts$num_edges, n$num_edges)
  expect_equal(py_ts$num_trees, n$num_trees)
  expect_equal(py_ts$num_sites, n$num_sites)
  expect_equal(py_ts$num_mutations, n$num_mutations)
  expect_equal(py_ts$sequence_length, n$sequence_length)
  expect_equal(py_ts$time_units, n$time_units)

  expect_equal(reticulate::py_len(py_ts$metadata), m$ts)
  expect_equal(reticulate::py_len(py_ts$tables$metadata), m$ts)
  expect_equal(length(py_ts$tables$populations$metadata), m$populations)
  expect_equal(length(py_ts$tables$migrations$metadata), m$migrations)
  expect_equal(length(py_ts$tables$individuals$metadata), m$individuals)
  expect_equal(length(py_ts$tables$nodes$metadata), m$nodes)
  expect_equal(length(py_ts$tables$edges$metadata), m$edges)
  expect_equal(length(py_ts$tables$sites$metadata), m$sites)
  expect_equal(length(py_ts$tables$mutations$metadata), m$mutations)

  # ---- ts_py_to_r() ----

  py_ts2 <- py_ts$simplify(samples = c(0L, 1L, 2L, 3L))
  r_ts2 <- ts_py_to_r(py_ts2)
  n2 <- ts_summary(r_ts2)
  m2 <- ts_metadata_length(r_ts2)

  # Simple comparison of summaries and of the lengths of metadata
  expect_equal(py_ts2$num_provenances, n2$num_provenances)
  expect_equal(py_ts2$num_populations, n2$num_populations)
  expect_equal(py_ts2$num_migrations, n2$num_migrations)
  expect_equal(py_ts2$num_individuals, n2$num_individuals)
  expect_equal(py_ts2$num_samples, n2$num_samples)
  expect_equal(py_ts2$num_nodes, n2$num_nodes)
  expect_equal(py_ts2$num_edges, n2$num_edges)
  expect_equal(py_ts2$num_trees, n2$num_trees)
  expect_equal(py_ts2$num_sites, n2$num_sites)
  expect_equal(py_ts2$num_mutations, n2$num_mutations)
  expect_equal(py_ts2$sequence_length, n2$sequence_length)
  expect_equal(py_ts2$time_units, n2$time_units)

  expect_equal(reticulate::py_len(py_ts2$metadata), m2$ts)
  expect_equal(length(py_ts2$tables$populations$metadata), m2$populations)
  expect_equal(length(py_ts2$tables$migrations$metadata), m2$migrations)
  expect_equal(length(py_ts2$tables$individuals$metadata), m2$individuals)
  expect_equal(length(py_ts2$tables$nodes$metadata), m2$nodes)
  expect_equal(length(py_ts2$tables$edges$metadata), m2$edges)
  expect_equal(length(py_ts2$tables$sites$metadata), m2$sites)
  expect_equal(length(py_ts2$tables$mutations$metadata), m2$mutations)
})
