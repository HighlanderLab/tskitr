test_that("ts/tc_load(), ts/tc_summary*(), and ts/tc_dump(x) work", {
  # ---- ts_load() ----

  expect_error(ts_ptr_load())
  expect_error(ts_load())
  expect_error(ts_ptr_load("nonexistent_ts"))
  expect_error(ts_load("nonexistent_ts"))
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")

  expect_error(
    ts_load(ts_file, skip_tables = "y"),
    regexp = "skip_tables must be TRUE/FALSE!"
  )
  expect_no_error(tc_load(ts_file, skip_tables = TRUE))
  check_empty_tables <- function(ts) {
    p <- ts$print()
    expect_true(all(p$tables$number == 0))
  }
  ts <- ts_load(ts_file, skip_tables = TRUE)
  check_empty_tables(ts)
  ts <- TableCollection$new(file = ts_file, skip_tables = TRUE)
  check_empty_tables(ts)

  expect_error(
    ts_load(ts_file, skip_reference_sequence = 1L),
    regexp = "skip_reference_sequence must be TRUE/FALSE!"
  )
  expect_no_error(ts_load(ts_file, skip_reference_sequence = TRUE))

  expect_error(
    ts_ptr_load(ts_file, options = bitwShiftL(1L, 30)),
    regexp = "ts_ptr_load only supports load options"
    # TSK_LOAD_SKIP_TABLES (1 << 0) and TSK_LOAD_SKIP_REFERENCE_SEQUENCE (1 << 1)
  )

  ts_ptr <- ts_ptr_load(ts_file)
  ts <- ts_load(ts_file)

  # ---- tc_load() ----

  expect_error(tc_ptr_load())
  expect_error(tc_load())
  expect_error(tc_ptr_load("nonexistent_ts"))
  expect_error(tc_load("nonexistent_ts"))
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")

  expect_error(
    tc_load(ts_file, skip_tables = "y"),
    regexp = "skip_tables must be TRUE/FALSE!"
  )
  expect_no_error(tc_load(ts_file, skip_tables = TRUE))
  check_empty_tables <- function(tc) {
    p <- tc$print()
    expect_true(all(p$tables$number == 0))
  }
  tc <- tc_load(ts_file, skip_tables = TRUE)
  check_empty_tables(tc)
  tc <- TableCollection$new(file = ts_file, skip_tables = TRUE)
  check_empty_tables(tc)

  expect_error(
    tc_load(ts_file, skip_reference_sequence = 1L),
    regexp = "skip_reference_sequence must be TRUE/FALSE!"
  )
  expect_no_error(tc_load(ts_file, skip_reference_sequence = TRUE))

  expect_error(
    tc_ptr_load(ts_file, options = bitwShiftL(1L, 30)),
    regexp = "tc_ptr_load only supports load options"
    # TSK_LOAD_SKIP_TABLES (1 << 0) and TSK_LOAD_SKIP_REFERENCE_SEQUENCE (1 << 1)
  )

  tc_ptr <- tc_ptr_load(ts_file)
  tc <- tc_load(ts_file)

  # ---- ts_ptr_summary() ----

  # Simple comparison of summaries
  expect_error(ts_ptr_summary(ts))
  n_ptr <- ts_ptr_summary(ts_ptr)
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

  expect_error(ts_ptr_num_provenances())
  expect_error(ts_ptr_num_provenances(ts))
  n_ptr <- ts_ptr_num_provenances(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 2L)
  expect_equal(ts$num_provenances(), 2L)

  expect_error(ts_ptr_num_populations())
  expect_error(ts_ptr_num_populations(ts))
  n_ptr <- ts_ptr_num_populations(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 1L)
  expect_equal(ts$num_populations(), 1L)

  expect_error(ts_ptr_num_migrations())
  expect_error(ts_ptr_num_migrations(ts))
  n_ptr <- ts_ptr_num_migrations(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 0L)
  expect_equal(ts$num_migrations(), 0L)

  expect_error(ts_ptr_num_individuals())
  expect_error(ts_ptr_num_individuals(ts))
  n_ptr <- ts_ptr_num_individuals(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 80L)
  expect_equal(ts$num_individuals(), 80L)

  expect_error(ts_ptr_num_samples())
  expect_error(ts_ptr_num_samples(ts))
  n_ptr <- ts_ptr_num_samples(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 160L)
  expect_equal(ts$num_samples(), 160L)

  expect_error(ts_ptr_num_nodes())
  expect_error(ts_ptr_num_nodes(ts))
  n_ptr <- ts_ptr_num_nodes(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 344L)
  expect_equal(ts$num_nodes(), 344L)

  expect_error(ts_ptr_num_edges())
  expect_error(ts_ptr_num_edges(ts))
  n_ptr <- ts_ptr_num_edges(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 414L)
  expect_equal(ts$num_edges(), 414L)

  expect_error(ts_ptr_num_trees())
  expect_error(ts_ptr_num_trees(ts))
  n_ptr <- ts_ptr_num_trees(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 26L)
  expect_equal(ts$num_trees(), 26L)

  expect_error(ts_ptr_num_sites())
  expect_error(ts_ptr_num_sites(ts))
  n_ptr <- ts_ptr_num_sites(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 2376L)
  expect_equal(ts$num_sites(), 2376L)

  expect_error(ts_ptr_num_mutations())
  expect_error(ts_ptr_num_mutations(ts))
  n_ptr <- ts_ptr_num_mutations(ts_ptr)
  expect_true(is.integer(n_ptr))
  expect_equal(n_ptr, 2700L)
  expect_equal(ts$num_mutations(), 2700L)

  expect_error(ts_ptr_sequence_length())
  expect_error(ts_ptr_sequence_length(ts))
  n_ptr <- ts_ptr_sequence_length(ts_ptr)
  expect_true(is.numeric(n_ptr))
  expect_equal(n_ptr, 10000)
  expect_equal(ts$sequence_length(), 10000)

  expect_error(ts_ptr_time_units())
  expect_error(ts_ptr_time_units(ts))
  c_ptr <- ts_ptr_time_units(ts_ptr)
  expect_true(is.character(c_ptr))
  expect_equal(c_ptr, "generations")
  expect_equal(ts$time_units(), "generations")

  expect_error(ts_ptr_min_time())
  expect_error(ts_ptr_min_time(ts))
  d_ptr <- ts_ptr_min_time(ts_ptr)
  expect_true(is.numeric(d_ptr))
  expect_equal(d_ptr, 0.0)
  expect_equal(ts$min_time(), 0.0)

  expect_error(ts_ptr_max_time())
  expect_error(ts_ptr_max_time(ts))
  d_ptr <- ts_ptr_max_time(ts_ptr)
  expect_true(is.numeric(d_ptr))
  expect_equal(d_ptr, 7.470281689748594)
  expect_equal(ts$max_time(), 7.470281689748594)

  # ---- tc_ptr_summary() ----

  # Simple comparison of summaries
  expect_error(tc_ptr_summary(tc))
  n_ptr_tc <- tc_ptr_summary(tc_ptr)
  n_ptr_ts <- ts_ptr_summary(ts_ptr)
  shared_items <- c(
    "num_provenances",
    "num_populations",
    "num_migrations",
    "num_individuals",
    "num_nodes",
    "num_edges",
    "num_sites",
    "num_mutations",
    "sequence_length",
    "time_units"
  )
  expect_equal(n_ptr_tc, n_ptr_ts[shared_items])

  # ---- ts_ptr_print() and ts$print() ----

  # Simple comparison of summaries
  expect_error(
    ts_ptr_print("not an externalptr object"),
    regexp = "ts must be an object of externalptr class!"
  )
  p_ptr <- ts_ptr_print(ts_ptr)
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

  # ---- tc_ptr_print() and tc$print() ----

  # Simple comparison of summaries
  expect_error(
    tc_ptr_print("not an externalptr object"),
    regexp = "tc must be an object of externalptr class!"
  )
  p_ptr <- tc_ptr_print(tc_ptr)
  p <- tc$print()
  expect_equal(
    p,
    list(
      tc = data.frame(
        property = c(
          "sequence_length",
          "time_units",
          "has_metadata"
        ),
        value = c(10000, "generations", FALSE)
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

  # ---- ts_ptr_dump() ----

  expect_error(ts_ptr_dump())
  expect_error(ts_ptr_dump(nonexistent_ts))
  expect_error(ts_ptr_dump(file = 1))
  expect_error(ts_ptr_dump(nonexistent_ts, file = 1))
  expect_error(ts_ptr_dump(1, file = 1))
  expect_error(ts_ptr_dump(1, file = "1"))
  expect_error(ts_ptr_dump(1, file = 1))
  expect_error(ts_ptr_dump(ts_ptr))
  expect_error(ts_ptr_dump(ts))
  bad_path <- file.path(tempdir(), "no_such_dir", "out.trees")
  expect_error(ts_ptr_dump(ts_ptr, file = bad_path))
  expect_error(
    ts_ptr_dump(ts_ptr, file = tempfile(fileext = ".trees"), options = 1L),
    regexp = "does not support non-zero options"
  )

  # Write ts to disk, read it back, and check that nums are still the same
  dump_file <- tempfile(fileext = ".trees")
  ts_ptr_dump(ts_ptr, dump_file)
  rm(ts_ptr)
  ts_ptr <- ts_ptr_load(dump_file)

  # Simple comparison of summaries
  n <- ts_ptr_summary(ts_ptr)
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

  # ---- tc_ptr_dump() ----

  expect_error(tc_ptr_dump())
  expect_error(tc_ptr_dump(nonexistent_ts))
  expect_error(tc_ptr_dump(file = 1))
  expect_error(tc_ptr_dump(nonexistent_ts, file = 1))
  expect_error(tc_ptr_dump(1, file = 1))
  expect_error(tc_ptr_dump(1, file = "1"))
  expect_error(tc_ptr_dump(1, file = 1))
  expect_error(tc_ptr_dump(tc_ptr))
  expect_error(tc_ptr_dump(tc))
  bad_path <- file.path(tempdir(), "no_such_dir", "out.trees")
  expect_error(tc_ptr_dump(tc_ptr, file = bad_path))
  expect_error(
    tc_ptr_dump(tc_ptr, file = tempfile(fileext = ".trees"), options = 1L),
    regexp = "does not support non-zero options"
  )

  # Write ts to disk, read it back, and check that nums are still the same
  dump_file <- tempfile(fileext = ".trees")
  tc_ptr_dump(tc_ptr, dump_file)
  rm(tc_ptr)
  tc_ptr <- tc_ptr_load(dump_file)
  ts_ptr <- ts_ptr_load(dump_file)

  # Simple comparison of summaries
  n_ts <- ts_ptr_summary(ts_ptr)
  n_tc <- tc_ptr_summary(tc_ptr)

  shared_items <- c(
    "num_provenances",
    "num_populations",
    "num_migrations",
    "num_individuals",
    "num_nodes",
    "num_edges",
    "num_sites",
    "num_mutations",
    "sequence_length",
    "time_units"
  )
  expect_equal(n_ts[shared_items], n_tc)

  # ---- ts$dump() ----

  expect_error(ts$dump())
  expect_error(ts$write())
  expect_error(ts$dump(file = 1))
  expect_error(
    ts$dump(file = tempfile(fileext = ".trees"), options = 1L),
    regexp = "unused argument"
  )
  bad_path <- file.path(tempdir(), "no_such_dir", "out.trees")
  expect_error(ts$dump(ts, file = bad_path))

  # Write ts to disk, read it back, and check that nums are still the same
  dump_file <- tempfile(fileext = ".trees")
  ts$dump(dump_file)
  rm(ts)
  ts <- ts_load(dump_file)

  # Simple comparison of summaries
  n_ptr <- ts_ptr_summary(ts$pointer)
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

  # ---- tc$dump() ----

  expect_error(tc$dump())
  expect_error(tc$write())
  expect_error(tc$dump(file = 1))
  expect_error(
    tc$dump(file = tempfile(fileext = ".trees"), options = 1L),
    regexp = "unused argument"
  )
  bad_path <- file.path(tempdir(), "no_such_dir", "out.trees")
  expect_error(tc$dump(ts, file = bad_path))

  # Write ts to disk, read it back, and check that nums are still the same
  dump_file <- tempfile(fileext = ".trees")
  tc$dump(dump_file)
  rm(tc)
  tc <- tc_load(dump_file)

  # Simple comparison of summaries
  n_ptr <- tc_ptr_summary(tc$pointer)
  expect_equal(
    n_ptr,
    list(
      # we got these numbers from inst/examples/create_test.trees.R
      "num_provenances" = 2L,
      "num_populations" = 1L,
      "num_migrations" = 0L,
      "num_individuals" = 80L,
      "num_nodes" = 344L,
      "num_edges" = 414L,
      "num_sites" = 2376L,
      "num_mutations" = 2700L,
      "sequence_length" = 10000.0,
      "time_units" = "generations"
    )
  )

  # ---- ts_ptr_metadata_length() ----

  # Simple comparison of the lengths of metadata
  n_ptr <- ts_ptr_metadata_length(ts_ptr)
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
  ts_ptr <- ts_ptr_load(ts_file)
  ts <- ts_load(ts_file)

  n_ptr <- ts_ptr_summary(ts_ptr)
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

  m_ptr <- ts_ptr_metadata_length(ts_ptr)
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

  p_ptr <- ts_ptr_print(ts_ptr)
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

  # ---- tc_ptr_metadata_length() ----

  # Simple comparison of the lengths of metadata
  n_ptr_tc <- tc_ptr_metadata_length(tc_ptr)
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts_ptr <- ts_ptr_load(ts_file)
  n_ptr_ts <- ts_ptr_metadata_length(ts_ptr)
  names(n_ptr_tc)[1] <- "ts"
  expect_equal(n_ptr_tc, n_ptr_ts)

  ts_file <- system.file("examples/test2.trees", package = "RcppTskit")
  tc_ptr <- tc_ptr_load(ts_file)
  tc <- tc_load(ts_file)
  ts_ptr <- ts_ptr_load(ts_file)
  ts <- ts_load(ts_file)

  n_ptr_tc <- tc_ptr_summary(tc_ptr)
  n_ptr_ts <- ts_ptr_summary(ts_ptr)
  shared_items <- c(
    "num_provenances",
    "num_populations",
    "num_migrations",
    "num_individuals",
    "num_nodes",
    "num_edges",
    "num_sites",
    "num_mutations",
    "sequence_length",
    "time_units"
  )
  expect_equal(n_ts[shared_items], n_tc)

  m_ptr_tc <- tc_ptr_metadata_length(tc_ptr)
  m_ptr_ts <- ts_ptr_metadata_length(ts_ptr)
  names(m_ptr_tc)[1] <- "ts"
  expect_equal(m_ptr_tc, m_ptr_ts)

  p_ptr <- tc_ptr_print(tc_ptr)
  p <- tc$print()
  expect_equal(
    p_ptr,
    list(
      tc = data.frame(
        property = c(
          "sequence_length",
          "time_units",
          "has_metadata"
        ),
        value = c(10000, "generations", TRUE)
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
