#' @title Succinct tree sequence R6 class (TreeSequence)
#' @description An R6 class holding an external pointer to a tree sequence
#' object. As an R6 class, its methods look Pythonic and therefore resemble the
#' tskit Python API. Since the class only holds the pointer, it is lightweight.
#' Currently there is a limited set of methods for summarising the tree sequence.
#' @export
TreeSequence <- R6Class(
  classname = "TreeSequence",
  public = list(
    #' @field pointer external pointer to the tree sequence
    pointer = "externalptr",

    #' @description Create a \code{\link{TreeSequence}} from a file or a pointer.
    #'   See \code{\link{ts_load}} for details and examples.
    #' @param file a string specifying the full path of the tree sequence file.
    #' @param options integer bitwise options (see details at
    #'   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_load}).
    #' @param pointer an external pointer (\code{externalptr}) to a tree sequence.
    #' @return A \code{\link{TreeSequence}} object.
    #' @seealso \code{\link{ts_load}}
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- TreeSequence$new(file = ts_file)
    #' is(ts)
    #' ts
    #' ts$num_nodes()
    #' # Also
    #' ts <- ts_load(ts_file)
    #' is(ts)
    initialize = function(file, options = 0L, pointer = NULL) {
      if (missing(file) && is.null(pointer)) {
        stop("Provide a file name or a pointer!")
      }
      if (!missing(file) && !is.null(pointer)) {
        stop("Provide either a file name or a pointer, but not both!")
      }
      if (!missing(file)) {
        if (!is.character(file)) {
          stop("file must be a character string!")
        }
        if (!is.numeric(options)) {
          stop("options must be numeric/integer!")
        }
        if (!is.integer(options)) {
          options <- as.integer(options)
        }
        self$pointer <- ts_load_ptr(file = file, options = options)
      } else {
        if (!is.null(pointer) && !is(pointer, "externalptr")) {
          stop("pointer must be an object of externalptr class!")
        }
        self$pointer <- pointer
      }
      invisible(self)
    },

    #' @description Write a tree sequence to a file.
    #' @param file a string specifying the full path of the tree sequence file.
    #' @param options integer bitwise options (see details at
    #'   \url{https://tskit.dev/tskit/docs/stable/c-api.html#c.tsk_treeseq_dump}).
    #' @return No return value; called for side effects.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' dump_file <- tempfile()
    #' ts$dump(dump_file)
    #' ts$write(dump_file) # alias
    dump = function(file, options = 0L) {
      ts_dump_ptr(self$pointer, file = file, options = options)
    },

    #' @description Alias for \code{\link[=TreeSequence]{TreeSequence$dump}}.
    #' @param file see \code{\link[=TreeSequence]{TreeSequence$dump}}.
    #' @param options see \code{\link[=TreeSequence]{TreeSequence$dump}}.
    write = function(file, options = 0L) {
      self$dump(file = file, options = options)
    },

    #' @description Print a summary of a tree sequence and its contents.
    #' @return list with two data.frames; the first contains tree sequence
    #'   properties and their values; the second contains the number of rows in
    #'   each table and the length of their metadata.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$print()
    #' ts
    print = function() {
      cat("Object of class 'TreeSequence'\n")
      print(ts_print_ptr(self$pointer))
    },

    #' @description This function saves a tree sequence from R to disk and
    #'   loads it into reticulate Python for use with the \code{tskit} Python API.
    #' @param tskit_module reticulate Python module of \code{tskit}. By default,
    #'   it calls \code{\link{get_tskit_py}} to obtain the module.
    #' @param cleanup logical; delete the temporary file at the end of the function?
    #' @return Tree sequence in reticulate Python.
    #' @seealso \code{\link{ts_py_to_r}}, \code{\link{ts_load}}, and
    #'   \code{\link[=TreeSequence]{TreeSequence$dump}}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts_r <- ts_load(ts_file)
    #' is(ts_r)
    #' ts_r$num_samples() # 160
    #'
    #' # Transfer the tree sequence to reticulate Python and use tskit Python API
    #' tskit <- get_tskit_py()
    #' if (check_tskit_py(tskit)) {
    #'   ts_py <- ts_r$r_to_py()
    #'   is(ts_py)
    #'   ts_py$num_samples # 160
    #'   ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
    #'   ts2_py$num_samples # 4
    #' }
    r_to_py = function(tskit_module = get_tskit_py(), cleanup = TRUE) {
      ts_r_to_py_ptr(
        self$pointer,
        tskit_module = tskit_module,
        cleanup = cleanup
      )
    },

    #' @description Get the number of provenances in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_provenances()
    num_provenances = function() {
      ts_num_provenances_ptr(self$pointer)
    },

    #' @description Get the number of populations in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_populations()
    num_populations = function() {
      ts_num_populations_ptr(self$pointer)
    },

    #' @description Get the number of migrations in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_migrations()
    num_migrations = function() {
      ts_num_migrations_ptr(self$pointer)
    },

    #' @description Get the number of individuals in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_individuals()
    num_individuals = function() {
      ts_num_individuals_ptr(self$pointer)
    },

    #' @description Get the number of samples (of nodes) in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_samples()
    num_samples = function() {
      ts_num_samples_ptr(self$pointer)
    },

    #' @description Get the number of nodes in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_nodes()
    num_nodes = function() {
      ts_num_nodes_ptr(self$pointer)
    },

    #' @description Get the number of edges in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_edges()
    num_edges = function() {
      ts_num_edges_ptr(self$pointer)
    },

    #' @description Get the number of trees in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_trees()
    num_trees = function() {
      ts_num_trees_ptr(self$pointer)
    },

    #' @description Get the number of sites in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_sites()
    num_sites = function() {
      ts_num_sites_ptr(self$pointer)
    },

    #' @description Get the number of mutations in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_mutations()
    num_mutations = function() {
      ts_num_mutations_ptr(self$pointer)
    },

    #' @description Get the sequence length.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$sequence_length()
    sequence_length = function() {
      ts_sequence_length_ptr(self$pointer)
    },

    #' @description Get the time units string.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$time_units()
    time_units = function() {
      ts_time_units_ptr(self$pointer)
    },

    #' @description Get the min time in node table and mutation table.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$min_time()
    min_time = function() {
      ts_min_time_ptr(self$pointer)
    },

    #' @description Get the max time in node table and mutation table.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$max_time()
    max_time = function() {
      ts_max_time_ptr(self$pointer)
    },

    #' @description Get the length of metadata in a tree sequence and its tables.
    #' @return A named list with the length of metadata.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$metadata_length()
    metadata_length = function() {
      ts_metadata_length_ptr(self$pointer)
    }
  )
)
