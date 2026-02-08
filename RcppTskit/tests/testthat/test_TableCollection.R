test_that("TableCollection$new() works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  expect_error(
    TableCollection$new(),
    regexp = "Provide a file or a pointer!"
  )
  expect_error(
    TableCollection$new(file = "xyz", pointer = "y"),
    regexp = "Provide either a file or a pointer, but not both!"
  )
  expect_error(
    TableCollection$new(file = 1L),
    regexp = "file must be a character string!"
  )
  expect_error(
    TableCollection$new(file = "bla", skip_tables = "y"),
    regexp = "skip_tables must be TRUE/FALSE!"
  )
  expect_error(
    TableCollection$new(file = "bla", skip_reference_sequence = 1),
    regexp = "skip_reference_sequence must be TRUE/FALSE!"
  )
  expect_no_error(
    TableCollection$new(
      file = ts_file,
      skip_tables = FALSE,
      skip_reference_sequence = FALSE
    )
  )
  expect_no_error(
    TableCollection$new(
      file = ts_file,
      skip_tables = TRUE,
      skip_reference_sequence = TRUE
    )
  )
  expect_no_error(TableCollection$new(ts_file))
  expect_error(
    TableCollection$new(pointer = 1L),
    regexp = "pointer must be an object of externalptr class!"
  )
})

test_that("TableCollection and TreeSequence round-trip works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts_ptr <- ts_ptr_load(ts_file)

  # ---- Integer bitmask of tskit flags ----

  # See ts_ptr_to_tc_ptr() and tc_ptr_to_ts_ptr() documentation
  unsupported_options <- bitwShiftL(1L, 27)
  supported_copy_option <- bitwShiftL(1L, 0)
  supported_init_options <- bitwOr(bitwShiftL(1L, 0), bitwShiftL(1L, 1))
  expect_error(
    ts_ptr_to_tc_ptr(ts_ptr, options = bitwShiftL(1L, 30)),
    regexp = "does not support TSK_NO_INIT"
  )
  expect_error(
    ts_ptr_to_tc_ptr(ts_ptr, options = unsupported_options),
    regexp = "only supports copy option TSK_COPY_FILE_UUID"
  )
  expect_true(is(
    ts_ptr_to_tc_ptr(ts_ptr, options = supported_copy_option),
    "externalptr"
  ))

  # ---- ts_ptr --> tc_ptr --> ts_ptr ----

  tc_ptr <- ts_ptr_to_tc_ptr(ts_ptr)
  expect_true(is(tc_ptr, "externalptr"))
  p <- tc_ptr_print(tc_ptr)
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
  expect_error(
    tc_ptr_to_ts_ptr(tc_ptr, options = bitwShiftL(1L, 28)),
    regexp = "does not support TSK_TAKE_OWNERSHIP"
  )
  expect_error(
    tc_ptr_to_ts_ptr(tc_ptr, options = unsupported_options),
    regexp = "only supports init options"
  )
  expect_true(is(
    tc_ptr_to_ts_ptr(tc_ptr, options = supported_init_options),
    "externalptr"
  ))
  ts_ptr2 <- tc_ptr_to_ts_ptr(tc_ptr)
  expect_equal(ts_ptr_print(ts_ptr), ts_ptr_print(ts_ptr2))

  # ---- ts --> tc --> ts ----

  ts <- ts_load(ts_file)
  expect_error(
    ts$dump_tables(options = "bla"),
    regexp = "unused argument"
  )
  expect_no_error(ts$dump_tables())

  tc <- ts$dump_tables()
  expect_true(is(tc, "TableCollection"))
  expect_output(tc$print(), NA) # non-interactive mode
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

  expect_error(
    tc$tree_sequence(options = "bla"),
    regexp = "unused argument"
  )
  expect_no_error(tc$tree_sequence())

  ts2 <- tc$tree_sequence()
  expect_true(is(ts2, "TreeSequence"))
  expect_output(ts$print(), NA) # non-interactive mode
  expect_equal(ts$print(), ts2$print())

  # Edge cases
  expect_error(
    test_ts_ptr_to_tc_ptr_forced_error(ts_ptr),
    regexp = "TSK_ERR_BAD_PARAM_VALUE"
  )
  expect_true(is(ts_ptr_to_tc_ptr(ts_ptr), "externalptr"))

  expect_error(
    test_tc_ptr_to_ts_ptr_forced_error(tc_ptr),
    regexp = "TSK_ERR_BAD_PARAM_VALUE"
  )
  expect_true(is(tc_ptr_to_ts_ptr(tc_ptr), "externalptr"))
})
