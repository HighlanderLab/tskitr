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

test_that("table_collection_sort wrapper validates inputs and sorts in place", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)

  expect_error(
    rtsk_table_collection_sort(tc_xptr, edge_start = NA_integer_),
    regexp = "edge_start must not be NA_integer_ in rtsk_table_collection_sort"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, edge_start = -1L),
    regexp = "edge_start must be >= 0 in rtsk_table_collection_sort"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, site_start = NA_integer_),
    regexp = "site_start must not be NA_integer_ in rtsk_table_collection_sort"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, site_start = -1L),
    regexp = "site_start must be >= 0 in rtsk_table_collection_sort"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, mutation_start = NA_integer_),
    regexp = "mutation_start must not be NA_integer_ in rtsk_table_collection_sort"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, mutation_start = -1L),
    regexp = "mutation_start must be >= 0 in rtsk_table_collection_sort"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, options = bitwShiftL(1L, 4)),
    regexp = "only supports options"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, options = -1L),
    regexp = "does not support negative options"
  )
  expect_error(
    rtsk_table_collection_sort(tc_xptr, site_start = 1L),
    regexp = "SORT_OFFSET_NOT_SUPPORTED|Sort offset"
  )
  expect_no_error(rtsk_table_collection_sort(tc_xptr))
  expect_no_error(rtsk_table_collection_sort(tc_xptr, 0L, 0L, 0L))

  expect_error(
    tc$sort(edge_start = NA_integer_),
    regexp = "edge_start must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$sort(edge_start = -1L),
    regexp = "edge_start must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$sort(site_start = NA_integer_),
    regexp = "site_start must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$sort(mutation_start = NA_integer_),
    regexp = "mutation_start must be a non-NA zero or positive integer scalar!"
  )
  expect_no_error(tc$sort())
  expect_no_error(tc$sort(
    edge_start = 0L,
    site_start = 0L,
    mutation_start = 0L
  ))
})

test_that("individual_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_individuals(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)$individuals

  expect_error(
    rtsk_individual_table_add_row(tc_xptr, flags = -1L),
    regexp = "rtsk_individual_table_add_row does not support negative flags"
  )

  new_id <- rtsk_individual_table_add_row(
    tc = tc_xptr,
    flags = 0L,
    location = c(1.25, -2.5),
    metadata = charToRaw("abc")
  )
  expect_equal(new_id, as.integer(n_before)) # since IDs are 0-based
  expect_equal(
    as.integer(rtsk_table_collection_get_num_individuals(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$individuals),
    as.integer(m_before) + 3L
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- tc$num_individuals()
  new_id_method <- tc$individual_table_add_row()
  expect_equal(new_id_method, as.integer(n_before_method))
  expect_equal(
    as.integer(tc$num_individuals()),
    as.integer(n_before_method) + 1L
  )

  tc_xptr <- rtsk_table_collection_load(ts_file)

  n0 <- as.integer(rtsk_table_collection_get_num_individuals(tc_xptr))
  m0 <- as.integer(rtsk_table_collection_metadata_length(tc_xptr)$individuals)

  # Defaults map to NULL in the generated R wrapper and should be accepted.
  id0 <- rtsk_individual_table_add_row(tc_xptr)
  expect_equal(id0, n0)
  expect_equal(
    as.integer(rtsk_table_collection_get_num_individuals(tc_xptr)),
    n0 + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$individuals),
    m0
  )

  # Explicit NULL should also be accepted and behave like empty vectors.
  id1 <- rtsk_individual_table_add_row(
    tc = tc_xptr,
    flags = 0L,
    location = NULL,
    parents = NULL,
    metadata = NULL
  )
  expect_equal(id1, n0 + 1L)

  # Parent IDs are provided as integer vectors and should be accepted.
  id2 <- rtsk_individual_table_add_row(
    tc = tc_xptr,
    flags = 0L,
    parents = c(id0, id1),
    location = numeric(),
    metadata = raw()
  )
  expect_equal(id2, n0 + 2L)

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_individuals())
  expect_no_error(
    tc$individual_table_add_row(
      flags = 0L,
      location = NULL,
      parents = c(id1, id2),
      metadata = NULL
    )
  )
  expect_equal(as.integer(tc$num_individuals()), n_before_method + 1L)

  m_before_char <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$individuals
  )
  expect_no_warning(tc$individual_table_add_row(metadata = "abc"))
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$individuals),
    m_before_char + 3L
  )
  m_before_raw <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$individuals
  )
  expect_no_error(tc$individual_table_add_row(metadata = charToRaw("xyz")))
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$individuals),
    m_before_raw + 3L
  )
  expect_error(
    tc$individual_table_add_row(flags = -1L),
    regexp = "flags must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$individual_table_add_row(location = c(1, NA_real_)),
    regexp = "location must be NULL or a numeric vector with no NA values!"
  )
  expect_error(
    tc$individual_table_add_row(parents = c(NA_integer_)),
    regexp = "parents must be NULL or an integer vector with no NA values!"
  )
  expect_error(
    test_rtsk_individual_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )

  expect_error(
    tc$individual_table_add_row(metadata = c("a", "b")),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$individual_table_add_row(metadata = NA_character_),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$individual_table_add_row(metadata = 1L),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
})

