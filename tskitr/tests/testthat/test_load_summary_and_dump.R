context("test_load_summary_and_dump")

test_that("ts_load(), ts_summary(), and ts_dump(x) work", {
  # ---- ts_load() ----

  expect_error(ts_load())
  expect_error(ts_load("nonexistent_ts"))
  ts_file <- system.file("examples/test.trees", package = "tskitr")
  ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!

  # ---- ts_summary() ----

  n <- ts_summary(ts)
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
      "time_units" = "generations"
    )
  )

  expect_error(ts_num_provenances())
  n <- ts_num_provenances(ts)
  expect_true(is.integer(n))
  expect_equal(n, 2L)

  expect_error(ts_num_populations())
  n <- ts_num_populations(ts)
  expect_true(is.integer(n))
  expect_equal(n, 1L)

  expect_error(ts_num_migrations())
  n <- ts_num_migrations(ts)
  expect_true(is.integer(n))
  expect_equal(n, 0L)

  expect_error(ts_num_individuals())
  n <- ts_num_individuals(ts)
  expect_true(is.integer(n))
  expect_equal(n, 80L)

  expect_error(ts_num_samples())
  n <- ts_num_samples(ts)
  expect_true(is.integer(n))
  expect_equal(n, 160L)

  expect_error(ts_num_nodes())
  n <- ts_num_nodes(ts)
  expect_true(is.integer(n))
  expect_equal(n, 344L)

  expect_error(ts_num_edges())
  n <- ts_num_edges(ts)
  expect_true(is.integer(n))
  expect_equal(n, 414L)

  expect_error(ts_num_trees())
  n <- ts_num_trees(ts)
  expect_true(is.integer(n))
  expect_equal(n, 26L)

  expect_error(ts_num_sites())
  n <- ts_num_sites(ts)
  expect_true(is.integer(n))
  expect_equal(n, 2376L)

  expect_error(ts_num_mutations())
  n <- ts_num_mutations(ts)
  expect_true(is.integer(n))
  expect_equal(n, 2700L)

  expect_error(ts_sequence_length())
  n <- ts_sequence_length(ts)
  expect_true(is.numeric(n))
  expect_equal(n, 10000)

  expect_error(ts_time_units())
  c <- ts_time_units(ts)
  expect_true(is.character(c))
  expect_equal(c, "generations")

  # ---- ts_dump() ----

  expect_error(ts_dump())
  expect_error(ts_dump(nonexistent_ts))
  expect_error(ts_dump(ts))

  # Write ts to disk, read it back, and check that nums are still the same
  dump_file <- tempfile(fileext = ".trees")
  ts_dump(ts, dump_file)
  rm(ts)
  ts <- tskitr::ts_load(dump_file) # slendr also has ts_load()!
  n <- ts_summary(ts)
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
      "time_units" = "generations"
    )
  )

  # ---- ts_metadata_length() ----

  n <- ts_metadata_length(ts)
  expect_equal(
    n,
    list(
      # we got these numbers from inst/examples/create_test.trees.R
      "ts" = 0L,
      "tables" = 0L,
      "migrations" = 0L,
      "populations" = 33L,
      "individuals" = 0L,
      "nodes" = 0L,
      "edges" = 0L,
      "sites" = 0L,
      "mutations" = 0L
    )
  )

  ts_file <- system.file("examples/testTODO.trees", package = "tskitr")
  ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!

  n <- ts_metadata_length(ts)
  expect_equal(
    n,
    list(
      # we got these numbers from inst/examples/create_test.trees.R
      "ts" = 0L,
      "tables" = 0L,
      "migrations" = 0L,
      "populations" = 33L,
      "individuals" = 0L,
      "nodes" = 0L,
      "edges" = 0L,
      "sites" = 0L,
      "mutations" = 0L
    )
  )
})
