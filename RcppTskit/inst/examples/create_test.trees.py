import msprime
import tskit
import os

# -----------------------------------------------------------------------------

# Generate a tree sequence for testing
ts = msprime.sim_ancestry(
    samples=8, sequence_length=1e2, recombination_rate=1e-2, random_seed=42
)
ts = msprime.sim_mutations(ts, rate=2e-2, random_seed=42)
ts
print(ts)
ts.num_provenances  # 2
ts.num_populations  # 1
ts.num_migrations  # 0
ts.num_individuals  # 8
ts.num_samples  # 16
ts.num_nodes  # 39
ts.num_edges  # 59
ts.num_trees  # 9
ts.num_sites  # 25
ts.num_mutations  # 30
ts.sequence_length  # 100.0
ts.time_units  # 'generations'
ts.min_time  # 0.0
ts.max_time  # 6.961993337190808

ts.metadata  # b''
type(ts.metadata)  # bytes
len(ts.metadata)  # 0
# ts.metadata.shape # 'bytes' object has no attribute 'shape'

ts.metadata_schema
# empty

ts.tables.populations.metadata  # array() ...
type(ts.tables.populations.metadata)  # numpy.ndarray
len(ts.tables.populations.metadata)  # 33
ts.tables.populations.metadata.shape  # (33,)

schema = ts.tables.populations.metadata_schema
# {"additionalProperties":true,"codec":"json","properties":{"description":{"type":["string","null"]},"name":{"type":"string"}},"required":["name","description"],"type":"object"}
schema.asdict()
# OrderedDict([('additionalProperties', True),
#              ('codec', 'json'),
# ...

ts.tables.migrations.metadata  # array() ...
type(ts.tables.migrations.metadata)  # numpy.ndarray
len(ts.tables.migrations.metadata)  # 0
ts.tables.migrations.metadata.shape  # (0,)

ts.tables.individuals.metadata  # array() ...
type(ts.tables.individuals.metadata)  # numpy.ndarray
len(ts.tables.individuals.metadata)  # 0
ts.tables.individuals.metadata.shape  # (0,)

os.getcwd()
ts.dump("RcppTskit/inst/examples/test.trees")
tskit.load("RcppTskit/inst/examples/test.trees").file_uuid
# '79ec383f-a57d-b44f-2a5c-f0feecbbcb32'
# test_trees_file_uuid <- "79ec383f-a57d-b44f-2a5c-f0feecbbcb32"
# ts = tskit.load("RcppTskit/inst/examples/test.trees")

# -----------------------------------------------------------------------------

# Create a second tree sequence with metadata in some tables
# ts = tskit.load("RcppTskit/inst/examples/test.trees")
ts2_tables = ts.dump_tables()
len(ts2_tables.metadata)
# ts2_tables.metadata = tskit.pack_bytes('{"seed": 42, "note": "ts2"}')
# TypeError: string argument without an encoding

# Create a second tree sequence with metadata in some tables
basic_schema = tskit.MetadataSchema({"codec": "json"})
basic_schema
# {"codec":"json"}
tables = ts.dump_tables()
tables.metadata_schema = basic_schema
tables.metadata_schema
# {"codec":"json"}
tables.metadata = {"mean_coverage": 200.5}
tables.metadata
# {'mean_coverage': 200.5}

tables.individuals.metadata_schema = tskit.MetadataSchema(None)
tables.individuals.metadata
len(tables.individuals)  # 8
tables.individuals[0]
# IndividualTableRow(flags=0, location=array([], dtype=float64), parents=array([], dtype=int32), metadata=b'')
tables.individuals[0].metadata
# b''
tables.individuals[7]
# ...
tables.individuals[7].metadata
# b''
tables.individuals.add_row(metadata=b"SOME CUSTOM BYTES #!@")
tables.individuals[8]
# IndividualTableRow(flags=0, location=array([], dtype=float64), parents=array([], dtype=int32), metadata=b'SOME CUSTOM BYTES #!@')
tables.individuals[8].metadata
# b'SOME CUSTOM BYTES #!@'

ts = tables.tree_sequence()
ts
ts.num_individuals  # 9

ts.metadata  # {'mean_coverage': 200.5}
type(ts.metadata)  # dict
len(ts.metadata)  # 1
ts.metadata_schema  # {"codec":"json"}
ts.metadata_schema

ts.tables.individuals.metadata  # array() ...
type(ts.tables.individuals.metadata)  # numpy.ndarray
len(ts.tables.individuals.metadata)  # 21
ts.tables.individuals.metadata.shape  # (21,)

ts.dump("RcppTskit/inst/examples/test2.trees")
tskit.load("RcppTskit/inst/examples/test2.trees").file_uuid
# 'cf406b8c-be33-af4a-c00b-a4de1e6151ff'
# test2_trees_file_uuid <- "cf406b8c-be33-af4a-c00b-a4de1e6151ff"

tables = ts.dump_tables()
tables.metadata_schema = tskit.MetadataSchema(None)
tables.metadata
# b'{"mean_coverage":200.5}'
ts = tables.tree_sequence()
ts.metadata
len(ts.metadata)  # 23

# -----------------------------------------------------------------------------

# Tiny example with a non-discrete genome (continuous coordinates)

ts = msprime.sim_ancestry(
    samples=2,
    sequence_length=10.5,
    recombination_rate=1e-2,
    random_seed=7,
    discrete_genome=False,
)
ts.discrete_genome  # False
ts.sequence_length  # 10.5
ts.dump("RcppTskit/inst/examples/test_non_discrete_genome.trees")
tskit.load("RcppTskit/inst/examples/test_non_discrete_genome.trees").file_uuid
# '42bc7ad8-f3a2-e722-a7e3-7f87c6c1dfc2'

# -----------------------------------------------------------------------------

# Another example with a reference genome sequence

ts = msprime.sim_ancestry(samples=3, ploidy=2, sequence_length=10, random_seed=2)
ts = msprime.sim_mutations(ts, rate=0.1, random_seed=2)
ts.has_reference_sequence()
ts.reference_sequence

tables = ts.dump_tables()
tables.reference_sequence.data = "ATCGAATTCG"
ts = tables.tree_sequence()
ts.has_reference_sequence()
ts.reference_sequence

ali = ts.alignments()
for i in ali:
    print(i)

ts.dump("RcppTskit/inst/examples/test_with_ref_seq.trees")
tskit.load("RcppTskit/inst/examples/test_with_ref_seq.trees").file_uuid
# '71793465-49ed-e0f3-0657-c01926226b29'
# test_with_ref_seq_file_uuid <- "71793465-49ed-e0f3-0657-c01926226b29"

# -----------------------------------------------------------------------------

# Tiny example with discrete time values

tables = tskit.TableCollection(sequence_length=10)
tables.nodes.add_row(flags=tskit.NODE_IS_SAMPLE, time=0)
tables.nodes.add_row(flags=tskit.NODE_IS_SAMPLE, time=0)
tables.nodes.add_row(time=1)
tables.edges.add_row(0, 10, parent=2, child=0)
tables.edges.add_row(0, 10, parent=2, child=1)
tables.sort()
ts = tables.tree_sequence()
ts.discrete_time  # True
ts.num_trees  # 1
ts.dump("RcppTskit/inst/examples/test_discrete_time.trees")
tskit.load("RcppTskit/inst/examples/test_discrete_time.trees").file_uuid
# 'ff35bc1d-8592-097c-c70a-03828ad847d8'

# -----------------------------------------------------------------------------