test_that("node_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_nodes(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)$nodes

  expect_error(
    rtsk_node_table_add_row(tc_xptr, flags = -1L),
    regexp = "rtsk_node_table_add_row does not support negative flags"
  )

  new_id <- rtsk_node_table_add_row(
    tc = tc_xptr,
    flags = 1L,
    time = 1.25,
    population = 0L,
    individual = 0L,
    metadata = charToRaw("abc")
  )
  expect_equal(new_id, as.integer(n_before)) # since IDs are 0-based
  expect_equal(
    as.integer(rtsk_table_collection_get_num_nodes(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$nodes),
    as.integer(m_before) + 3L
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- tc$num_nodes()
  new_id_method <- tc$node_table_add_row()
  expect_equal(new_id_method, as.integer(n_before_method))
  expect_equal(
    as.integer(tc$num_nodes()),
    as.integer(n_before_method) + 1L
  )

  tc_xptr <- rtsk_table_collection_load(ts_file)

  n0 <- as.integer(rtsk_table_collection_get_num_nodes(tc_xptr))
  m0 <- as.integer(rtsk_table_collection_metadata_length(tc_xptr)$nodes)

  # Testing defaults
  id0 <- rtsk_node_table_add_row(tc_xptr)
  expect_equal(id0, n0)
  expect_equal(
    as.integer(rtsk_table_collection_get_num_nodes(tc_xptr)),
    n0 + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$nodes),
    m0
  )

  # Explicit NULL metadata should also be accepted.
  id1 <- rtsk_node_table_add_row(
    tc = tc_xptr,
    flags = 0L,
    time = 2.5,
    population = -1L,
    individual = -1L,
    metadata = NULL
  )
  expect_equal(id1, n0 + 1L)

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_nodes())
  expect_no_error(
    tc$node_table_add_row(
      flags = 1L,
      time = 3.5,
      population = 0L,
      individual = -1L,
      metadata = NULL
    )
  )
  expect_equal(as.integer(tc$num_nodes()), n_before_method + 1L)
  expect_no_error(tc$node_table_add_row(population = NULL, individual = NULL))
  expect_equal(as.integer(tc$num_nodes()), n_before_method + 2L)

  m_before_char <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$nodes
  )
  expect_no_warning(tc$node_table_add_row(metadata = "abc"))
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$nodes),
    m_before_char + 3L
  )
  m_before_raw <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$nodes
  )
  expect_no_error(tc$node_table_add_row(metadata = charToRaw("xyz")))
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$nodes),
    m_before_raw + 3L
  )

  expect_error(
    tc$node_table_add_row(flags = -1L),
    regexp = "flags must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$node_table_add_row(time = NA_real_),
    regexp = "time must be a non-NA numeric scalar!"
  )
  expect_error(
    tc$node_table_add_row(population = NA_integer_),
    regexp = "population must be -1, NULL, or a non-NA integer scalar!"
  )
  expect_error(
    tc$node_table_add_row(individual = NA_integer_),
    regexp = "individual must be -1, NULL, or a non-NA integer scalar!"
  )
  expect_error(
    tc$node_table_add_row(metadata = c("a", "b")),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$node_table_add_row(metadata = NA_character_),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$node_table_add_row(metadata = 1L),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    test_rtsk_node_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )
})

