# install.packages("reticulate")
reticulate::py_require("msprime")
msprime <- reticulate::import("msprime")

# Generate a tree sequence for testing
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
ts$sequence_length # 10000.0
ts$time_units # generations

# TODO:how do I run
len(ts$metadata)?ts$metadata
ts$tables$metadata
ts$tables$migrations$metadata
ts$tables$populations$metadata
ts$tables$individuals$metadata
ts$tables$nodes$metadata
ts$tables$edges$metadata
ts$tables$sites$metadata
ts$tables$mutations$metadata

ts$dump("inst/examples/test.trees")
ts_original <- ts

tskit <- reticulate::import("tskit")
ts <- tskit$load("inst/examples/test.trees")
ts


# Create a second tree sequence with metadata in some tables
ts2_tables <- ts$dump_tables()
set.seed(123)
ts2_tables$metadata <- charToRaw(
  paste0("{\"seed\":", sample.int(100000, 1), ",\"note\":\"ts2\"}")
)

node_md <- rep(list(raw(0)), ts2_tables$nodes$num_rows)
node_md[[1]] <- charToRaw("node:1")
node_md[[ts2_tables$nodes$num_rows]] <- charToRaw("node:last")
node_md_packed <- tskit$pack_bytes(node_md)
ts2_tables$nodes$set_columns(
  flags = ts2_tables$nodes$flags,
  time = ts2_tables$nodes$time,
  population = ts2_tables$nodes$population,
  individual = ts2_tables$nodes$individual,
  metadata = node_md_packed[[1]],
  metadata_offset = node_md_packed[[2]]
)

site_md <- rep(list(raw(0)), ts2_tables$sites$num_rows)
if (ts2_tables$sites$num_rows > 0) {
  site_md[[1]] <- charToRaw("site:1")
}
if (ts2_tables$sites$num_rows > 1) {
  site_md[[2]] <- charToRaw("site:2")
}
site_md_packed <- tskit$pack_bytes(site_md)
ts2_tables$sites$set_columns(
  position = ts2_tables$sites$position,
  ancestral_state = ts2_tables$sites$ancestral_state,
  ancestral_state_offset = ts2_tables$sites$ancestral_state_offset,
  metadata = site_md_packed[[1]],
  metadata_offset = site_md_packed[[2]]
)

pop_md <- rep(list(raw(0)), ts2_tables$populations$num_rows)
if (ts2_tables$populations$num_rows > 0) {
  pop_md[[1]] <- charToRaw("pop:1")
}
pop_md_packed <- tskit$pack_bytes(pop_md)
ts2_tables$populations$set_columns(
  metadata = pop_md_packed[[1]],
  metadata_offset = pop_md_packed[[2]]
)

ts2 <- ts2_tables$tree_sequence()
ts2$dump("inst/examples/test_with_metadata.trees")


# Create a second tree sequence with metadata in some tables
ts2_tables <- ts$dump_tables()
set.seed(123)
ts2_tables$metadata <- charToRaw(
  paste0("{\"seed\":", sample.int(100000, 1), ",\"note\":\"ts2\"}")
)

node_md <- rep(list(raw(0)), ts2_tables$nodes$num_rows)
node_md[[1]] <- charToRaw("node:1")
node_md[[ts2_tables$nodes$num_rows]] <- charToRaw("node:last")
node_md_packed <- tskit$pack_bytes(node_md)
ts2_tables$nodes$set_columns(
  flags = ts2_tables$nodes$flags,
  time = ts2_tables$nodes$time,
  population = ts2_tables$nodes$population,
  individual = ts2_tables$nodes$individual,
  metadata = node_md_packed[[1]],
  metadata_offset = node_md_packed[[2]]
)

site_md <- rep(list(raw(0)), ts2_tables$sites$num_rows)
if (ts2_tables$sites$num_rows > 0) {
  site_md[[1]] <- charToRaw("site:1")
}
if (ts2_tables$sites$num_rows > 1) {
  site_md[[2]] <- charToRaw("site:2")
}
site_md_packed <- tskit$pack_bytes(site_md)
ts2_tables$sites$set_columns(
  position = ts2_tables$sites$position,
  ancestral_state = ts2_tables$sites$ancestral_state,
  ancestral_state_offset = ts2_tables$sites$ancestral_state_offset,
  metadata = site_md_packed[[1]],
  metadata_offset = site_md_packed[[2]]
)

pop_md <- rep(list(raw(0)), ts2_tables$populations$num_rows)
if (ts2_tables$populations$num_rows > 0) {
  pop_md[[1]] <- charToRaw("pop:1")
}
pop_md_packed <- tskit$pack_bytes(pop_md)
ts2_tables$populations$set_columns(
  metadata = pop_md_packed[[1]],
  metadata_offset = pop_md_packed[[2]]
)

ts2 <- ts2_tables$tree_sequence()
ts2$dump("inst/examples/test_with_metadata.trees")
