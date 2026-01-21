#' @title Succinct Tree Sequence R6 Class
#' @description An R6 class to hold an external pointer to a tskit tree sequence.
#' As an R6 class, it's functions will look Pythonic and hence resemble the
#' tskit Python API. Since the class only holds the pointer, it is lightweight.
#' The pointer does not provide direct view for users and currently there is
#' only a limited number of methods available to summarise the tree sequence.
#' @export
TreeSequence <- R6Class(
  classname = "TreeSequence",
  public = list(
    #' @field pointer external pointer to the tree sequence
    pointer = "externalptr",

    #' @description Create a \code{\link{TreeSequence}} from a file or a pointer.
    #'   See \code{\link{ts_load}()} for details and examples.
    #' @param file see \code{\link{ts_load}()}
    #' @param options see \code{\link{ts_load}()}
    #' @param pointer an external pointer to a tree sequence
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
    #'   See \code{\link{ts_dump}()} for details and examples.
    #' @param file see \code{\link{ts_dump}()}
    #' @param options see \code{\link{ts_dump}()}
    dump = function(file, options = 0L) {
      ts_dump_ptr(self$pointer, file = file, options = options)
    },

    #' @description Write a tree sequence to a file.
    #'   Alias for \code{TreeSequence$dump(file, options)}.
    #'   See \code{\link{ts_dump}()} for details and examples.
    #' @param file see \code{\link{ts_dump}()}
    #' @param options see \code{\link{ts_dump}()}
    write = function(file, options = 0L) {
      self$dump(file = file, options = options)
    },

    #' @description Print a summary of a tree sequence and its contents.
    #'   See \code{\link{ts_print}()} for details and examples.
    print = function() {
      cat("Object of class 'TreeSequence'\n")
      print(ts_print_ptr(self$pointer))
    },

    #' @description Summary of properties and number of records in a tree sequence.
    #'   See \code{\link{ts_summary}()} for details and examples.
    summary = function() {
      ts_summary_ptr(self$pointer)
    },

    #' @description Get the number of provenances in a tree sequence.
    #'   See \code{\link{ts_summary}()} for details and examples.
    num_provenances = function() {
      ts_num_provenances_ptr(self$pointer)
    },

    #' @description Get the number of populations in a tree sequence.
    #'   See \code{\link{ts_summary}()} for details and examples.
    num_populations = function() {
      ts_num_populations_ptr(self$pointer)
    },

    #' @description Get the number of migrations in a tree sequence.
    #'   See \code{\link{ts_summary}()} for details and examples.
    num_migrations = function() {
      ts_num_migrations_ptr(self$pointer)
    },

    #' @description Get the number of individuals in a tree sequence.
    #'   See \code{\link{ts_summary}()} for details and examples.
    num_individuals = function() {
      ts_num_individuals_ptr(self$pointer)
    },

    #' @description Get the number of samples (of nodes) in a tree sequence.
    #'   See \code{\link{ts_summary}()} for details and examples.
    num_samples = function() {
      ts_num_samples_ptr(self$pointer)
    },

    #' @description Get the number of nodes in a tree sequence.
    #'   See \code{\link{ts_summary}()} for details and examples.
    num_nodes = function() {
      ts_num_nodes_ptr(self$pointer)
    },

    #' @description Get the number of edges in a tree sequence.
    #'   See \code{\link{ts_summary}()} for details and examples.
    num_edges = function() {
      ts_num_edges_ptr(self$pointer)
    },

    #' @description Get the number of trees in a tree sequence.
    #'   See \code{\link{ts_summary}()} for details and examples.
    num_trees = function() {
      ts_num_trees_ptr(self$pointer)
    },

    #' @description Get the number of sites in a tree sequence.
    #'   See \code{\link{ts_summary}()} for details and examples.
    num_sites = function() {
      ts_num_sites_ptr(self$pointer)
    },

    #' @description Get the number of mutations in a tree sequence.
    #'   See \code{\link{ts_summary}()} for details and examples.
    num_mutations = function() {
      ts_num_mutations_ptr(self$pointer)
    },

    #' @description Get the sequence length.
    #'   See \code{\link{ts_summary}()} for details and examples.
    sequence_length = function() {
      ts_sequence_length_ptr(self$pointer)
    },

    #' @description Get the time units string.
    #'   See \code{\link{ts_summary}()} for details and examples.
    time_units = function() {
      ts_time_units_ptr(self$pointer)
    },

    #' @description Get the length of metadata in a tree sequence and its tables.
    #'   See \code{\link{ts_metadata_length}()} for details and examples.
    metadata_length = function() {
      ts_metadata_length_ptr(self$pointer)
    },

    #' @description Transfer a tree sequence from R to reticulate Python.
    #'   See \code{\link{ts_r_to_py}()} for details and examples.
    #' @param tskit_module see \code{\link{ts_r_to_py}()}
    #' @param cleanup see \code{\link{ts_r_to_py}()}
    r_to_py = function(tskit_module = get_tskit_py(), cleanup = TRUE) {
      ts_r_to_py_ptr(
        self$pointer,
        tskit_module = tskit_module,
        cleanup = cleanup
      )
    }
  )
)

#' @name TreeSequence-load-alias
#' @title Create a \code{\link{TreeSequence}} from a file
#' @description
#'   Alias for \code{TreeSequence$new(file, options)}
#'   See \code{\link{ts_load}()} for details and examples.
#' @param file see \code{\link{ts_load}()}
#' @param options see \code{\link{ts_load}()}
TreeSequence$load <- function(file, options = 0L) {
  TreeSequence$new(file = file, options = options)
}
# This one has to be outside of the R6 class definition to work as a generator

#' @name TreeSequence-read-alias
#' @title Create a \code{\link{TreeSequence}} from a file.
#' @description
#'   Alias for \code{TreeSequence$new(file, options)}
#'   See \code{\link{ts_load}()} for details and examples.
#' @param file see \code{\link{ts_load}()}
#' @param options see \code{\link{ts_load}()}
TreeSequence$read <- function(file, options = 0L) {
  TreeSequence$new(file = file, options = options)
}
# This one has to be outside of the R6 class definition to work as a generator