test_that("node_table_get_row wrapper returns node row fields and validates IDs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  tc <- TableCollection$new(xptr = tc_xptr)
  last_node <- as.integer(rtsk_table_collection_get_num_nodes(tc_xptr)) - 1L

  first_row_low <- rtsk_node_table_get_row(tc_xptr, 0L)
  first_row_method <- tc$node_table_get_row(0L)
  last_row_low <- rtsk_node_table_get_row(tc_xptr, last_node)
  last_row_method <- tc$node_table_get_row(last_node)

  # we got these values from inst/examples/create_test.trees.py
  expect_equal(
    first_row_low,
    list(
      id = 0L,
      flags = 1L,
      time = 0,
      population = 0L,
      individual = 0L,
      metadata = raw(0)
    )
  )
  expect_equal(first_row_method, first_row_low)
  # we got these values from inst/examples/create_test.trees.py
  expect_equal(
    last_row_low,
    list(
      id = 38L,
      flags = 0L,
      time = 6.96199333719081,
      population = 0L,
      individual = -1L,
      metadata = raw(0)
    )
  )
  expect_equal(last_row_method, last_row_low)

  expect_error(
    rtsk_node_table_get_row(tc_xptr, NA_integer_),
    regexp = "TSK_ERR_NODE_OUT_OF_BOUNDS"
  )
  expect_error(
    rtsk_node_table_get_row(tc_xptr, -1L),
    regexp = "TSK_ERR_NODE_OUT_OF_BOUNDS"
  )
  expect_error(
    tc$node_table_get_row(NA_integer_),
    regexp = "index must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$node_table_get_row(-1L),
    regexp = "index must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$node_table_get_row(0),
    regexp = "index must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    rtsk_node_table_get_row(tc_xptr, 999999L),
    regexp = "TSK_ERR_NODE_OUT_OF_BOUNDS"
  )

  new_id <- tc$node_table_add_row(
    flags = 1L,
    time = 12.5,
    population = 0L,
    individual = -1L,
    metadata = charToRaw("abc")
  )
  row_low <- rtsk_node_table_get_row(tc_xptr, new_id)
  row_method <- tc$node_table_get_row(new_id)

  expect_equal(
    sort(names(row_low)),
    c("flags", "id", "individual", "metadata", "population", "time")
  )
  expect_equal(row_low$id, new_id)
  expect_equal(row_low$flags, 1L)
  expect_equal(row_low$time, 12.5)
  expect_equal(row_low$population, 0L)
  expect_equal(row_low$individual, -1L)
  expect_equal(row_low$metadata, charToRaw("abc"))
  expect_equal(row_method, row_low)
})

test_that("edge_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_edges(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)$edges

  parent <- 0L
  child <- 1L

  new_id <- rtsk_edge_table_add_row(
    tc = tc_xptr,
    left = 0,
    right = 1,
    parent = parent,
    child = child,
    metadata = charToRaw("abc")
  )
  expect_equal(new_id, as.integer(n_before)) # since IDs are 0-based
  expect_equal(
    as.integer(rtsk_table_collection_get_num_edges(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$edges),
    as.integer(m_before) + 3L
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- tc$num_edges()
  new_id_method <- tc$edge_table_add_row(
    left = 1,
    right = 2,
    parent = parent,
    child = child
  )
  expect_equal(new_id_method, as.integer(n_before_method))
  expect_equal(
    as.integer(tc$num_edges()),
    as.integer(n_before_method) + 1L
  )

  tc_xptr <- rtsk_table_collection_load(ts_file)

  n0 <- as.integer(rtsk_table_collection_get_num_edges(tc_xptr))
  m0 <- as.integer(rtsk_table_collection_metadata_length(tc_xptr)$edges)

  # Explicit NULL metadata should be accepted.
  id0 <- rtsk_edge_table_add_row(
    tc = tc_xptr,
    left = 0,
    right = 1,
    parent = parent,
    child = child,
    metadata = NULL
  )
  expect_equal(id0, n0)
  expect_equal(
    as.integer(rtsk_table_collection_get_num_edges(tc_xptr)),
    n0 + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$edges),
    m0
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_edges())
  expect_no_error(
    tc$edge_table_add_row(
      left = 2,
      right = 3,
      parent = parent,
      child = child,
      metadata = NULL
    )
  )
  expect_equal(as.integer(tc$num_edges()), n_before_method + 1L)

  m_before_char <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$edges
  )
  expect_no_warning(
    tc$edge_table_add_row(
      left = 3,
      right = 4,
      parent = parent,
      child = child,
      metadata = "abc"
    )
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$edges),
    m_before_char + 3L
  )
  m_before_raw <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$edges
  )
  expect_no_error(
    tc$edge_table_add_row(
      left = 4,
      right = 5,
      parent = parent,
      child = child,
      metadata = charToRaw("xyz")
    )
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$edges),
    m_before_raw + 3L
  )
  expect_error(
    tc$edge_table_add_row(
      left = NULL,
      right = 6,
      parent = parent,
      child = child
    ),
    regexp = "left must be a non-NA numeric scalar!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = c(5, 6),
      right = 6,
      parent = parent,
      child = child
    ),
    regexp = "left must be a non-NA numeric scalar!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = NULL,
      parent = parent,
      child = child
    ),
    regexp = "right must be a non-NA numeric scalar!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 6,
      parent = parent,
      child = child
    ),
    regexp = "left must be strictly less than right!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 7,
      parent = NULL,
      child = child
    ),
    regexp = "parent must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 7,
      parent = parent,
      child = NULL
    ),
    regexp = "child must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 5,
      right = 6,
      parent = NA_integer_,
      child = child
    ),
    regexp = "parent must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 5,
      right = 6,
      parent = parent,
      child = NA_integer_
    ),
    regexp = "child must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 7,
      parent = parent,
      child = child,
      metadata = c("a", "b")
    ),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 7,
      parent = parent,
      child = child,
      metadata = NA_character_
    ),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    tc$edge_table_add_row(
      left = 6,
      right = 7,
      parent = parent,
      child = child,
      metadata = 1L
    ),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    test_rtsk_edge_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )
})

