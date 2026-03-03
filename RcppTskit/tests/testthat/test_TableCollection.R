test_that("TableCollection$new() works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  expect_error(
    TableCollection$new(),
    regexp = "Provide a file or an external pointer \\(xptr\\)!"
  )
  expect_error(
    TableCollection$new(file = "xyz", xptr = "y"),
    regexp = "Provide either a file or an external pointer \\(xptr\\), but not both!"
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
    TableCollection$new(xptr = 1L),
    regexp = "external pointer \\(xptr\\) must be an object of externalptr class!"
  )
})

test_that("TableCollection and TreeSequence round-trip works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  test_trees_file_uuid <- "79ec383f-a57d-b44f-2a5c-f0feecbbcb32"
  ts_xptr <- rtsk_treeseq_load(ts_file)

  # ---- Integer bitmask of tskit flags ----

  # See rtsk_treeseq_copy_tables() and rtsk_treeseq_init() documentation
  unsupported_options <- bitwShiftL(1L, 27)
  supported_copy_option <- bitwShiftL(1L, 0)
  supported_init_options <- bitwOr(bitwShiftL(1L, 0), bitwShiftL(1L, 1))
  expect_error(
    rtsk_treeseq_copy_tables(ts_xptr, options = -1),
    regexp = "rtsk_treeseq_copy_tables does not support negative options"
  )
  expect_error(
    rtsk_treeseq_copy_tables(ts_xptr, options = bitwShiftL(1L, 30)),
    regexp = "does not support TSK_NO_INIT"
  )
  expect_error(
    rtsk_treeseq_copy_tables(ts_xptr, options = unsupported_options),
    regexp = "only supports copy option TSK_COPY_FILE_UUID"
  )
  expect_true(is(
    rtsk_treeseq_copy_tables(ts_xptr, options = supported_copy_option),
    "externalptr"
  ))

  # ---- ts_xptr --> tc_xptr --> ts_xptr ----

  tc_xptr <- rtsk_treeseq_copy_tables(ts_xptr)
  expect_true(is(tc_xptr, "externalptr"))
  p <- rtsk_table_collection_print(tc_xptr)
  expect_equal(
    p,
    list(
      tc = data.frame(
        property = c(
          "sequence_length",
          "has_reference_sequence",
          "time_units",
          "has_metadata",
          "file_uuid",
          "has_index"
        ),
        value = as.character(c(
          100,
          FALSE,
          "generations",
          FALSE,
          NA_character_,
          TRUE
        ))
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
        number = as.character(c(2, 1, 0, 8, 39, 59, 25, 30)),
        has_metadata = as.character(c(
          NA, # provenances have no metadata
          TRUE,
          FALSE,
          FALSE,
          FALSE,
          FALSE,
          FALSE,
          FALSE
        ))
      )
    )
  )
  expect_error(
    rtsk_treeseq_init(tc_xptr, options = -1),
    regexp = "rtsk_treeseq_init does not support negative options"
  )
  expect_error(
    rtsk_treeseq_init(tc_xptr, options = bitwShiftL(1L, 28)),
    regexp = "does not support TSK_TAKE_OWNERSHIP"
  )
  expect_error(
    rtsk_treeseq_init(tc_xptr, options = unsupported_options),
    regexp = "only supports init options"
  )
  expect_true(is(
    rtsk_treeseq_init(tc_xptr, options = supported_init_options),
    "externalptr"
  ))
  ts_xptr2 <- rtsk_treeseq_init(tc_xptr)
  p_ts_xptr <- rtsk_treeseq_print(ts_xptr)
  p_ts_xptr2 <- rtsk_treeseq_print(ts_xptr2)
  i_file_uuid <- p_ts_xptr$ts$property == "file_uuid"
  p_ts_xptr$ts$value[i_file_uuid] <- NA_character_
  p_ts_xptr2$ts$value[p_ts_xptr2$ts$property == "file_uuid"] <- NA_character_
  expect_equal(p_ts_xptr, p_ts_xptr2)

  # ---- ts --> tc --> ts ----

  ts <- ts_load(ts_file)
  expect_error(
    ts$dump_tables(options = "bla"),
    regexp = "unused argument"
  )
  expect_no_error(ts$dump_tables())

  tc <- ts$dump_tables()
  expect_true(is(tc, "TableCollection"))
  # jarl-ignore implicit_assignment:  it's just a test
  tmp <- capture.output(p <- tc$print())
  expect_equal(
    p,
    list(
      tc = data.frame(
        property = c(
          "sequence_length",
          "has_reference_sequence",
          "time_units",
          "has_metadata",
          "file_uuid",
          "has_index"
        ),
        value = as.character(c(
          100,
          FALSE,
          "generations",
          FALSE,
          NA_character_,
          TRUE
        ))
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
        number = as.character(c(2, 1, 0, 8, 39, 59, 25, 30)),
        has_metadata = as.character(c(
          NA, # provenances have no metadata
          TRUE,
          FALSE,
          FALSE,
          FALSE,
          FALSE,
          FALSE,
          FALSE
        ))
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
  # jarl-ignore implicit_assignment: it's just a test
  tmp <- capture.output(ts_print <- ts$print())
  # jarl-ignore implicit_assignment: it's just a test
  tmp <- capture.output(ts2_print <- ts2$print())
  i_file_uuid <- ts_print$ts$property == "file_uuid"
  ts_print$ts$value[i_file_uuid] <- NA_character_
  ts2_print$ts$value[ts2_print$ts$property == "file_uuid"] <- NA_character_
  expect_equal(ts_print, ts2_print)

  # Edge cases
  expect_error(
    test_rtsk_treeseq_copy_tables_forced_error(ts_xptr),
    regexp = "TSK_ERR_BAD_PARAM_VALUE"
  )
  expect_true(is(rtsk_treeseq_copy_tables(ts_xptr), "externalptr"))

  expect_error(
    test_rtsk_treeseq_init_forced_error(tc_xptr),
    regexp = "TSK_ERR_BAD_PARAM_VALUE"
  )
  expect_true(is(rtsk_treeseq_init(tc_xptr), "externalptr"))

  expect_error(
    test_rtsk_table_collection_build_index_forced_error(tc_xptr),
    regexp = "TSK_ERR_NODE_OUT_OF_BOUNDS"
  )
})

test_that("TableCollection index lifecycle and tree_sequence index handling works", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts <- ts_load(ts_file)
  tc <- ts$dump_tables()
  tc_xptr <- tc$xptr
  build_index_option <- bitwShiftL(1L, 0)

  expect_error(rtsk_table_collection_build_index())
  expect_error(rtsk_table_collection_build_index(tc))
  expect_error(rtsk_table_collection_drop_index())
  expect_error(rtsk_table_collection_drop_index(tc))

  expect_true(tc$has_index())
  expect_no_error(tc$drop_index())
  expect_false(tc$has_index())

  expect_error(
    rtsk_treeseq_init(tc_xptr, options = 0L),
    regexp = "TSK_ERR_TABLES_NOT_INDEXED"
  )
  expect_true(is(
    rtsk_treeseq_init(tc_xptr, options = build_index_option),
    "externalptr"
  ))
  # rtsk_treeseq_init() builds indexes in an internal ts, not in tc itself,
  # so the tc in this environment will not have indexes here
  expect_false(tc$has_index())
  ts2 <- tc$tree_sequence()
  expect_true(is(ts2, "TreeSequence"))
  expect_true(tc$has_index())

  expect_no_error(tc$drop_index())
  expect_false(tc$has_index())
  expect_no_error(tc$build_index())
  expect_true(tc$has_index())
})
