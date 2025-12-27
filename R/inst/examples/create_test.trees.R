# install.packages("reticulate")
reticulate::py_require("msprime")
msprime <- reticulate::import("msprime")
ts <- msprime$sim_ancestry(
  samples = 80,
  sequence_length = 1e4,
  recombination_rate = 1e-4,
  random_seed = 42
)
ts <- msprime$sim_mutations(ts, rate = 1e-2, random_seed = 42)
ts
ts$num_provenances # 2
ts$num_populations # 1
ts$num_migrations # 0
ts$num_individuals # 80
ts$num_samples # 160
ts$num_nodes # 344
ts$num_edges # 414
ts$num_trees # 26
ts$num_sites # 2376
ts$num_mutations # 2700
ts$dump("inst/examples/test.trees")

tskit <- reticulate::import("tskit")
ts2 <- tskit$load("inst/examples/test.trees")
ts2
stopifnot(ts2$num_provenances == 2)
stopifnot(ts2$num_populations == 1)
stopifnot(ts2$num_migrations == 0)
stopifnot(ts2$num_individuals == 80)
stopifnot(ts2$num_samples == 160)
stopifnot(ts2$num_nodes == 344)
stopifnot(ts2$num_edges == 414)
stopifnot(ts2$num_trees == 26)
stopifnot(ts2$num_sites == 2376)
stopifnot(ts2$num_mutations == 2700)