test_that("site_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_sites(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)[["sites"]]

  new_id <- rtsk_site_table_add_row(
    tc = tc_xptr,
    position = 0.5,
    ancestral_state = "A",
    metadata = charToRaw("abc")
  )
  expect_equal(new_id, as.integer(n_before)) # since IDs are 0-based
  expect_equal(
    as.integer(rtsk_table_collection_get_num_sites(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)[["sites"]]),
    as.integer(m_before) + 3L
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- tc$num_sites()
  new_id_method <- tc$site_table_add_row(position = 1.5, ancestral_state = "G")
  expect_equal(new_id_method, as.integer(n_before_method))
  expect_equal(
    as.integer(tc$num_sites()),
    as.integer(n_before_method) + 1L
  )

  tc_xptr <- rtsk_table_collection_load(ts_file)

  n0 <- as.integer(rtsk_table_collection_get_num_sites(tc_xptr))
  m0 <- as.integer(rtsk_table_collection_metadata_length(tc_xptr)[["sites"]])

  id0 <- rtsk_site_table_add_row(
    tc = tc_xptr,
    position = 2.5,
    ancestral_state = "",
    metadata = NULL
  )
  expect_equal(id0, n0)
  expect_equal(
    as.integer(rtsk_table_collection_get_num_sites(tc_xptr)),
    n0 + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)[["sites"]]),
    m0
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  expect_error(
    tc$site_table_add_row(
      position = 3.5,
      ancestral_state = NULL,
      metadata = NULL
    ),
    regexp = "ancestral_state must be a length-1 non-NA character string!"
  )

  m_before_char <- as.integer(rtsk_table_collection_metadata_length(tc$xptr)[[
    "sites"
  ]])
  expect_no_warning(
    tc$site_table_add_row(
      position = 4.5,
      ancestral_state = "T",
      metadata = "abc"
    )
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)[["sites"]]),
    m_before_char + 3L
  )
  m_before_raw <- as.integer(rtsk_table_collection_metadata_length(tc$xptr)[[
    "sites"
  ]])
  expect_no_error(
    tc$site_table_add_row(
      position = 5.5,
      ancestral_state = "C",
      metadata = charToRaw("xyz")
    )
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)[["sites"]]),
    m_before_raw + 3L
  )

  expect_error(
    tc$site_table_add_row(position = NULL, ancestral_state = "A"),
    regexp = "position must be a non-NA numeric scalar!"
  )
  expect_error(
    tc$site_table_add_row(position = NaN, ancestral_state = "A"),
    regexp = "position must be a non-NA numeric scalar!"
  )
  expect_error(
    tc$site_table_add_row(position = 6.5, ancestral_state = c("A", "B")),
    regexp = "ancestral_state must be a length-1 non-NA character string!"
  )
  expect_error(
    tc$site_table_add_row(position = 6.5, ancestral_state = NA_character_),
    regexp = "ancestral_state must be a length-1 non-NA character string!"
  )
  expect_error(
    tc$site_table_add_row(position = 6.5, ancestral_state = charToRaw("A")),
    regexp = "ancestral_state must be a length-1 non-NA character string!"
  )
  expect_error(
    tc$site_table_add_row(position = 6.5, ancestral_state = 1L),
    regexp = "ancestral_state must be a length-1 non-NA character string!"
  )
  expect_error(
    tc$site_table_add_row(
      position = 6.5,
      ancestral_state = "A",
      metadata = c("a", "b")
    ),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    test_rtsk_site_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )
})

