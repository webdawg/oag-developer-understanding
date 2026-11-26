# 0177 — Embedding recompute clears the table before generating replacements

Claim `B-0177`: at core `fb54e431332a030a566099c76fb2558084765422`,
`recompute_embeddings` deletes every row in `node_embeddings`, then embeds and
upserts nodes one by one. There is no transaction spanning the clear and the
reinserts, so a provider failure after the clear leaves a partially populated
table. It is an operator-triggered rebuild, not an incremental write path.

## Order of behavior

1. The method acquires one SQLite connection, reads all nodes with
   `nodes_repo::list_all`, then calls `node_embeddings_repo::clear_all`, which
   executes `DELETE FROM node_embeddings`.
2. For each node it builds `canonical_identifier + name + description` text.
   A defensively empty string increments `nodes_skipped` without calling the
   provider.
3. It calls `provider.embed(&text).await?`. A provider error returns immediately
   from the whole method. On success it upserts the vector, provider name, model
   name, dimension, and current timestamp for that node, then increments
   `nodes_embedded`.
4. `EmbeddingSummary` is returned only if every iteration reaches the end.
   There is no retry or rollback for rows already processed.
5. Semantic search reads whatever rows are present. It does not recompute
   missing vectors, so partial output remains semantically searchable for the
   nodes that were written.

## What is durable, rejected, and left behind

Durable: each `upsert` is committed independently in the shown code. A failure
after `clear_all` leaves previously stored embeddings deleted and only the
successful prefix written; the source does not test this crash/error window.
A successful recompute avoids mixing vectors from different providers or
models because the old table was cleared first.

Rejected: an empty embeddable text is skipped; a provider error aborts the run.
Ordinary graph writes do not update embeddings, so the table can become stale
between operator recomputes. No provider, database migration, or target test
was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0177a | Implemented recompute loop | `crates/oag-graph/src/semantic_search.rs:48-86` |
| B-0177b | Implemented clear and upsert storage | `crates/oag-storage/src/repo/node_embeddings.rs:27-55` |
| B-0177c | Implemented read-side consumer | `crates/oag-graph/src/semantic_search.rs:94-117` |
| B-0177d | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-graph/src/semantic_search.rs crates/oag-storage/src/repo/node_embeddings.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No embedding provider or target test was executed.

## Change since the previously explained commit

The recompute/storage code is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0054 records the same
batch posture for authority scores; finding 0174 records the semantic search
response. This finding adds the partial-state consequence of the embedding
rebuild.

## Next investigation

Trace `oag_graph::resolve::GraphService::list_assertions_for_node` and
`edges::list_touching` at the newer commit to document ordering and what a
multi-edge neighborhood returns.
