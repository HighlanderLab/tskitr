TODO: Write the STATE_and_AIMS.md file on what we want to achieve with the tskitr package #12
      https://github.com/HighlanderLab/tskitr/issues/12

# STATE of the tree sequence ecosystem and AIMS for `tskitr`

## STATE of the tree sequence ecosystem

The tree sequence ecosystem is rapidly evolving (see https://tskit.dev). There are now multiple packages supporting generation of tree sequences and there is a growing number of APIs for analysing them. This is a quick summary of the state of the ecosystem as of December 2025.

  * `tskit` (https://tskit.dev/tskit/docs, https://github.com/tskit-dev/tskit) is the core tree sequence toolkit. It has a C API and Python API. Python API is popular entry point for most users. There is also a Rust API that interfaces the C API.

  * `msprime` (https://tskit.dev/msprime/docs, https://github.com/tskit-dev/msprime) generates tree sequences with backward in time simulation. It has Python API and command line interface.

  * `SLiM` (https://messerlab.org/slim, https://github.com/MesserLab/SLiM) generates tree sequences with forward in time simulation. It is written in C++ (with embedded tskit C library) and has command line and GUI interface. It's tree sequence recording is described in great detail at https://github.com/MesserLab/SLiM/blob/master/treerec/implementation.md.

  * `pyslim` (https://tskit.dev/pyslim/docs, https://github.com/tskit-dev/pyslim) provides a Python API for reading and modifying tskit tree sequence files produced by SLiM, or modifying files produced by other programs (e.g., msprime) for use in SLiM.

  * `fwdpy11` (https://molpopgen.github.io/fwdpy11, https://github.com/molpopgen/fwdpy11) generates tree sequences with forward in time simulation. It has a Python API, which is built on C++ API (`fwdpp`).

  * `stdpopsim` (https://popsim-consortium.github.io/stdpopsim-docs, https://github.com/popsim-consortium/stdpopsim) is a standard library of population genetic models used in simulations with `msprime` and `SLiM`. It has Python API and command line interface.

  * `slendr` (https://bodkan.net/slendr, https://github.com/bodkan/slendr) is an R package for describing population genetic models, simulating them with either `msprime` or `SLiM`, and analysing resulting tree sequences using `tskit`. It calls `msprime`, `pyslim`, and `tskit` via R package `reticulate` (that enables calling Python from within R), while it calls `SLiM` via R `system()/shell()` function. It implemented R wrappers for a number of `tskit` functions, such as `ts_read()`, `ts_write()`, `ts_simplify()`, `ts_mutate()`, etc. The wrappers call Python functions (via reticulate) and perform additional actions required for integration with R and `slendr` functionality.

  * `slimr` (https://rdinnager.github.io/slimr, https://github.com/rdinnager/slimr) provides an R API for specifying and running SLiM scripts and analysing results in R. It runs `SLiM` via R package `processx`.

  * `tsinfer` (https://tskit.dev/tsinfer/docs, https://github.com/tskit-dev/tsinfer) generates tree sequence from observed genomic (haplotype) data. It has Python API and command line interface.

As described above, the tree sequence ecosystem is extensive. Python is the most widely used and complete interface for simulation and analysis of tree sequences.

There is an interest for work with tree sequences in R. Because we can call Python from within R with `reticulate`, there is no pressing need for a dedicated R support for work with tree sequences. See https://tskit.dev/tutorials/tskitr.html on how this looks like and further details at https://rstudio.github.io/reticulate. In a way, this situation will positively focus the community on the Python collection of packages. While there are some differences between R and Python, many R users will be able to work with the extensive Python documentation and examples. For example, the reticulate-based-calls from within R look like this:


TODO: Move this to an external file (since it's quite long)?
```
# install.packages(c("reticulate")
library(reticulate)
reticulate::py_require("msprime")
# msprime and tskit Python API calls from within R via reticulate
msprime <- reticulate::import("msprime")
ts <- msprime$sim_ancestry(10, sequence_length=100, recombination_rate=0.1)
is(ts)
# "tskit.trees.TreeSequence"
class(ts)
# [1] "tskit.trees.TreeSequence" "python.builtin.object"
ts$`__class__`
# <class 'tskit.trees.TreeSequence'>
# signature: (ll_tree_sequence)
print(ts)
# <tskit.trees.TreeSequence object at 0x15d602990>
cat(py_str(ts))
# ╔═══════════════════════════╗
# ║TreeSequence               ║
# ╠═══════════════╤═══════════╣
# ║Trees          │         73║
# ...
cat(py_repr(ts))
# <tskit.trees.TreeSequence object at 0x15d602990>
lobstr::obj_addr(ts)
# 0x165359eb0
py_id(ts)
# [1] "5861550480"
# --> a complex object lives in Python session (managed by reticulate)
#     and is wrapped by an R object
#     https://rstudio.github.io/reticulate/#type-conversions

print(ts$num_samples)
# [1] 20
# --> a simple object (like an integer) is converted to an R object
#     https://rstudio.github.io/reticulate/#type-conversions

ts <- msprime$sim_mutations(ts, rate=0.1)
ts <- ts$simplify(0:4)
G <- ts$genotype_matrix()
str(G)
# int [1:54, 1:5] 0 0 0 0 0 ...
# py_id(G)
# Error: ! Expected a python object, received a integer
# --> a simple object (like a NumPy array) is converted to an R object
#     https://rstudio.github.io/reticulate/#type-conversions
#     https://rstudio.github.io/reticulate/articles/arrays.html

# G is an R matrix object so we can use R functions on it
allele_frequency <- rowMeans(G)
allele_frequency
```

To provide idiomatic R interface to some population genetic simulation steps and operations with tree sequences, `slendr` implemented bespoke functions and wrapper functions that use `reticulate` to call Python packages and their functions. This further lowers barriers for R users. For example, the code calls from within R look like this:

TODO: Move this to an external file (since it's quite long)?
```
# install.packages(c("slendr"))
library(slendr)
# setup_env() # run in the first session
init_env() # run in future sessions
model <- read_model(path=system.file("extdata/models/introgression",
  package="slendr"))
print(model)
# slendr 'model' object
# ---------------------
# populations: CH, AFR, NEA, EUR
...

afr <- model$populations[["AFR"]]
eur <- model$populations[["EUR"]]
samples <- schedule_sampling(model, times=0, list(afr, 10), list(eur, 100))
ts <- msprime(model, sequence_length=100, recombination_rate=0.001,
  samples=samples)
is(ts)
# [1] "slendr_ts"
class(ts)
# [1] "slendr_ts" "tskit.trees.TreeSequence" "python.builtin.object"
ts$`__class__`
# <class 'tskit.trees.TreeSequence'>
# signature: (ll_tree_sequence)
print(ts)
# ╔═══════════════════════════╗
# ║TreeSequence               ║
# ╠═══════════════╤═══════════╣
# ║Trees          │        100║
# ...
cat(reticulate::py_str(ts))
# ╔═══════════════════════════╗
# ║TreeSequence               ║
# ╠═══════════════╤═══════════╣
# ║Trees          │        100║
# ...
cat(reticulate::py_repr(ts))
# <tskit.trees.TreeSequence object at 0x15f556c10>
lobstr::obj_addr(ts)
reticulate::py_id(ts)
# [1] "5894401040"
# --> a complex object lives in Python session (managed by reticulate)
#     and is wrapped by an R object
#     https://rstudio.github.io/reticulate/#type-conversions

print(ts$num_samples)
# [1] 220
# --> a simple object (like an integer) is converted to an R object
#     https://rstudio.github.io/reticulate/#type-conversions

ts <- ts_mutate(ts, mutation_rate=0.0001)
G <- ts$genotype_matrix()
str(G)
# int [1:100, 1:220] 0 0 2 2 0 2 1 0 0 1 ...
# py_id(G)
# Error: ! Expected a python object, received a integer
# --> a simple object (like a NumPy array) is converted to an R object
#     https://rstudio.github.io/reticulate/#type-conversions
#     https://rstudio.github.io/reticulate/articles/arrays.html

# G is an R matrix object so we can use R functions on it
allele_frequency <- rowMeans(G)
allele_frequency

# An alternative from slendr
G <- ts_genotypes(ts)
# 98 multiallelic sites (98.000% out of 100 total) detected and removed
str(G)
# tibble [2 × 221] (S3: tbl_df/tbl/data.frame)
#  $ pos         : int [1:2] 40 80
#  $ AFR_1_chr1  : int [1:2] 0 0

# G is an R tibble object so we can use R functions on it
G <- as.matrix(G[, -1])
allele_frequency <- rowMeans(G)
allele_frequency
```

One downside of using `reticulate` is the overhead of calling Python functions, which can add up if they are called many times, say within an R loop. This overhead is minimal for most analyses as these would call a few functions, so most of the work, looping, etc. is done on Python side, often in tskit's C code). However, the overhead can be limiting for repeated calling of tskit functions, say for tree sequence recording and bespoke analyses (though ideally these would be implemented in Python and possibly ported to C/C++).

## AIMS for `tskitr`

Given the above state of the tree sequence ecosystem, the primary aims of the `tskitr` package are:

### 1) To load a tree sequence into an R session and summarise its contents (IMPLEMENTED)

Here is an example:

```
# Load package and print tskit version
library(tskitr)
tskit_version()
# major minor patch
#     1     3     0

# Get a package tree sequence
ts_file <- system.file("examples", "test.trees", package="tskitr")
ts <- tskitr::ts_load(ts_file)
ts
# <pointer: 0x1236b4220>

# Summarise
ts_num(ts)
# $num_provenances
# [1] 2
# $num_populations
# [1] 1
# $num_migrations
# [1] 0
# $num_individuals
# [1] 80
...
ts_num_individuals(ts)
# [1] 80
?ts_num
# see the implemented ts_num_x() functions
```

TODO: create a summary()/print() method for ts? To do so, we would need to have a class that would hold the pointer!

### 2) To call tskit C API in C++ code within an R session or an R package (IMPLEMENTED)

Here is an example:

```
# Load packages
library(Rcpp)
library(tskitr)

# Write and compile C++ function
codeString <- '
    #include <tskit.h>
    int ts_num_individuals(SEXP ts) {
        int n;
        Rcpp::XPtr<tsk_treeseq_t> xptr(ts);
        n = (int) tsk_treeseq_get_num_individuals(xptr);
        return n;
    }'
get_num_individuals <- cppFunction(code=codeString, depends="tskitr", plugins="tskitr")

# Get a package tree sequence
ts_file <- system.file("examples", "test.trees", package="tskitr")
ts <- tskitr::ts_load(ts_file)

# Apply the compiled function
get_num_individuals(ts)
# [1] 80

# Identical tskitr implementation
ts_num_individuals(ts)
# [1] 80
```

### 3) To call tskit C API in C++ code within an R package (TODO)

For an R package we have to:

TODO: provide steps here.

### 4) To call tskit C API in R code within an R session or an R package (TODO)

doable, but do we want/need this? - we would have to write Rcpp wrappers for all the functions in tskit C API! Could this be automated somehow? Would Rcpp module help here?)