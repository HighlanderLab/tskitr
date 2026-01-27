# install.packages("reticulate")
library(reticulate)
reticulate::py_require("msprime")
# msprime and tskit Python API calls from within R via reticulate
msprime <- reticulate::import("msprime")
ts <- msprime$sim_ancestry(10, sequence_length = 100, recombination_rate = 0.1)
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
# 0x177073e40
py_id(ts)
# [1] "5861550480"
# --> a complex object exist in reticulate Python
#     and is wrapped by an R object in R
#     https://rstudio.github.io/reticulate/#type-conversions

print(ts$num_samples)
# [1] 20
# --> a simple object (like an integer) is converted to an R object
#     https://rstudio.github.io/reticulate/#type-conversions

ts <- msprime$sim_mutations(ts, rate = 0.1)
ts <- ts$simplify(samples = c(0L, 1L, 2L, 3L))
G <- ts$genotype_matrix()
str(G)
# int [1:54, 1:4] 0 0 0 0 0 ...
py_id(G)
# Error: ! Expected a python object, received a integer
# --> a simple object (like a NumPy array) is converted to an R object
#     https://rstudio.github.io/reticulate/#type-conversions
#     https://rstudio.github.io/reticulate/articles/arrays.html

# G is an R matrix object so we can use R functions on it
allele_frequency <- rowMeans(G)
allele_frequency
