context("test_load_num_and_dump")

test_that("ts_load(), ts_num(), and ts_dump(x) work", {
  # ---- ts_load() ----

  expect_error(ts_load())
  expect_error(ts_load("nonexistent_ts"))
  ts_file <- system.file("examples/test.trees", package = "tskitr")
  ts <- tskitr::ts_load(ts_file) # slendr also has ts_load()!

  # ---- ts_num() ----

  n <- ts_num(ts)
  expect_equal(
    n,
    list(
      # we got these numbers from inst/examples/create_test.trees.R
      "num_provenances" = 2,
      "num_populations" = 1,
      "num_migrations" = 0,
      "num_individuals" = 80,
      "num_samples" = 160,
      "num_nodes" = 344,
      "num_edges" = 414,
      "num_trees" = 26,
      "num_sites" = 2376,
      "num_mutations" = 2700,
      "sequence_length" = 10000
    )
  )

  expect_error(ts_num_provenances())
  n <- ts_num_provenances(ts)
  expect_equal(n, 2)
  expect_true(is.integer(n))

  expect_error(ts_num_populations())
  n <- ts_num_populations(ts)
  expect_equal(n, 1)
  expect_true(is.integer(n))

  expect_error(ts_num_migrations())
  n <- ts_num_migrations(ts)
  expect_equal(n, 0)
  expect_true(is.integer(n))

  expect_error(ts_num_individuals())
  n <- ts_num_individuals(ts)
  expect_equal(n, 80)
  expect_true(is.integer(n))

  expect_error(ts_num_samples())
  n <- ts_num_samples(ts)
  expect_equal(n, 160)
  expect_true(is.integer(n))

  expect_error(ts_num_nodes())
  n <- ts_num_nodes(ts)
  expect_equal(n, 344)
  expect_true(is.integer(n))

  expect_error(ts_num_edges())
  n <- ts_num_edges(ts)
  expect_equal(n, 414)
  expect_true(is.integer(n))

  expect_error(ts_num_trees())
  n <- ts_num_trees(ts)
  expect_equal(n, 26)
  expect_true(is.integer(n))

  expect_error(ts_num_sites())
  n <- ts_num_sites(ts)
  expect_equal(n, 2376)
  expect_true(is.integer(n))

  expect_error(ts_num_mutations())
  n <- ts_num_mutations(ts)
  expect_equal(n, 2700)
  expect_true(is.integer(n))

  expect_error(ts_sequence_length())
  n <- ts_sequence_length(ts)
  expect_equal(n, 10000)
  expect_true(is.numeric(n))

  expect_error(ts_dump())
  expect_error(ts_dump(nonexistent_ts))
  expect_error(ts_dump(ts))
  dump_file <- tempfile(fileext = ".trees")

  # ---- ts_dump() ----

  # Write ts to disk, read it back, and check that nums are still the same
  ts_dump(ts, dump_file)
  rm(ts)
  ts <- tskitr::ts_load(dump_file) # slendr also has ts_load()!
  n <- ts_num(ts)
  expect_equal(
    n,
    list(
      # we got these numbers from inst/examples/create_test.trees.R
      "num_provenances" = 2,
      "num_populations" = 1,
      "num_migrations" = 0,
      "num_individuals" = 80,
      "num_samples" = 160,
      "num_nodes" = 344,
      "num_edges" = 414,
      "num_trees" = 26,
      "num_sites" = 2376,
      "num_mutations" = 2700,
      "sequence_length" = 10000
    )
  )
})