test_that("mutation_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)
  expect_gt(as.integer(rtsk_table_collection_get_num_sites(tc_xptr)), 0L)
  expect_gt(as.integer(rtsk_table_collection_get_num_nodes(tc_xptr)), 0L)
  site <- 0L
  node <- 0L

  n_before <- rtsk_table_collection_get_num_mutations(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)[["mutations"]]

  new_id <- rtsk_mutation_table_add_row(
    tc = tc_xptr,
    site = site,
    node = node,
    parent = -1L,
    time = NaN,
    derived_state = "T",
    metadata = charToRaw("abc")
  )
  expect_equal(new_id, as.integer(n_before)) # since IDs are 0-based
  expect_equal(
    as.integer(rtsk_table_collection_get_num_mutations(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)[["mutations"]]),
    as.integer(m_before) + 3L
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- tc$num_mutations()
  new_id_method <- tc$mutation_table_add_row(
    site = site,
    node = node,
    derived_state = "C"
  )
  expect_equal(new_id_method, as.integer(n_before_method))
  expect_equal(
    as.integer(tc$num_mutations()),
    as.integer(n_before_method) + 1L
  )

  tc_xptr <- rtsk_table_collection_load(ts_file)
  site <- 0L
  node <- 0L

  n0 <- as.integer(rtsk_table_collection_get_num_mutations(tc_xptr))
  m0 <- as.integer(rtsk_table_collection_metadata_length(tc_xptr)[[
    "mutations"
  ]])

  id0 <- rtsk_mutation_table_add_row(
    tc = tc_xptr,
    site = site,
    node = node,
    parent = -1L,
    time = NaN,
    derived_state = "",
    metadata = NULL
  )
  expect_equal(id0, n0)
  expect_equal(
    as.integer(rtsk_table_collection_get_num_mutations(tc_xptr)),
    n0 + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)[["mutations"]]),
    m0
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_mutations())
  expect_no_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      parent = NULL,
      time = NULL,
      derived_state = "T",
      metadata = NULL
    )
  )
  expect_equal(as.integer(tc$num_mutations()), n_before_method + 1L)

  m_before_char <- as.integer(rtsk_table_collection_metadata_length(tc$xptr)[[
    "mutations"
  ]])
  expect_no_warning(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      derived_state = "G",
      metadata = "abc"
    )
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)[["mutations"]]),
    m_before_char + 3L
  )
  m_before_raw <- as.integer(rtsk_table_collection_metadata_length(tc$xptr)[[
    "mutations"
  ]])
  expect_no_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      derived_state = "A",
      metadata = charToRaw("xyz")
    )
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)[["mutations"]]),
    m_before_raw + 3L
  )

  expect_error(
    tc$mutation_table_add_row(site = NULL, node = node, derived_state = "T"),
    regexp = "site must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$mutation_table_add_row(site = site, node = NULL, derived_state = "T"),
    regexp = "node must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      parent = NA_integer_,
      derived_state = "T"
    ),
    regexp = "parent must be -1, NULL, or a non-NA integer scalar!"
  )
  expect_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      time = c(0, 1),
      derived_state = "T"
    ),
    regexp = "time must be NaN, NULL, or a non-NA numeric scalar!"
  )
  expect_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      time = NA_real_,
      derived_state = "T"
    ),
    regexp = "time must be NaN, NULL, or a non-NA numeric scalar!"
  )
  expect_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      time = "foo",
      derived_state = "T"
    ),
    regexp = "time must be NaN, NULL, or a non-NA numeric scalar!"
  )
  expect_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      derived_state = c("a", "b")
    ),
    regexp = "derived_state must be a length-1 non-NA character string!"
  )
  expect_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      derived_state = NA_character_
    ),
    regexp = "derived_state must be a length-1 non-NA character string!"
  )
  expect_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      derived_state = charToRaw("A")
    ),
    regexp = "derived_state must be a length-1 non-NA character string!"
  )
  expect_error(
    tc$mutation_table_add_row(site = site, node = node, derived_state = 1L),
    regexp = "derived_state must be a length-1 non-NA character string!"
  )
  expect_error(
    tc$mutation_table_add_row(
      site = site,
      node = node,
      derived_state = "T",
      metadata = c("a", "b")
    ),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
  expect_error(
    test_rtsk_mutation_table_add_row_forced_error(tc$xptr),
    regexp = "TSK_ERR_TABLE_OVERFLOW"
  )
})

