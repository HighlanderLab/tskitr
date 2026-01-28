skip_if_no_tskit_py <- function() {
  if (!covr::in_covr()) {
    # To get_tskit_py() we need internet connection
    skip_if_offline()
  }
  if (!reticulate::py_module_available("tskit")) {
    skip("tskit reticulate Python module not available for testing!")
  }
}

test_that("ts_r_to_py() and ts_py_to_r() work", {
  skip_if_no_tskit_py()

  # ---- ts_r_to_py() ----

  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts_r <- ts_load(ts_file)
  n <- ts_summary_ptr(ts_r$pointer)
  m <- ts_metadata_length_ptr(ts_r$pointer)

  expect_error(
    ts_r$r_to_py(tskit_module = "bla"),
    regexp = "object must be a reticulate Python module object!"
  )
  ts_py <- ts_r$r_to_py()

  # Simple comparison of summaries and of the lengths of metadata
  expect_equal(ts_py$num_provenances, n$num_provenances)
  expect_equal(ts_py$num_provenances, ts_r$num_provenances())
  expect_equal(ts_py$num_populations, n$num_populations)
  expect_equal(ts_py$num_populations, ts_r$num_populations())
  expect_equal(ts_py$num_migrations, n$num_migrations)
  expect_equal(ts_py$num_migrations, ts_r$num_migrations())
  expect_equal(ts_py$num_individuals, n$num_individuals)
  expect_equal(ts_py$num_individuals, ts_r$num_individuals())
  expect_equal(ts_py$num_samples, n$num_samples)
  expect_equal(ts_py$num_samples, ts_r$num_samples())
  expect_equal(ts_py$num_nodes, n$num_nodes)
  expect_equal(ts_py$num_nodes, ts_r$num_nodes())
  expect_equal(ts_py$num_edges, n$num_edges)
  expect_equal(ts_py$num_edges, ts_r$num_edges())
  expect_equal(ts_py$num_trees, n$num_trees)
  expect_equal(ts_py$num_trees, ts_r$num_trees())
  expect_equal(ts_py$num_sites, n$num_sites)
  expect_equal(ts_py$num_sites, ts_r$num_sites())
  expect_equal(ts_py$num_mutations, n$num_mutations)
  expect_equal(ts_py$num_mutations, ts_r$num_mutations())
  expect_equal(ts_py$sequence_length, n$sequence_length)
  expect_equal(ts_py$sequence_length, ts_r$sequence_length())
  expect_equal(ts_py$time_units, n$time_units)
  expect_equal(ts_py$time_units, ts_r$time_units())

  expect_equal(reticulate::py_len(ts_py$metadata), m$ts)
  expect_equal(reticulate::py_len(ts_py$tables$metadata), m$ts)
  expect_equal(length(ts_py$tables$populations$metadata), m$populations)
  expect_equal(length(ts_py$tables$migrations$metadata), m$migrations)
  expect_equal(length(ts_py$tables$individuals$metadata), m$individuals)
  expect_equal(length(ts_py$tables$nodes$metadata), m$nodes)
  expect_equal(length(ts_py$tables$edges$metadata), m$edges)
  expect_equal(length(ts_py$tables$sites$metadata), m$sites)
  expect_equal(length(ts_py$tables$mutations$metadata), m$mutations)

  expect_error(
    ts_r_to_py_ptr("not_an_externalptr_object"),
    regexp = "ts must be an object of externalptr class!"
  )
  expect_error(
    ts_r_to_py_ptr(ts_r$pointer, tskit_module = "not_a_module"),
    regexp = "object must be a reticulate Python module object!"
  )
  ts_py <- ts_r_to_py_ptr(ts_r$pointer)

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
    ts_py_to_r_ptr(1L),
    regexp = "ts must be a reticulate Python object!"
  )
  expect_error(
    ts_py_to_r(1L),
    regexp = "ts must be a reticulate Python object!"
  )
  expect_error(
    ts_py_to_r_ptr(ts_r),
    regexp = "ts must be a reticulate Python object!"
  )
  expect_error(
    ts_py_to_r(ts_r),
    regexp = "ts must be a reticulate Python object!"
  )
  ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
  ts2_r_ptr <- ts_py_to_r_ptr(ts2_py)
  ts2_r <- ts_py_to_r(ts2_py)
  n2 <- ts_summary_ptr(ts2_r_ptr)
  m2 <- ts_metadata_length_ptr(ts2_r_ptr)

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
