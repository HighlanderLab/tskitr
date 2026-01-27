test_that("ts_load(), ts_summary*(), and ts_dump(x) work", {
  # ---- ts_load() ----

  expect_error(ts_load_ptr())
  expect_error(ts_load())
  expect_error(ts_load_ptr("nonexistent_ts"))
  expect_error(ts_load("nonexistent_ts"))
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts_ptr <- ts_load_ptr(ts_file)
  ts <- ts_load(ts_file)

  # ---- ts_summary_ptr() ----

  # Simple comparison of summaries
  expect_error(ts_summary_ptr(ts))
  n_ptr <- ts_summary_ptr(ts_ptr)
  expect_equal(
    n_ptr,
    list(
      # we got these numbers from inst/examples/create_test.trees.R
      "num_provenances" = 2L,
      "num_populations" = 1L,
      "num_migrations" = 0L,
      "num_individuals" = 80L,
      "num_samples" = 160L,
      "num_nodes" = 344L,
      "num_edges" = 414L,
      "num_trees" = 26L,
      "num_sites" = 2376L,
      "num_mutations" = 2700L,
      "sequence_length" = 10000.0,
      "time_units" = "generations",
      "min_time" = 0,
      "max_time" = 7.470281689748594
    )
  )

  expect_error(ts_num_provenances_ptr())
  expect_error(ts_num_provenances_ptr(ts))
  n_ptr <- ts_num_provenances_ptr(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 2L)
  expect_equal(ts$num_provenances(), 2L)

  expect_error(ts_num_populations_ptr())
  expect_error(ts_num_populations_ptr(ts))
  n_ptr <- ts_num_populations_ptr(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 1L)
  expect_equal(ts$num_populations(), 1L)

  expect_error(ts_num_migrations_ptr())
  expect_error(ts_num_migrations_ptr(ts))
  n_ptr <- ts_num_migrations_ptr(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 0L)
  expect_equal(ts$num_migrations(), 0L)

  expect_error(ts_num_individuals_ptr())
  expect_error(ts_num_individuals_ptr(ts))
  n_ptr <- ts_num_individuals_ptr(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 80L)
  expect_equal(ts$num_individuals(), 80L)

  expect_error(ts_num_samples_ptr())
  expect_error(ts_num_samples_ptr(ts))
  n_ptr <- ts_num_samples_ptr(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 160L)
  expect_equal(ts$num_samples(), 160L)

  expect_error(ts_num_nodes_ptr())
  expect_error(ts_num_nodes_ptr(ts))
  n_ptr <- ts_num_nodes_ptr(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 344L)
  expect_equal(ts$num_nodes(), 344L)

  expect_error(ts_num_edges_ptr())
  expect_error(ts_num_edges_ptr(ts))
  n_ptr <- ts_num_edges_ptr(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 414L)
  expect_equal(ts$num_edges(), 414L)

  expect_error(ts_num_trees_ptr())
  expect_error(ts_num_trees_ptr(ts))
  n_ptr <- ts_num_trees_ptr(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 26L)
  expect_equal(ts$num_trees(), 26L)

  expect_error(ts_num_sites_ptr())
  expect_error(ts_num_sites_ptr(ts))
  n_ptr <- ts_num_sites_ptr(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 2376L)
  expect_equal(ts$num_sites(), 2376L)

  expect_error(ts_num_mutations_ptr())
  expect_error(ts_num_mutations_ptr(ts))
  n_ptr <- ts_num_mutations_ptr(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 2700L)
  expect_equal(ts$num_mutations(), 2700L)

  expect_error(ts_sequence_length_ptr())
  expect_error(ts_sequence_length_ptr(ts))
  n_ptr <- ts_sequence_length_ptr(ts_ptr)
  expect_true(is.numeric(n_ptr))
  expect_equal(n_ptr, 10000)
  expect_equal(ts$sequence_length(), 10000)

  expect_error(ts_time_units_ptr())
  expect_error(ts_time_units_ptr(ts))
  c_ptr <- ts_time_units_ptr(ts_ptr)
  expect_true(is.character(c_ptr))
  expect_equal(c_ptr, "generations")
  expect_equal(ts$time_units(), "generations")

  expect_error(ts_min_time_ptr())
  expect_error(ts_min_time_ptr(ts))
  d_ptr <- ts_min_time_ptr(ts_ptr)
  expect_true(is.numeric(d_ptr))
  expect_equal(d_ptr, 0.0)
  expect_equal(ts$min_time(), 0.0)

  expect_error(ts_max_time_ptr())
  expect_error(ts_max_time_ptr(ts))
  d_ptr <- ts_max_time_ptr(ts_ptr)
  expect_true(is.numeric(d_ptr))
  expect_equal(d_ptr, 7.470281689748594)
  expect_equal(ts$max_time(), 7.470281689748594)

  # ---- ts_print_ptr() and ts$print() ----

  # Simple comparison of summaries
  expect_error(
    ts_print_ptr("not an externalptr object"),
    regexp = "ts must be an object of externalptr class!"
  )
  p_ptr <- ts_print_ptr(ts_ptr)
  p <- ts$print()
  expect_equal(
    p,
    list(
      ts = data.frame(
        property = c(
          "num_samples",
          "sequence_length",
          "num_trees",
          "time_units",
          "min_time",
          "max_time",
          "has_metadata"
        ),
        value = c(160, 10000, 26, "generations", 0.0, 7.470281689748594, FALSE)
      ),
      tables = data.frame(
        table = c(
          "provenances",
          "populations",
          "migrations",
          "individuals",
          "nodes",
          "edges",
          "sites",
          "mutations"
        ),
        number = c(2, 1, 0, 80, 344, 414, 2376, 2700),
        has_metadata = c(
          NA, # provenances have no metadata
          TRUE,
          FALSE,
          FALSE,
          FALSE,
          FALSE,
          FALSE,
          FALSE
        )
      )
    )
  )
  expect_equal(p_ptr, p)

  # ---- ts_dump_ptr() ----

  expect_error(ts_dump_ptr())
  expect_error(ts_dump_ptr(nonexistent_ts))
  expect_error(ts_dump_ptr(file = 1))
  expect_error(ts_dump_ptr(nonexistent_ts, file = 1))
  expect_error(ts_dump_ptr(1, file = 1))
  expect_error(ts_dump_ptr(1, file = "1"))
  expect_error(ts_dump_ptr(1, file = 1))
  expect_error(ts_dump_ptr(ts_ptr))
  expect_error(ts_dump_ptr(ts))
  bad_path <- file.path(tempdir(), "no_such_dir", "out.trees")
  expect_error(ts_dump_ptr(ts_ptr, file = bad_path))

  # Write ts to disk, read it back, and check that nums are still the same
  dump_file <- tempfile(fileext = ".trees")
  ts_dump_ptr(ts_ptr, dump_file)
  rm(ts_ptr)
  ts_ptr <- ts_load_ptr(dump_file)

  # Simple comparison of summaries
  n <- ts_summary_ptr(ts_ptr)
  expect_equal(
    n,
    list(
      # we got these numbers from inst/examples/create_test.trees.R
      "num_provenances" = 2L,
      "num_populations" = 1L,
      "num_migrations" = 0L,
      "num_individuals" = 80L,
      "num_samples" = 160L,
      "num_nodes" = 344L,
      "num_edges" = 414L,
      "num_trees" = 26L,
      "num_sites" = 2376L,
      "num_mutations" = 2700L,
      "sequence_length" = 10000.0,
      "time_units" = "generations",
      "min_time" = 0.0,
      "max_time" = 7.470281689748594
    )
  )

  # ---- ts$dump() ----

  expect_error(ts$dump())
  expect_error(ts$write())
  expect_error(ts$dump(file = 1))
  bad_path <- file.path(tempdir(), "no_such_dir", "out.trees")
  expect_error(ts$dump(ts, file = bad_path))

  # Write ts to disk, read it back, and check that nums are still the same
  dump_file <- tempfile(fileext = ".trees")
  ts$dump(dump_file)
  rm(ts)
  ts <- ts_load(dump_file)

  # Simple comparison of summaries
  n_ptr <- ts_summary_ptr(ts$pointer)
  expect_equal(
    n_ptr,
    list(
      # we got these numbers from inst/examples/create_test.trees.R
      "num_provenances" = 2L,
      "num_populations" = 1L,
      "num_migrations" = 0L,
      "num_individuals" = 80L,
      "num_samples" = 160L,
      "num_nodes" = 344L,
      "num_edges" = 414L,
      "num_trees" = 26L,
      "num_sites" = 2376L,
      "num_mutations" = 2700L,
      "sequence_length" = 10000.0,
      "time_units" = "generations",
      "min_time" = 0.0,
      "max_time" = 7.470281689748594
    )
  )

  # ---- ts_metadata_length_ptr() ----

  # Simple comparison of the lengths of metadata
  n_ptr <- ts_metadata_length_ptr(ts_ptr)
  n <- ts$metadata_length()
  expect_equal(
    n_ptr,
    list(
      # we got these numbers from inst/examples/create_test.trees.R
      "ts" = 0L,
      "populations" = 33L,
      "migrations" = 0L,
      "individuals" = 0L,
      "nodes" = 0L,
      "edges" = 0L,
      "sites" = 0L,
      "mutations" = 0L
    )
  )
  expect_equal(n_ptr, n)

  ts_file <- system.file("examples/test2.trees", package = "RcppTskit")
  ts_ptr <- ts_load_ptr(ts_file)
  ts <- ts_load(ts_file)

  n_ptr <- ts_summary_ptr(ts_ptr)
  expect_equal(
    n_ptr,
    list(
      # we got these numbers from inst/examples/create_test.trees.{py,R}
      "num_provenances" = 2L,
      "num_populations" = 1L,
      "num_migrations" = 0L,
      "num_individuals" = 81L,
      "num_samples" = 160L,
      "num_nodes" = 344L,
      "num_edges" = 414L,
      "num_trees" = 26L,
      "num_sites" = 2376L,
      "num_mutations" = 2700L,
      "sequence_length" = 10000.0,
      "time_units" = "generations",
      "min_time" = 0,
      "max_time" = 7.470281689748594
    )
  )

  m_ptr <- ts_metadata_length_ptr(ts_ptr)
  m <- ts$metadata_length()
  expect_equal(
    m_ptr,
    list(
      # we got these numbers from inst/examples/create_test.trees.{py,R}
      "ts" = 23L,
      "populations" = 33L,
      "migrations" = 0L,
      "individuals" = 21L,
      "nodes" = 0L,
      "edges" = 0L,
      "sites" = 0L,
      "mutations" = 0L
    )
  )
  expect_equal(m_ptr, m)

  p_ptr <- ts_print_ptr(ts_ptr)
  p <- ts$print()
  expect_equal(
    p_ptr,
    list(
      ts = data.frame(
        property = c(
          "num_samples",
          "sequence_length",
          "num_trees",
          "time_units",
          "min_time",
          "max_time",
          "has_metadata"
        ),
        value = c(160, 10000, 26, "generations", 0.0, 7.470281689748594, TRUE)
      ),
      tables = data.frame(
        table = c(
          "provenances",
          "populations",
          "migrations",
          "individuals",
          "nodes",
          "edges",
          "sites",
          "mutations"
        ),
        number = c(2, 1, 0, 81, 344, 414, 2376, 2700),
        has_metadata = c(
          NA, # provenances have no metadata
          TRUE,
          FALSE,
          TRUE,
          FALSE,
          FALSE,
          FALSE,
          FALSE
        )
      )
    )
  )
  expect_equal(p_ptr, p)
})