test_that("population_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_populations(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)$populations

  new_id <- rtsk_population_table_add_row(tc_xptr, metadata = charToRaw("abc"))
  expect_equal(new_id, as.integer(n_before))
  expect_equal(
    as.integer(rtsk_table_collection_get_num_populations(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$populations),
    as.integer(m_before) + 3L
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_populations())
  expect_no_error(tc$population_table_add_row())
  expect_equal(as.integer(tc$num_populations()), n_before_method + 1L)

  m_before_char <- as.integer(
    rtsk_table_collection_metadata_length(tc$xptr)$populations
  )
  expect_no_warning(tc$population_table_add_row(metadata = "xyz"))
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc$xptr)$populations),
    m_before_char + 3L
  )

  expect_error(
    tc$population_table_add_row(metadata = c("a", "b")),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
})

test_that("migration_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_migrations(tc_xptr)
  m_before <- rtsk_table_collection_metadata_length(tc_xptr)$migrations

  new_id <- rtsk_migration_table_add_row(
    tc = tc_xptr,
    left = 0,
    right = 1,
    node = 0L,
    source = 0L,
    dest = 0L,
    time = 1.0,
    metadata = charToRaw("abc")
  )
  expect_equal(new_id, as.integer(n_before))
  expect_equal(
    as.integer(rtsk_table_collection_get_num_migrations(tc_xptr)),
    as.integer(n_before) + 1L
  )
  expect_equal(
    as.integer(rtsk_table_collection_metadata_length(tc_xptr)$migrations),
    as.integer(m_before) + 3L
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_migrations())
  expect_no_error(
    tc$migration_table_add_row(
      left = 1,
      right = 2,
      node = 1L,
      source = 0L,
      dest = 0L,
      time = 2.0
    )
  )
  expect_equal(as.integer(tc$num_migrations()), n_before_method + 1L)

  expect_error(
    tc$migration_table_add_row(
      left = 2,
      right = 2,
      node = 0L,
      source = 0L,
      dest = 0L,
      time = 1.0
    ),
    regexp = "left must be strictly less than right!"
  )
  expect_error(
    tc$migration_table_add_row(
      left = 0,
      right = 1,
      node = NA_integer_,
      source = 0L,
      dest = 0L,
      time = 1.0
    ),
    regexp = "node must be a non-NA zero or positive integer scalar!"
  )
  expect_error(
    tc$migration_table_add_row(
      left = 0,
      right = 1,
      node = 0L,
      source = 0L,
      dest = 0L,
      time = NA_real_
    ),
    regexp = "time must be a non-NA numeric scalar!"
  )
  expect_error(
    tc$migration_table_add_row(
      left = 0,
      right = 1,
      node = 0L,
      source = 0L,
      dest = 0L,
      time = 1.0,
      metadata = c("a", "b")
    ),
    regexp = "metadata must be NULL, a length-1 non-NA character string, or a raw vector!"
  )
})

test_that("provenance_table_add_row wrapper expands the table collection and handles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  tc_xptr <- rtsk_table_collection_load(ts_file)

  n_before <- rtsk_table_collection_get_num_provenances(tc_xptr)
  new_id <- rtsk_provenance_table_add_row(
    tc = tc_xptr,
    timestamp = "2025-01-01T00:00:00Z",
    record = "{\"software\":\"RcppTskit\"}"
  )
  expect_equal(new_id, as.integer(n_before))
  expect_equal(
    as.integer(rtsk_table_collection_get_num_provenances(tc_xptr)),
    as.integer(n_before) + 1L
  )

  tc <- TableCollection$new(xptr = tc_xptr)
  n_before_method <- as.integer(tc$num_provenances())
  expect_no_error(
    tc$provenance_table_add_row(
      timestamp = "2025-01-02T00:00:00Z",
      record = "{\"software\":\"RcppTskit\",\"action\":\"test\"}"
    )
  )
  expect_equal(as.integer(tc$num_provenances()), n_before_method + 1L)

  expect_error(
    tc$provenance_table_add_row(
      timestamp = NULL,
      record = "{}"
    ),
    regexp = "timestamp must be a length-1 non-NA character string!"
  )
  expect_error(
    tc$provenance_table_add_row(
      timestamp = "2025-01-01T00:00:00Z",
      record = NA_character_
    ),
    regexp = "record must be a length-1 non-NA character string!"
  )
})
