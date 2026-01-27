# install.packages("slendr")
library(slendr)
# setup_env() # run in the first session
init_env() # run in future sessions
mode_file <- system.file("extdata/models/introgression", package = "slendr")
model <- read_model(path = mode_file)
print(model)
# slendr 'model' object
# ---------------------
# populations: CH, AFR, NEA, EUR
...

afr <- model$populations[["AFR"]]
eur <- model$populations[["EUR"]]
samples <- schedule_sampling(model, times = 0, list(afr, 10), list(eur, 100))
ts <- msprime(
  model,
  sequence_length = 100,
  recombination_rate = 0.001,
  samples = samples
) # this will not be instant ... but not too long either
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
# --> a complex object lives in reticulate Python
#     and is wrapped by an R object in R
#     https://rstudio.github.io/reticulate/#type-conversions

print(ts$num_samples)
# [1] 220
# --> a simple object (like an integer) is converted to an R object
#     https://rstudio.github.io/reticulate/#type-conversions

ts <- ts_mutate(ts, mutation_rate = 0.0001)
G <- ts$genotype_matrix()
str(G)
# int [1:100, 1:220] 0 0 2 2 0 2 1 0 0 1 ...
reticulate::py_id(G)
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
