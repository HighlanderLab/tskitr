test_that("low-level variant iterator decodes all sites", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts_xptr <- rtsk_treeseq_load(ts_file)

  it <- rtsk_variant_iterator_init(ts_xptr)
  n_sites <- as.integer(rtsk_treeseq_get_num_sites(ts_xptr))

  out <- vector("list", n_sites)
  for (j in seq_len(n_sites)) {
    out[[j]] <- rtsk_variant_iterator_next(it)
    expect_true(is.list(out[[j]]))
    expect_equal(
      sort(names(out[[j]])),
      c("alleles", "genotypes", "has_missing_data", "position", "site_id")
    )
  }
  expect_null(rtsk_variant_iterator_next(it))
})

test_that("low-level variant iterator supports left-right site filtering", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts_xptr <- rtsk_treeseq_load(ts_file)

  full_it <- rtsk_variant_iterator_init(ts_xptr)
  first <- rtsk_variant_iterator_next(full_it)
  second <- rtsk_variant_iterator_next(full_it)
  expect_false(is.null(first))
  expect_false(is.null(second))

  left <- first$position
  right <- second$position + 1e-12

  it <- rtsk_variant_iterator_init(ts_xptr, left = left, right = right)
  v1 <- rtsk_variant_iterator_next(it)
  v2 <- rtsk_variant_iterator_next(it)
  v3 <- rtsk_variant_iterator_next(it)

  expect_equal(v1$site_id, first$site_id)
  expect_equal(v2$site_id, second$site_id)
  expect_null(v3)
})

test_that("low-level variant iterator supports sample subsets", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts_xptr <- rtsk_treeseq_load(ts_file)

  samples <- c(0L, 1L, 2L)
  it <- rtsk_variant_iterator_init(ts_xptr, samples = samples)
  v <- rtsk_variant_iterator_next(it)

  expect_false(is.null(v))
  expect_length(v$genotypes, length(samples))
})

test_that("low-level variant iterator validates bounds", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts_xptr <- rtsk_treeseq_load(ts_file)
  seq_len <- rtsk_treeseq_get_sequence_length(ts_xptr)

  expect_error(
    rtsk_variant_iterator_init(ts_xptr, left = NaN, right = seq_len),
    "left and right must be finite numbers"
  )
  expect_error(
    rtsk_variant_iterator_init(ts_xptr, left = -1, right = seq_len),
    "left and right must be >= 0"
  )
  expect_error(
    rtsk_variant_iterator_init(ts_xptr, left = seq_len + 1, right = seq_len),
    "left and right must be <= sequence length"
  )
  expect_error(
    rtsk_variant_iterator_init(ts_xptr, left = 1, right = 0.5),
    "left must be <= right"
  )
})

test_that("low-level variant iterator validates site-index range helper", {
  expect_error(
    test_variant_site_index_range("2147483648", "0"),
    "Site index exceeds tsk_id_t range"
  )
})

test_that("low-level variant iterator validates samples and alleles inputs", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts_xptr <- rtsk_treeseq_load(ts_file)
  n_nodes <- as.integer(rtsk_treeseq_get_num_nodes(ts_xptr))

  expect_error(
    rtsk_variant_iterator_init(ts_xptr, samples = c(n_nodes + 1L)),
    "Node out of bounds"
  )

  it <- rtsk_variant_iterator_init(ts_xptr, alleles = c("A", "C", "G", "T"))
  v <- rtsk_variant_iterator_next(it)
  expect_false(is.null(v))
})

test_that("low-level variant iterator decode error path can be triggered", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts_xptr <- rtsk_treeseq_load(ts_file)
  n_sites <- as.integer(rtsk_treeseq_get_num_sites(ts_xptr))

  it <- rtsk_variant_iterator_init(ts_xptr)
  test_rtsk_variant_iterator_set_site_bounds(
    it,
    next_site_id = n_sites,
    stop_site_id = n_sites + 1L
  )
  expect_error(
    rtsk_variant_iterator_next(it),
    regexp = "Site out of bounds|Bounds check"
  )
})

test_that("low-level variant iterator maps null alleles to NA_character_", {
  ts_file <- system.file("examples/test.trees", package = "RcppTskit")
  ts_xptr <- rtsk_treeseq_load(ts_file)
  it <- rtsk_variant_iterator_init(ts_xptr)
  test_rtsk_variant_iterator_force_null_first_allele(TRUE)
  v <- rtsk_variant_iterator_next(it)
  expect_false(is.null(v))
  expect_true(anyNA(v$alleles))
})
