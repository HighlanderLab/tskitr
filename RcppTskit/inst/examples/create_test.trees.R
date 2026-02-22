# install.packages("reticulate")
library(reticulate)

# Using Python packages installed via reticulate
py_require("msprime")
# Using Python packages installed via conda (if available)
if (condaenv_exists("arg_work")) {
  use_condaenv("arg_work")
}

# Access to main Python environment (say if you have run a script and then objects are in main)
# main <- import_main()
# main$x
# ... or
# py$x
# Access builtin Python functionality
builtins <- import_builtins()

# ARG packages
msprime <- import("msprime")
tskit <- import("tskit")

# -----------------------------------------------------------------------------

# Generate a tree sequence for testing
ts <- msprime$sim_ancestry(
  samples = 8,
  sequence_length = 1e2,
  recombination_rate = 1e-2,
  random_seed = 42
)
ts <- msprime$sim_mutations(ts, rate = 2e-2, random_seed = 42)
ts
cat(py_str(ts))
builtins$print(ts)
ts$num_provenances # 2
ts$num_populations # 1
ts$num_migrations # 0
ts$num_individuals # 8
ts$num_samples # 16
ts$num_nodes # 39
ts$num_edges # 59
ts$num_trees # 9
ts$num_sites # 25
ts$num_mutations # 30
ts$sequence_length # 100.0
ts$time_units # generations
ts$min_time # 0.0
ts$max_time # 6.961993337190808

ts$metadata # b''
builtins$type(ts$metadata) # <class 'bytes'>
py_len(ts$metadata) # 0
# ts$metadata$shape # 'bytes' object has no attribute 'shape'

schema <- ts$metadata_schema
# empty

ts$tables$populations$metadata # R vector
builtins$type(ts$tables$populations$metadata) # numpy.ndarray
length(ts$tables$populations$metadata) # 33
# ts$tables$populations$metadata$shape # $ operator is invalid for atomic vectors
# ts$tables$populations$metadata.shape # AttributeError: 'ImmutablePopulationTable' object has no attribute 'metadata.shape'

schema <- ts$tables$populations$metadata_schema
# {"additionalProperties":true,"codec":"json","properties":{"description":{"type":["string","null"]},"name":{"type":"string"}},"required":["name","description"],"type":"object"}
schema$asdict()
# $additionalProperties
# [1] TRUE
#
# $codec
# [1] "json"
# ...

ts$tables$migrations$metadata # integer(0)
builtins$type(ts$tables$migrations$metadata) # numpy.ndarray
length(ts$tables$migrations$metadata) # 0
# ts$tables$migrations$metadata$shape # $ operator is invalid for atomic vectors
# ts$tables$migrations$metadata.shape # AttributeError: 'ImmutablePopulationTable' object has no attribute 'metadata.shape'

ts$tables$individuals$metadata # integer(0)
builtins$type(ts$tables$individuals$metadata) # numpy.ndarray
length(ts$tables$individuals$metadata) # 0
# ts$tables$individuals$metadata$shape # $ operator is invalid for atomic vectors
# ts$tables$individuals$metadata.shape # AttributeError: 'ImmutablePopulationTable' object has no attribute 'metadata.shape'

ts$dump("inst/examples/test.trees")
# ts <- tskit$load("inst/examples/test.trees")

# -----------------------------------------------------------------------------

# Create a second tree sequence with metadata in some tables
# basic_schema <- tskit$MetadataSchema("{'codec': 'json'}")
# Can't get this to work via reticulate :(
# see create_test.trees.py

ts <- tskit$load("inst/examples/test2.trees")
ts
ts$num_individuals # 9

ts$metadata
# $mean_coverage
# [1] 200.5
builtins$type(ts$metadata) # dict
len(ts.metadata) # 1
ts$metadata_schema # {"codec":"json"}

ts$tables$individuals$metadata # R vector
builtins$type(ts$tables$individuals$metadata) # numpy.ndarray
length(ts$tables$individuals$metadata) # 21

# -----------------------------------------------------------------------------

# Another example with a reference sequence

ts <- msprime$sim_ancestry(
  samples = 3,
  ploidy = 2,
  sequence_length = 10,
  random_seed = 2
)
ts <- msprime$sim_mutations(ts, rate = 0.1, random_seed = 2)
ts$has_reference_sequence() # FALSE
ts$reference_sequence # NULL

tables <- ts$dump_tables()
tables$reference_sequence$data <- "ATCGAATTCG"
ts <- tables$tree_sequence()
ts$has_reference_sequence() # TRUE
ts$reference_sequence
# ReferenceSequence({'metadata_schema': '', 'metadata': b'', 'data': 'ATCGAATTCG', 'url': ''})

ali <- ts$alignments()
iterate(ali, function(i) cat(i, "\n"))
# iterate(ali, function(i) print(i)) # produces no output
ali_vec <- iterate(ts$alignments())
print(ali_vec)

ts$dump("RcppTskit/inst/examples/test_with_ref_seq.trees")

# -----------------------------------------------------------------------------
