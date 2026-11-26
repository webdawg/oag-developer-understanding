# 0176 — Subgraph nodes and edges are ordered; assertions are not

Claim `B-0176`: at core `fb54e431332a030a566099c76fb2558084765422`,
`get_subgraph` sorts returned nodes by `(distance, canonical_identifier)` and
edges by edge ID before responding. Assertions are collected earlier from a
`HashMap` key iterator, so their order remains unspecified. The source comment
claims assertion order became deterministic too; the inspected statement order
does not support that claim.

## Order of behavior

1. A breadth-first walk starts at the root, follows `edges::list_touching` in
   both directions, and records first-seen distances. `max_nodes` is checked
   before adding nodes, so the node count is bounded but the edge list can grow
   from edges that add no new node (finding 0063).
2. After traversal, the code iterates `visited_edges.keys()` and appends every
   assertion for each edge. At this point `visited_edges` is still a
   `HashMap`, so assertion grouping order is unspecified.
3. It then sorts `nodes` by `(distance, canonical_identifier)` and `edges` by
   `edge.id`. These two output arrays are deterministic for the same visited
   set.
4. The returned `Subgraph` contains the sorted nodes, sorted edges, and the
   previously collected assertions. A missing root or any SQL error aborts
   before a partial response is built.

## What is durable, rejected, and left behind

The subgraph is a read-only derived view; nothing is stored. Rejected: a root
that does not exist returns `GraphError::NotFound`, and a query failure
propagates. No partial subgraph is returned on those paths.

The source comment says assertions "keep the edge iteration order, which is now
deterministic too". The actual assertion loop runs before `edges.sort_by_key`
and uses `visited_edges.keys()`, not the sorted vector. This finding records the
implementation: node and edge arrays are reproducible, assertion array order is
not. No request or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0176a | Implemented traversal and assertion collection | `crates/oag-graph/src/subgraph.rs:26-83` |
| B-0176b | Implemented node/edge sorting | `crates/oag-graph/src/subgraph.rs:85-100` |
| B-0176c | Documented intent not matching statement order | `crates/oag-graph/src/subgraph.rs:85-91` |
| B-0176d | New since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/subgraph.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No subgraph request or target test was executed.

## Change since the previously explained commit

At `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, all three arrays came directly
from `HashMap` values/keys. At `fb54e431...`, nodes and edges are sorted.
Finding 0063's soft-cap and both-direction traversal claims still hold at the
newer commit; this is a correction finding for assertion ordering, not a silent
rewrite of 0063.

## Next investigation

Trace `oag_graph::resolve` at the newer commit to document which candidate
fields are compared and whether deterministic ordering was added there too.
