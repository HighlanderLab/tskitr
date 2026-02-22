#' @title Succinct tree sequence R6 class (TreeSequence)
#' @description An R6 class holding an external pointer to a tree sequence
#' object. As an R6 class, its methods look Pythonic and therefore resemble the
#' tskit Python API. Since the class only holds the pointer, it is lightweight.
#' Currently there is a limited set of R methods for working with the tree sequence.
#' @export
TreeSequence <- R6Class(
  classname = "TreeSequence",
  public = list(
    #' @field pointer external pointer to the tree sequence
    pointer = "externalptr",

    #' @description Create a \code{\link{TreeSequence}} from a file or a pointer.
    #'   See \code{\link{ts_load}} for details and examples.
    #' @param file a string specifying the full path of the tree sequence file.
    #' @param skip_tables logical; if \code{TRUE}, load only non-table information.
    #' @param skip_reference_sequence logical; if \code{TRUE}, skip loading
    #'   reference sequence information.
    #' @param pointer an external pointer (\code{externalptr}) to a tree sequence.
    #' @details See the corresponding Python function at
    #'   \url{https://tskit.dev/tskit/docs/latest/python-api.html#tskit.load}.
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
    initialize = function(
      file,
      skip_tables = FALSE,
      skip_reference_sequence = FALSE,
      pointer = NULL
    ) {
      if (missing(file) && is.null(pointer)) {
        stop("Provide a file or a pointer!")
      }
      if (!missing(file) && !is.null(pointer)) {
        stop("Provide either a file or a pointer, but not both!")
      }
      if (!missing(file)) {
        if (!is.character(file)) {
          stop("file must be a character string!")
        }
        options <- load_args_to_options(
          skip_tables = skip_tables,
          skip_reference_sequence = skip_reference_sequence
        )
        self$pointer <- ts_ptr_load(file = file, options = options)
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
    #' @details See the corresponding Python function at
    #'   \url{https://tskit.dev/tskit/docs/latest/python-api.html#tskit.TreeSequence.dump}.
    #' @return No return value; called for side effects.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' dump_file <- tempfile()
    #' ts$dump(dump_file)
    #' ts$write(dump_file) # alias
    #' \dontshow{file.remove(dump_file)}
    dump = function(file) {
      ts_ptr_dump(self$pointer, file = file, options = 0L)
    },

    #' @description Alias for \code{\link[=TreeSequence]{TreeSequence$dump}}.
    #' @param file see \code{\link[=TreeSequence]{TreeSequence$dump}}.
    write = function(file) {
      self$dump(file = file)
    },

    #' @description Copy the tables into a \code{\link{TableCollection}}.
    #' @details See the corresponding Python function at
    #'   \url{https://tskit.dev/tskit/docs/latest/python-api.html#tskit.TreeSequence.dump_tables}.
    #' @return A \code{\link{TableCollection}} object.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' tc <- ts$dump_tables()
    #' is(tc)
    dump_tables = function() {
      tc_ptr <- ts_ptr_to_tc_ptr(self$pointer)
      TableCollection$new(pointer = tc_ptr)
    },

    #' @description Print a summary of a tree sequence and its contents.
    #' @return A list with two data.frames; the first contains tree sequence
    #'   properties and their values; the second contains the number of rows in
    #'   each table and the length of their metadata.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$print()
    #' ts
    print = function() {
      ret <- ts_ptr_print(self$pointer)
      # These are not hit since testing is not interactive
      # nocov start
      if (interactive()) {
        cat("Object of class 'TreeSequence'\n")
        print(ret)
      }
      # nocov end
      invisible(ret)
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
    #' \dontrun{
    #'   ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #'   ts_r <- ts_load(ts_file)
    #'   is(ts_r)
    #'   ts_r$num_individuals() # 8
    #'
    #'   # Transfer the tree sequence to reticulate Python and use tskit Python API
    #'   tskit <- get_tskit_py()
    #'   if (check_tskit_py(tskit)) {
    #'     ts_py <- ts_r$r_to_py()
    #'     is(ts_py)
    #'     ts_py$num_individuals # 8
    #'     ts2_py <- ts_py$simplify(samples = c(0L, 1L, 2L, 3L))
    #'     ts_py$num_individuals # 8
    #'     ts2_py$num_individuals # 2
    #'     ts2_py$num_nodes # 8
    #'     ts2_py$tables$nodes$time # 0.0 ... 5.0093910
    #'   }
    #' }
    r_to_py = function(tskit_module = get_tskit_py(), cleanup = TRUE) {
      ts_ptr_r_to_py(
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
      ts_ptr_num_provenances(self$pointer)
    },

    #' @description Get the number of populations in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_populations()
    num_populations = function() {
      ts_ptr_num_populations(self$pointer)
    },

    #' @description Get the number of migrations in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_migrations()
    num_migrations = function() {
      ts_ptr_num_migrations(self$pointer)
    },

    #' @description Get the number of individuals in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_individuals()
    num_individuals = function() {
      ts_ptr_num_individuals(self$pointer)
    },

    #' @description Get the number of samples (of nodes) in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_samples()
    num_samples = function() {
      ts_ptr_num_samples(self$pointer)
    },

    #' @description Get the number of nodes in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_nodes()
    num_nodes = function() {
      ts_ptr_num_nodes(self$pointer)
    },

    #' @description Get the number of edges in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_edges()
    num_edges = function() {
      ts_ptr_num_edges(self$pointer)
    },

    #' @description Get the number of trees in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_trees()
    num_trees = function() {
      ts_ptr_num_trees(self$pointer)
    },

    #' @description Get the number of sites in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_sites()
    num_sites = function() {
      ts_ptr_num_sites(self$pointer)
    },

    #' @description Get the number of mutations in a tree sequence.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$num_mutations()
    num_mutations = function() {
      ts_ptr_num_mutations(self$pointer)
    },

    #' @description Get the sequence length.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$sequence_length()
    sequence_length = function() {
      ts_ptr_sequence_length(self$pointer)
    },

    #' @description Get the time units string.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$time_units()
    time_units = function() {
      ts_ptr_time_units(self$pointer)
    },

    #' @description Get the min time in node table and mutation table.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$min_time()
    min_time = function() {
      ts_ptr_min_time(self$pointer)
    },

    #' @description Get the max time in node table and mutation table.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$max_time()
    max_time = function() {
      ts_ptr_max_time(self$pointer)
    },

    #' @description Get the length of metadata in a tree sequence and its tables.
    #' @return A named list with the length of metadata.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' ts <- ts_load(ts_file)
    #' ts$metadata_length()
    metadata_length = function() {
      ts_ptr_metadata_length(self$pointer)
    }
  )
)
