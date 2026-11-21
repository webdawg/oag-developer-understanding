# 0052 — Semantic search does not apply lexical suppression

Claim `B-052`: at core `87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe`, semantic
search embeds the query, loads every row from `node_embeddings`, ranks cosine
similarity, and resolves node IDs directly. The inspected path never checks
`search_suppressions`.

## Visibility gap

Lexical search excludes suppressed node IDs. Semantic search instead calls
`node_embeddings::list_all`, which selects the whole embedding table, and then
`nodes::get_by_id` for each ranked result. A node hidden from lexical search can
therefore remain discoverable through semantic search while its embedding and
node row exist.

When the provider is disabled, the function returns a typed embedding-disabled
error rather than an empty success. That prevents a silent false negative, but
it is unrelated to suppression. The ranking limit is clamped, and missing node
rows are skipped. No authorization check appears inside this method; its API
caller separately uses the shared read gate.

This is a visibility inconsistency, not evidence that embeddings contain secret
material. What text was embedded depends on the embedding builder and was not
fully traced here.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-052a | Implemented | `crates/oag-graph/src/semantic_search.rs:94-111` |
| B-052b | Implemented | `crates/oag-storage/src/repo/node_embeddings.rs:69-80` |
| B-052c | Comparison | Lexical exclusion in `crates/oag-storage/src/repo/nodes.rs:166-171` |

Verification: source inspection only. Semantic-search tests were not executed.

## Next investigation

Trace embedding text construction and storage lifecycle to determine when embeddings are created, updated, or left stale after node changes.