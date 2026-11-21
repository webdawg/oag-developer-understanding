# 0063 — Subgraph traversal follows every edge direction, but its cap is soft

Claim `B-063`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, subgraph
retrieval walks breadth-first from a root through both ends of every touching
edge. Visited node IDs prevent cycles and make the first reaching hop the
recorded distance. The `max_nodes` check does not strictly cap the returned
node count.

## Traversal

The root must exist. Each hop lists edges touching the current frontier and
considers both subject and object, so traversal is undirected despite edge
storage being directional. A candidate already seen is not revisited. Assertions
are then loaded for every visited edge, with no status filter in this function.

The cap is checked before processing an edge. Once an edge passes that check,
both of its endpoints may be inserted. The `break` only exits the current
node's edge loop; the next frontier node is still processed and can add more
nodes until its own loop observes the cap. The result can therefore exceed
`max_nodes`, omit later edges non-deterministically according to database
listing order, and still include every assertion on the edges that were
visited. Output order follows hash-map iteration and is not a stable rank.

The REST caller defaults depth and maximum were not rechecked in this finding.
No traversal test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-063 | Implemented | `crates/oag-graph/src/subgraph.rs:28-88` |

Verification: source inspection only.

## Next investigation

Trace the REST subgraph defaults and determine whether callers can request an unbounded or very large traversal.