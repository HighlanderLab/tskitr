#' @title Table collection R6 class (TableCollection)
#' @description An \code{R6} class holding an external pointer to
#' a table collection object. As an \code{R6} class, method-calling looks Pythonic
#' and hence resembles the \code{tskit Python} API. Since the class only
#' holds the pointer, it is lightweight. Currently there is a limited set of
#' \code{R} methods for working with the table collection object.
#' @export
TableCollection <- R6Class(
  classname = "TableCollection",
  public = list(
    #' @field xptr external pointer to the table collection
    xptr = "externalptr",

    #' @description Create a \code{\link{TableCollection}} from a file or an external pointer.
    #' @param file a string specifying the full path of the tree sequence file.
    #' @param skip_tables logical; if \code{TRUE}, load only non-table information.
    #' @param skip_reference_sequence logical; if \code{TRUE}, skip loading
    #'   reference genome sequence information.
    #' @param xptr an external pointer (\code{externalptr}) to a table collection.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://github.com/tskit-dev/tskit/blob/dc394d72d121c99c6dcad88f7a4873880924dd72/python/tskit/tables.py#L3463}.
    #'   TODO: Update URL to TableCollection.load() method #104
    #'         https://github.com/HighlanderLab/RcppTskit/issues/104
    #' @return A \code{\link{TableCollection}} object.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- TableCollection$new(file = ts_file)
    #' is(tc)
    #' tc
    initialize = function(
      file,
      skip_tables = FALSE,
      skip_reference_sequence = FALSE,
      xptr = NULL
    ) {
      if (missing(file) && is.null(xptr)) {
        stop("Provide a file or an external pointer (xptr)!")
      }
      if (!missing(file) && !is.null(xptr)) {
        stop(
          "Provide either a file or an external pointer (xptr), but not both!"
        )
      }
      if (!missing(file)) {
        if (!is.character(file)) {
          stop("file must be a character string!")
        }
        options <- load_args_to_options(
          skip_tables = skip_tables,
          skip_reference_sequence = skip_reference_sequence
        )
        self$xptr <- rtsk_table_collection_load(
          filename = file,
          options = options
        )
      } else {
        if (!is.null(xptr) && !is(xptr, "externalptr")) {
          stop(
            "external pointer (xptr) must be an object of externalptr class!"
          )
        }
        self$xptr <- xptr
      }
      invisible(self)
    },

    #' @description Write a table collection to a file.
    #' @param file a string specifying the full path of the tree sequence file.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/latest/python-api.html#tskit.TableCollection.dump}.
    #' @return No return value; called for side effects.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- TableCollection$new(file = ts_file)
    #' dump_file <- tempfile()
    #' tc$dump(dump_file)
    #' tc$write(dump_file) # alias
    #' \dontshow{file.remove(dump_file)}
    dump = function(file) {
      rtsk_table_collection_dump(self$xptr, filename = file, options = 0L)
    },

    #' @description Alias for \code{\link[=TableCollection]{TableCollection$dump}}.
    #' @param file see \code{\link[=TableCollection]{TableCollection$dump}}.
    write = function(file) {
      self$dump(file = file)
    },

    #' @description Create a \code{\link{TreeSequence}} from this table collection.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/latest/python-api.html#tskit.TableCollection.tree_sequence}.
    #' @return A \code{\link{TreeSequence}} object.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- TableCollection$new(file = ts_file)
    #' ts <- tc$tree_sequence()
    #' is(ts)
    tree_sequence = function() {
      if (!self$has_index()) {
        self$build_index()
      }
      ts_xptr <- rtsk_treeseq_init(self$xptr)
      TreeSequence$new(xptr = ts_xptr)
    },

    # TODO: add site_start and mutation_start
    #' @description Sort this table collection in place.
    #' @param edge_start integer scalar edge-table start row index (0-based).
    #' # TODO: remove this argument since Python code does not have it
    #' @param no_check_integrity logical; when \code{TRUE}, pass
    #'   \code{TSK_NO_CHECK_INTEGRITY} to \code{tskit C}.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/latest/python-api.html#tskit.TableCollection.sort}.
    #' @return No return value; called for side effects.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' tc$sort()
    sort = function(edge_start = 0L, no_check_integrity = FALSE) {
      validate_row_index(edge_start, "edge_start")
      # TODO: remove this argument since Python code does not have it
      if (
        !is.logical(no_check_integrity) ||
          length(no_check_integrity) != 1L ||
          is.na(no_check_integrity)
      ) {
        stop("no_check_integrity must be TRUE/FALSE!")
      }
      options <- if (isTRUE(no_check_integrity)) {
        as.integer(rtsk_const_tsk_no_check_integrity())
      } else {
        0L
      }
      rtsk_table_collection_sort(
        tc = self$xptr,
        edge_start = as.integer(edge_start),
        # TODO: remove this argument since Python code does not have it
        options = options
      )
    },

    #' @description Get the number of provenances in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_provenances()
    num_provenances = function() {
      rtsk_table_collection_get_num_provenances(self$xptr)
    },

    #' @description Get the number of populations in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_populations()
    num_populations = function() {
      rtsk_table_collection_get_num_populations(self$xptr)
    },

    #' @description Get the number of migrations in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_migrations()
    num_migrations = function() {
      rtsk_table_collection_get_num_migrations(self$xptr)
    },

    #' @description Get the number of individuals in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_individuals()
    num_individuals = function() {
      rtsk_table_collection_get_num_individuals(self$xptr)
    },

    #' @description Add a row to the individuals table.
    #' @param flags integer scalar flags for the new individual.
    #' @param location numeric vector with the location of the new individual;
    #'   can be \code{NULL} if unknown.
    #' @param parents integer vector with parent individual IDs (0-based);
    #'   can be \code{NULL} if unknown
    #' @param metadata for the new individual; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.IndividualTable.add_row}.
    #' @return An integer row index and hence ID (0-based) of the newly added individual.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' (n_before <- tc$num_individuals())
    #' new_id <- tc$individual_table_add_row()
    #' new_id <- tc$individual_table_add_row(location = c(5, 8))
    #' new_id <- tc$individual_table_add_row(flags = 0L)
    #' new_id <- tc$individual_table_add_row(parents = c(0L, 2L))
    #' new_id <- tc$individual_table_add_row(metadata = "abc")
    #' new_id <- tc$individual_table_add_row(metadata = charToRaw("cba"))
    #' (n_after <- tc$num_individuals())
    individual_table_add_row = function(
      flags = 0L,
      location = NULL,
      parents = NULL,
      metadata = NULL
    ) {
      validate_integer_scalar_arg(flags, "flags", minimum = 0L)
      validate_optional_numeric_vector_arg(location, "location")
      validate_optional_integer_vector_arg(parents, "parents")
      metadata_raw <- validate_metadata_arg(metadata)
      rtsk_individual_table_add_row(
        tc = self$xptr,
        flags = as.integer(flags),
        location = if (is.null(location)) NULL else as.numeric(location),
        parents = if (is.null(parents)) NULL else as.integer(parents),
        metadata = metadata_raw
      )
    },

    #' @description Get the number of nodes in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_nodes()
    num_nodes = function() {
      rtsk_table_collection_get_num_nodes(self$xptr)
    },

    #' @description Add a row to the nodes table.
    #' @param flags integer scalar flags for the new node.
    #' @param time numeric scalar time value for the new node.
    #' @param population integer scalar population ID (0-based);
    #'   use \code{-1} if not known - \code{NULL} maps to \code{-1} (\code{TSK_NULL}).
    #' @param individual integer scalar individual ID (0-based);
    #'   use \code{-1} if not known - \code{NULL} maps to \code{-1} (\code{TSK_NULL}).
    #' @param metadata for the new node; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.NodeTable.add_row}.
    #' @return An integer row index and hence ID (0-based) of the newly added node.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' (n_before <- tc$num_nodes())
    #' new_id <- tc$node_table_add_row()
    #' new_id <- tc$node_table_add_row(time = 2.5)
    #' new_id <- tc$node_table_add_row(flags = 1L, time = 3.5, population = 0L)
    #' new_id <- tc$node_table_add_row(flags = 1L, time = 4.5, individual = 0L)
    #' new_id <- tc$node_table_add_row(metadata = "abc")
    #' new_id <- tc$node_table_add_row(metadata = charToRaw("cba"))
    #' (n_after <- tc$num_nodes())
    node_table_add_row = function(
      flags = 0L,
      time = 0,
      population = -1L,
      individual = -1L,
      metadata = NULL
    ) {
      validate_integer_scalar_arg(flags, "flags", minimum = 0L)
      validate_numeric_scalar_arg(time, "time")
      validate_nullable_integer_scalar_arg(population, "population")
      validate_nullable_integer_scalar_arg(individual, "individual")
      metadata_raw <- validate_metadata_arg(metadata)
      rtsk_node_table_add_row(
        tc = self$xptr,
        flags = as.integer(flags),
        time = as.numeric(time),
        population = if (is.null(population)) -1L else as.integer(population),
        individual = if (is.null(individual)) -1L else as.integer(individual),
        metadata = metadata_raw
      )
    },

    # TODO: how should we handle useR's experience with numeric&integer in getters?
    #       In Python 0 is integer and 0.0 is numeric, so obj[0] works.
    #       In R 0L is integer and 0 is numeric, so obj[0] might or might not work depending on context,
    #       though many sub-setting methods cast numeric to integer.
    #       So, should we be casting too?
    #       If we allow numeric for index, then we can add allow_numeric into validate_row_index.
    #       We cast with as.integer() anyway before calling C++ method.
    # TODO: Similarly with add_row method on the R side, maybe?
    # TODO: ALSO, should we use 0-based or 1-based access to elements of an object!? I think not!?
    #       And should we allow characters as ID names?
    #' @description Get one row from the nodes table.
    #' @param index integer scalar row index (0-based).
    #' @details In \code{tskit Python}, rows are accessed by indexing a
    #'   \code{NodeTable}, for example \code{tables.nodes[index]}; see
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.NodeTable}.
    #' @return A named list with fields \code{id}, \code{flags}, \code{time},
    #'   \code{population}, \code{individual}, and \code{metadata}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' tc$node_table_get_row(0L)
    #' last_node <- as.integer(tc$num_nodes()) - 1L
    #' tc$node_table_get_row(last_node)
    node_table_get_row = function(index) {
      validate_row_index(index)
      rtsk_node_table_get_row(self$xptr, index = as.integer(index))
    },

    #' @description Get the number of edges in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_edges()
    num_edges = function() {
      rtsk_table_collection_get_num_edges(self$xptr)
    },

    #' @description Add a row to the edges table.
    #' @param left numeric scalar left coordinate for the new edge.
    #' @param right numeric scalar right coordinate for the new edge.
    #' @param parent integer scalar parent node ID (0-based).
    #' @param child integer scalar child node ID (0-based).
    #' @param metadata for the new edge; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.EdgeTable.add_row}.
    #' @return An integer row index and hence ID (0-based) of the newly added edge.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' child <- tc$node_table_add_row(time = 0.0)
    #' (n_before <- tc$num_edges())
    #' new_id <- tc$edge_table_add_row(
    #'   left = 0, right = 50, parent = 16L, child = child
    #' )
    #' new_id <- tc$edge_table_add_row(
    #'   left = 50, right = 75, parent = 17L, child = child, metadata = "abc"
    #' )
    #' new_id <- tc$edge_table_add_row(
    #'   left = 75, right = 100, parent = 18L, child = child, metadata = charToRaw("cba")
    #' )
    #' (n_after <- tc$num_edges())
    edge_table_add_row = function(
      left,
      right,
      parent,
      child,
      metadata = NULL
    ) {
      validate_numeric_scalar_arg(left, "left")
      validate_numeric_scalar_arg(right, "right")
      if (as.numeric(left) >= as.numeric(right)) {
        stop("left must be strictly less than right!")
      }
      validate_row_index(parent, "parent")
      validate_row_index(child, "child")
      metadata_raw <- validate_metadata_arg(metadata)
      rtsk_edge_table_add_row(
        tc = self$xptr,
        left = as.numeric(left),
        right = as.numeric(right),
        parent = as.integer(parent),
        child = as.integer(child),
        metadata = metadata_raw
      )
    },

    #' @description Get the number of sites in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_sites()
    num_sites = function() {
      rtsk_table_collection_get_num_sites(self$xptr)
    },

    #' @description Add a row to the sites table.
    #' @param position numeric scalar site position.
    #' @param ancestral_state character string for the new site.
    #' @param metadata for the new site; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.SiteTable.add_row}.
    #' @return An integer row index and hence ID (0-based) of the newly added site.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' (n_before <- tc$num_sites())
    #' new_id <- tc$site_table_add_row(position = 0.5, ancestral_state = "A")
    #' new_id <- tc$site_table_add_row(position = 2.5, ancestral_state = "T", metadata = "abc")
    #' (n_after <- tc$num_sites())
    site_table_add_row = function(
      position,
      ancestral_state,
      metadata = NULL
    ) {
      validate_numeric_scalar_arg(position, "position")
      validate_character_scalar_arg(ancestral_state, "ancestral_state")
      metadata_raw <- validate_metadata_arg(metadata)
      rtsk_site_table_add_row(
        tc = self$xptr,
        position = as.numeric(position),
        ancestral_state = as.character(ancestral_state),
        metadata = metadata_raw
      )
    },

    #' @description Get the number of mutations in a table collection.
    #' @return A signed 64 bit integer \code{bit64::integer64}.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$num_mutations()
    num_mutations = function() {
      rtsk_table_collection_get_num_mutations(self$xptr)
    },

    #' @description Add a row to the mutations table.
    #' @param site integer scalar site ID (0-based).
    #' @param node integer scalar node ID (0-based).
    #' @param derived_state character string for the new mutation.
    #' @param parent integer scalar parent mutation ID (0-based);
    #'   use \code{-1} if not known - \code{NULL} maps to \code{-1} (\code{TSK_NULL}).
    #' @param metadata for the new mutation; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @param time numeric scalar mutation time;
    #'   use \code{NaN} if not known - \code{NULL} maps to \code{NaN} (\code{TSK_UNKNOWN_TIME}).
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.MutationTable.add_row}.
    #' @return An integer row index and hence ID (0-based) of the newly added mutation.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' (n_before <- tc$num_mutations())
    #' # From inspection of tc we have:
    #' # node13(time=0) <- node16(time=0.02...) <- node20(time=0.08...)
    #' # Add mutation above 16L
    #' m0 <- tc$mutation_table_add_row(site = 0L, node = 16L, derived_state = "T", time = 0.03)
    #' # Add mutation above 13L
    #' m1 <- tc$mutation_table_add_row(
    #'   site = 0L,
    #'   node = 13L,
    #'   parent = m0,
    #'   time = 0.01,
    #'   derived_state = "C",
    #'   metadata = "abc"
    #' )
    #' (n_after <- tc$num_mutations())
    mutation_table_add_row = function(
      site,
      node,
      derived_state,
      parent = -1L,
      metadata = NULL,
      time = NaN
    ) {
      validate_row_index(site, "site")
      validate_row_index(node, "node")
      validate_character_scalar_arg(derived_state, "derived_state")
      validate_nullable_integer_scalar_arg(parent, "parent")
      metadata_raw <- validate_metadata_arg(metadata)
      validate_numeric_scalar_arg(
        time,
        "time",
        allow_null = TRUE,
        allow_nan = TRUE
      )
      rtsk_mutation_table_add_row(
        tc = self$xptr,
        site = as.integer(site),
        node = as.integer(node),
        derived_state = as.character(derived_state),
        parent = if (is.null(parent)) -1L else as.integer(parent),
        metadata = metadata_raw,
        time = if (is.null(time)) NaN else as.numeric(time)
      )
    },

    #' @description Get the sequence length.
    #' @return A numeric.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$sequence_length()
    sequence_length = function() {
      rtsk_table_collection_get_sequence_length(self$xptr)
    },

    #' @description Get the time units string.
    #' @return A character.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$time_units()
    time_units = function() {
      rtsk_table_collection_get_time_units(self$xptr)
    },

    #' @description Get whether the table collection has edge indexes.
    #' @return A logical.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$has_index()
    has_index = function() {
      rtsk_table_collection_has_index(self$xptr)
    },

    #' @description Build edge indexes for this table collection.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/latest/python-api.html#tskit.TableCollection.build_index}.
    #' @return No return value; called for side effects.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$has_index()
    #' tc$drop_index()
    #' tc$has_index()
    #' tc$build_index()
    #' tc$has_index()
    build_index = function() {
      rtsk_table_collection_build_index(self$xptr)
    },

    #' @description Drop edge indexes for this table collection.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/latest/python-api.html#tskit.TableCollection.drop_index}.
    #' @return No return value; called for side effects.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$has_index()
    #' tc$drop_index()
    #' tc$has_index()
    drop_index = function() {
      rtsk_table_collection_drop_index(self$xptr)
    },

    #' @description Get whether the table collection has a reference genome sequence.
    #' @return A logical.
    #' @examples
    #' tc_file1 <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc_file2 <- system.file("examples/test_with_ref_seq.trees", package = "RcppTskit")
    #' tc1 <- tc_load(tc_file1)
    #' tc1$has_reference_sequence()
    #' tc2 <- tc_load(tc_file2)
    #' tc2$has_reference_sequence()
    has_reference_sequence = function() {
      rtsk_table_collection_has_reference_sequence(self$xptr)
    },

    #' @description Get the UUID string of the file the table collection was
    #'   loaded from.
    #' @return A character; \code{NA_character_} when file is information is
    #'   unavailable.
    #' @examples
    #' tc_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(tc_file)
    #' tc$file_uuid()
    file_uuid = function() {
      rtsk_table_collection_get_file_uuid(self$xptr)
    },

    #' @description This function saves a table collection from \code{R} to disk
    #'   and loads it into reticulate \code{Python} for use with the
    #'   \code{tskit Python} API.
    #' @param tskit_module reticulate \code{Python} module of \code{tskit}.
    #'   By default, it calls \code{\link{get_tskit_py}} to obtain the module.
    #' @param cleanup logical; delete the temporary file at the end of the function?
    #' @details See \url{https://tskit.dev/tutorials/tables_and_editing.html#tables-and-editing}
    #'   on what you can do with the tables.
    #' @return \code{TableCollection} object in reticulate \code{Python}.
    #' @seealso \code{\link{tc_py_to_r}}, \code{\link{tc_load}}, and
    #'   \code{\link[=TableCollection]{TableCollection$dump}}.
    #' @examples
    #' \dontrun{
    #'   ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #'   tc_r <- tc_load(ts_file)
    #'   is(tc_r)
    #'   tc_r$print()
    #'
    #'   # Transfer the table collection to reticulate Python and use tskit Python API
    #'   tskit <- get_tskit_py()
    #'   if (check_tskit_py(tskit)) {
    #'     tc_py <- tc_r$r_to_py()
    #'     is(tc_py)
    #'     tmp <- tc_py$simplify(samples = c(0L, 1L, 2L, 3L))
    #'     tmp
    #'     tc_py$individuals$num_rows # 2
    #'     tc_py$nodes$num_rows # 8
    #'     tc_py$nodes$time # 0.0 ... 5.0093910
    #'   }
    #' }
    r_to_py = function(tskit_module = get_tskit_py(), cleanup = TRUE) {
      rtsk_table_collection_r_to_py(
        self$xptr,
        tskit_module = tskit_module,
        cleanup = cleanup
      )
    },

    #' @description Print a summary of a table collection and its contents.
    #' @return A list with two data.frames; the first contains table collection
    #'   properties and their values; the second contains the number of rows in
    #'   each table and the length of their metadata. All columns are characters
    #'   since output types differ across the entries. Use individual getters
    #'   to obtain raw values before they are converted to character.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(file = ts_file)
    #' tc$print()
    #' tc
    print = function() {
      ret <- rtsk_table_collection_print(self$xptr)
      # These are not hit since testing is not interactive
      # nocov start
      if (interactive()) {
        cat("Object of class 'TableCollection'\n")
        print(ret)
      }
      # nocov end
      invisible(ret)
    }
  )
)
