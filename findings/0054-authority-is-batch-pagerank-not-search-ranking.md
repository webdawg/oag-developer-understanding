# 0054 — Authority is batch PageRank, not a live search rank

Claim `B-054`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, authority
recomputes PageRank from all local edges, clears stored scores, and writes the
new scores. It is not triggered by ordinary writes, and neither lexical nor
semantic search reads those scores while ranking.

## Algorithm and freshness

The graph treats an edge as rank flowing from subject to object. Damping is
`0.85`, iteration stops at 50 passes or a total absolute movement below `1e-6`,
and nodes with no outgoing edges redistribute their score uniformly. Only nodes
that appear in at least one edge receive scores. Isolated nodes therefore have
no stored authority after recomputation.

The service clears all authority rows before writing replacements. A failure
after clearing can leave scores absent; that crash window was not tested.
`get_node_authority` returns `None` when no score exists. The node read API can
include that optional value, but search queries inspected earlier order by FTS
rank or cosine similarity only.

The score describes local graph structure, not truth, corroboration, or global
importance. It uses all stored edges and does not inspect assertion status in
this function.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-054a | Implemented | `crates/oag-graph/src/authority.rs:15-88` |
| B-054b | Implemented | `crates/oag-graph/src/authority.rs:99-122` |
| B-054c | Comparison | Search ordering in `nodes.rs:166-171` and semantic ranking in `semantic_search.rs:94-111` |

Verification: source inspection only. PageRank tests were not executed.

## Next investigation

Trace rebuild from the event log and determine which projections are erased, replayed, or intentionally preserved.