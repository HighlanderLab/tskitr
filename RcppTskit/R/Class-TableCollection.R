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
    #' @param flags integer flags for the new individual.
    #' @param location numeric vector with the location of the new individual.
    #' @param parents integer vector with parent individual IDs (0-based).
    #' @param metadata for the new individual; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.IndividualTable.add_row}.
    #'   The function casts inputs to the expected class.
    #' @return Integer row ID (0-based) of the newly added individual.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' n_before <- tc$num_individuals()
    #' new_id <- tc$individual_table_add_row()
    #' new_id <- tc$individual_table_add_row(location = c(5, 8))
    #' new_id <- tc$individual_table_add_row(flags = 0L)
    #' new_id <- tc$individual_table_add_row(parents = c(0L, 2L))
    #' new_id <- tc$individual_table_add_row(metadata = "abc")
    #' new_id <- tc$individual_table_add_row(metadata = charToRaw("cba"))
    #' n_after <- tc$num_individuals()
    individual_table_add_row = function(
      flags = 0L,
      location = NULL,
      parents = NULL,
      metadata = NULL
    ) {
      if (is.null(metadata)) {
        metadata_raw <- NULL
      } else if (is.raw(metadata)) {
        metadata_raw <- metadata
      } else if (
        is.character(metadata) && length(metadata) == 1L && !is.na(metadata)
      ) {
        metadata_raw <- charToRaw(metadata)
      } else {
        stop(
          "metadata must be NULL, a raw vector, or a length-1 non-NA character string!"
        )
      }
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
    #' @param flags integer flags for the new node.
    #' @param time numeric time value for the new node.
    #' @param population integer population row ID (0-based, or \code{-1});
    #'   \code{NULL} maps to \code{-1}.
    #' @param individual integer individual row ID (0-based, or \code{-1});
    #'   \code{NULL} maps to \code{-1}.
    #' @param metadata for the new node; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.NodeTable.add_row}.
    #'   The function casts inputs to the expected class. For convenience,
    #'   \code{population = NULL} and \code{individual = NULL} are mapped to
    #'   \code{-1} (\code{TSK_NULL}).
    #' @return Integer row ID (0-based) of the newly added node.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' n_before <- tc$num_nodes()
    #' new_id <- tc$node_table_add_row()
    #' new_id <- tc$node_table_add_row(time = 2.5)
    #' new_id <- tc$node_table_add_row(flags = 1L, time = 3.5, population = 0L)
    #' new_id <- tc$node_table_add_row(flags = 1L, time = 4.5, individual = 0L)
    #' new_id <- tc$node_table_add_row(metadata = "abc")
    #' new_id <- tc$node_table_add_row(metadata = charToRaw("cba"))
    #' n_after <- tc$num_nodes()
    node_table_add_row = function(
      flags = 0L,
      time = 0,
      population = -1L,
      individual = -1L,
      metadata = NULL
    ) {
      if (is.null(metadata)) {
        metadata_raw <- NULL
      } else if (is.raw(metadata)) {
        metadata_raw <- metadata
      } else if (
        is.character(metadata) && length(metadata) == 1L && !is.na(metadata)
      ) {
        metadata_raw <- charToRaw(metadata)
      } else {
        stop(
          "metadata must be NULL, a raw vector, or a length-1 non-NA character string!"
        )
      }
      rtsk_node_table_add_row(
        tc = self$xptr,
        flags = as.integer(flags),
        time = as.numeric(time),
        population = if (is.null(population)) -1L else as.integer(population),
        individual = if (is.null(individual)) -1L else as.integer(individual),
        metadata = metadata_raw
      )
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
    #' @param parent integer scalar parent node row ID (0-based).
    #' @param child integer scalar child node row ID (0-based).
    #' @param metadata for the new edge; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.EdgeTable.add_row}.
    #'   The function casts inputs to the expected class. Inputs are validated:
    #'   \code{left} and \code{right} must be finite numeric scalars with
    #'   \code{left < right}, and \code{parent} and \code{child} must be
    #'   non-\code{NA} integer scalars.
    #' @return Integer row ID (0-based) of the newly added edge.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' parent <- 0L
    #' child <- 1L
    #' n_before <- tc$num_edges()
    #' new_id <- tc$edge_table_add_row(
    #'   left = 0, right = 1, parent = parent, child = child
    #' )
    #' new_id <- tc$edge_table_add_row(
    #'   left = 1, right = 2, parent = parent, child = child, metadata = "abc"
    #' )
    #' new_id <- tc$edge_table_add_row(
    #'   left = 2, right = 3, parent = parent, child = child, metadata = charToRaw("cba")
    #' )
    #' n_after <- tc$num_edges()
    edge_table_add_row = function(
      left,
      right,
      parent,
      child,
      metadata = NULL
    ) {
      if (
        is.null(left) ||
          length(left) != 1L ||
          !is.numeric(left) ||
          is.na(left) ||
          !is.finite(left)
      ) {
        stop("left must be a non-NA finite numeric scalar!")
      }
      if (
        is.null(right) ||
          length(right) != 1L ||
          !is.numeric(right) ||
          is.na(right) ||
          !is.finite(right)
      ) {
        stop("right must be a non-NA finite numeric scalar!")
      }
      if (as.numeric(left) >= as.numeric(right)) {
        stop("left must be strictly less than right!")
      }
      if (
        is.null(parent) || length(parent) != 1L || is.na(as.integer(parent))
      ) {
        stop("parent must be a non-NA integer scalar!")
      }
      if (is.null(child) || length(child) != 1L || is.na(as.integer(child))) {
        stop("child must be a non-NA integer scalar!")
      }
      if (is.null(metadata)) {
        metadata_raw <- NULL
      } else if (is.raw(metadata)) {
        metadata_raw <- metadata
      } else if (
        is.character(metadata) && length(metadata) == 1L && !is.na(metadata)
      ) {
        metadata_raw <- charToRaw(metadata)
      } else {
        stop(
          "metadata must be NULL, a raw vector, or a length-1 non-NA character string!"
        )
      }
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
    #' @param ancestral_state for the new site; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @param metadata for the new site; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.SiteTable.add_row}.
    #'   The function casts inputs to the expected class. \code{position}
    #'   must be a non-\code{NA} finite numeric scalar.
    #' @return Integer row ID (0-based) of the newly added site.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' n_before <- tc$num_sites()
    #' new_id <- tc$site_table_add_row(position = 0.5, ancestral_state = "A")
    #' new_id <- tc$site_table_add_row(position = 1.5, ancestral_state = charToRaw("G"))
    #' new_id <- tc$site_table_add_row(position = 2.5, ancestral_state = "T", metadata = "abc")
    #' n_after <- tc$num_sites()
    site_table_add_row = function(
      position,
      ancestral_state = NULL,
      metadata = NULL
    ) {
      if (
        is.null(position) ||
          length(position) != 1L ||
          !is.numeric(position) ||
          is.na(position) ||
          !is.finite(position)
      ) {
        stop("position must be a non-NA finite numeric scalar!")
      }
      if (is.null(ancestral_state)) {
        ancestral_state_raw <- NULL
      } else if (is.raw(ancestral_state)) {
        ancestral_state_raw <- ancestral_state
      } else if (
        is.character(ancestral_state) &&
          length(ancestral_state) == 1L &&
          !is.na(ancestral_state)
      ) {
        ancestral_state_raw <- charToRaw(ancestral_state)
      } else {
        stop(
          "ancestral_state must be NULL, a raw vector, or a length-1 non-NA character string!"
        )
      }
      if (is.null(metadata)) {
        metadata_raw <- NULL
      } else if (is.raw(metadata)) {
        metadata_raw <- metadata
      } else if (
        is.character(metadata) && length(metadata) == 1L && !is.na(metadata)
      ) {
        metadata_raw <- charToRaw(metadata)
      } else {
        stop(
          "metadata must be NULL, a raw vector, or a length-1 non-NA character string!"
        )
      }
      rtsk_site_table_add_row(
        tc = self$xptr,
        position = as.numeric(position),
        ancestral_state = ancestral_state_raw,
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
    #' @param site integer scalar site row ID (0-based).
    #' @param node integer scalar node row ID (0-based).
    #' @param parent integer scalar parent mutation row ID (0-based, or \code{-1}).
    #' @param time numeric scalar mutation time; use \code{NaN} for
    #'   \code{TSK_UNKNOWN_TIME}.
    #' @param derived_state for the new mutation; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @param metadata for the new mutation; accepts \code{NULL},
    #'   a raw vector, or a character of length 1.
    #' @details See the \code{tskit Python} equivalent at
    #'   \url{https://tskit.dev/tskit/docs/stable/python-api.html#tskit.MutationTable.add_row}.
    #'   The function casts inputs to the expected class. \code{site},
    #'   \code{node}, and \code{parent} must be non-\code{NA} integer scalars.
    #'   \code{time} must be a numeric scalar that is finite or \code{NaN}
    #'   (unknown time).
    #' @return Integer row ID (0-based) of the newly added mutation.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(ts_file)
    #' n_before <- tc$num_mutations()
    #' new_id <- tc$mutation_table_add_row(site = 0L, node = 0L, derived_state = "T")
    #' new_id <- tc$mutation_table_add_row(
    #'   site = 0L,
    #'   node = 0L,
    #'   parent = -1L,
    #'   time = 1.5,
    #'   derived_state = charToRaw("C"),
    #'   metadata = "abc"
    #' )
    #' n_after <- tc$num_mutations()
    mutation_table_add_row = function(
      site,
      node,
      parent = -1L,
      time = NaN,
      derived_state = NULL,
      metadata = NULL
    ) {
      if (is.null(site) || length(site) != 1L || is.na(as.integer(site))) {
        stop("site must be a non-NA integer scalar!")
      }
      if (is.null(node) || length(node) != 1L || is.na(as.integer(node))) {
        stop("node must be a non-NA integer scalar!")
      }
      if (
        is.null(parent) || length(parent) != 1L || is.na(as.integer(parent))
      ) {
        stop("parent must be a non-NA integer scalar!")
      }
      if (
        is.null(time) ||
          length(time) != 1L ||
          !is.numeric(time) ||
          (is.na(time) && !is.nan(time)) ||
          !(is.finite(time) || is.nan(time))
      ) {
        stop("time must be a non-NA numeric scalar that is finite or NaN!")
      }
      if (is.null(derived_state)) {
        derived_state_raw <- NULL
      } else if (is.raw(derived_state)) {
        derived_state_raw <- derived_state
      } else if (
        is.character(derived_state) &&
          length(derived_state) == 1L &&
          !is.na(derived_state)
      ) {
        derived_state_raw <- charToRaw(derived_state)
      } else {
        stop(
          "derived_state must be NULL, a raw vector, or a length-1 non-NA character string!"
        )
      }
      if (is.null(metadata)) {
        metadata_raw <- NULL
      } else if (is.raw(metadata)) {
        metadata_raw <- metadata
      } else if (
        is.character(metadata) && length(metadata) == 1L && !is.na(metadata)
      ) {
        metadata_raw <- charToRaw(metadata)
      } else {
        stop(
          "metadata must be NULL, a raw vector, or a length-1 non-NA character string!"
        )
      }
      rtsk_mutation_table_add_row(
        tc = self$xptr,
        site = as.integer(site),
        node = as.integer(node),
        parent = as.integer(parent),
        time = as.numeric(time),
        derived_state = derived_state_raw,
        metadata = metadata_raw
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
