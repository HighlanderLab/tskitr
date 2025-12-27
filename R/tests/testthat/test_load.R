context("test_load_and_num")

test_that("ts_load works and ts_num(_x) are correct", {
  expect_error(ts_load())
  expect_error(ts_load("nonexistent_ts"))
  ts_file <- system.file("examples", "test.trees", package = "tskitr")
  ts <- ts_load(ts_file)

  expect_error(ts_num())
  n <- ts_num(ts)
  expect_equal(
    n,
    list(
      "num_provenances" = 2,
      "num_populations" = 1,
      "num_migrations" = 0,
      "num_individuals" = 80,
      "num_samples" = 160,
      "num_nodes" = 344,
      "num_edges" = 414,
      "num_trees" = 26,
      "num_sites" = 2376,
      "num_mutations" = 2700
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
})
