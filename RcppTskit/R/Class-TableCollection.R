#' @title Table collection R6 class (TableCollection)
#' @description An R6 class holding an external pointer to a table collection
#' object. As an R6 class, its methods look Pythonic and therefore resemble the
#' tskit Python API. Since the class only holds the pointer, it is lightweight.
#' Currently there is a limited set of R methods for working the tree sequence.
#' @export
TableCollection <- R6Class(
  classname = "TableCollection",
  public = list(
    #' @field pointer external pointer to the table collection
    pointer = "externalptr",

    #' @description Create a \code{\link{TableCollection}} from a file or a pointer.
    #' @param file a string specifying the full path of the tree sequence file.
    #' @param skip_tables logical; if \code{TRUE}, load only non-table information.
    #' @param skip_reference_sequence logical; if \code{TRUE}, skip loading
    #'   reference sequence information.
    #' @param pointer an external pointer (\code{externalptr}) to a table collection.
    #' @details See the corresponding Python function at
    #'   \url{https://github.com/tskit-dev/tskit/blob/dc394d72d121c99c6dcad88f7a4873880924dd72/python/tskit/tables.py#L3463}.
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
        self$pointer <- tc_ptr_load(file = file, options = options)
      } else {
        if (!is.null(pointer) && !is(pointer, "externalptr")) {
          stop("pointer must be an object of externalptr class!")
        }
        self$pointer <- pointer
      }
      invisible(self)
    },

    #' @description Write a table collection to a file.
    #' @param file a string specifying the full path of the tree sequence file.
    #' @details See the corresponding Python function at
    #'   \url{https://tskit.dev/tskit/docs/latest/python-api.html#tskit.TableCollection.dump}.
    #' @return No return value; called for side effects.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- TableCollection$new(file = ts_file)
    #' dump_file <- tempfile()
    #' tc$dump(dump_file)
    #' tc$write(dump_file) # alias
    dump = function(file) {
      tc_ptr_dump(self$pointer, file = file, options = 0L)
    },

    #' @description Alias for \code{\link[=TableCollection]{TableCollection$dump}}.
    #' @param file see \code{\link[=TableCollection]{TableCollection$dump}}.
    write = function(file) {
      self$dump(file = file)
    },

    #' @description Create a \code{\link{TreeSequence}} from this table collection.
    #' @details See the corresponding Python function at
    #'   \url{https://tskit.dev/tskit/docs/latest/python-api.html#tskit.TableCollection.tree_sequence}.
    #' @return A \code{\link{TreeSequence}} object.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- TableCollection$new(file = ts_file)
    #' ts <- tc$tree_sequence()
    #' is(ts)
    tree_sequence = function() {
      # See https://tskit.dev/tskit/docs/stable/c-api.html#c.TSK_TS_INIT_BUILD_INDEXES
      # TSK_TS_INIT_BUILD_INDEXES (1 << 0) is bitwShiftL(1L, 0) or just 1L
      # TODO: Should we also use https://tskit.dev/tskit/docs/stable/c-api.html#c.TSK_TS_INIT_COMPUTE_MUTATION_PARENTS?
      init_options <- bitwShiftL(1L, 0)
      ts_ptr <- tc_ptr_to_ts_ptr(self$pointer, options = init_options)
      TreeSequence$new(pointer = ts_ptr)
    },

    #' @description This function saves a table collection from R to disk and
    #'   loads it into reticulate Python for use with the \code{tskit} Python API.
    #' @param tskit_module reticulate Python module of \code{tskit}. By default,
    #'   it calls \code{\link{get_tskit_py}} to obtain the module.
    #' @param cleanup logical; delete the temporary file at the end of the function?
    #' @details See \url{https://tskit.dev/tutorials/tables_and_editing.html#tables-and-editing}
    #'   on what you can do with the tables.
    #' @return Table collection in reticulate Python.
    #' @seealso \code{\link{tc_py_to_r}}, \code{\link{tc_load}}, and
    #'   \code{\link[=TableCollection]{TableCollection$dump}}.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc_r <- tc_load(ts_file)
    #' is(tc_r)
    #' tc_r$print()
    #'
    #' # Transfer the table collection to reticulate Python and use tskit Python API
    #' tskit <- get_tskit_py()
    #' if (check_tskit_py(tskit)) {
    #'   tc_py <- tc_r$r_to_py()
    #'   is(tc_py)
    #'   tmp <- tc_py$simplify(samples = c(0L, 1L, 2L, 3L))
    #'   tmp
    #'   tc_py$individuals$num_rows # 2
    #'   tc_py$nodes$num_rows # 10
    #'   tc_py$nodes$time # 0.0 ... 7.4702817
    #' }
    r_to_py = function(tskit_module = get_tskit_py(), cleanup = TRUE) {
      tc_ptr_r_to_py(
        self$pointer,
        tskit_module = tskit_module,
        cleanup = cleanup
      )
    },

    #' @description Print a summary of a table collection and its contents.
    #' @return A list with two data.frames; the first contains table collection
    #'   properties and their values; the second contains the number of rows in
    #'   each table and the length of their metadata.
    #' @examples
    #' ts_file <- system.file("examples/test.trees", package = "RcppTskit")
    #' tc <- tc_load(file = ts_file)
    #' tc$print()
    #' tc
    print = function() {
      ret <- tc_ptr_print(self$pointer)
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
