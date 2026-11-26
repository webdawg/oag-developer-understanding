# 0175 — Embedding rank is brute-force cosine with stable ties

Claim `B-0175`: at core `fb54e431332a030a566099c76fb2558084765422`, semantic
ranking is a pure in-memory `f32` cosine scan. Equal scores keep the order in
which `node_embeddings.list_all` returned them, which has no explicit SQL
`ORDER BY`. There is no ANN index, no dimension check in the rank function
beyond cosine's mismatch guard, and no NaN/Infinity filtering.

## Order of behavior

1. `node_embeddings::upsert` stores one vector per node as little-endian `f32`
   bytes with provider, model, dimension, and computation time. `list_all`
   selects every row with `SELECT * FROM node_embeddings` and decodes each
   byte slice with `as_chunks::<4>()`; a non-multiple-of-four remainder would be
   ignored.
2. `cosine_similarity(a, b)` returns `0.0` when lengths differ or either vector
   is empty. It computes the dot product and both L2 norms, returns `0.0` if a
   norm is zero, and otherwise returns `dot / (norm_a * norm_b)`.
3. `rank(query, candidates, limit)` scores every candidate, sorts descending
   with `f32::total_cmp`, and truncates. The sort is stable, so equal scores
   preserve the candidate order supplied by `list_all`.
4. `semantic_search` then loads each ranked Node by ID and drops IDs that no
   longer resolve. The service cap of 1000 is applied before ranking output is
   built, not inside `rank`.
5. Tests inspected cover identical, orthogonal, opposite, mismatched-length,
   zero-vector, and truncation cases. They were not executed.

## What is durable, rejected, and left behind

Durable: embeddings in `node_embeddings`, replaced wholesale by
`recompute_embeddings`; ranking itself stores nothing. Mismatched dimensions
and zero vectors yield similarity `0.0` rather than errors. No explicit guard
converts NaN or infinite inputs to zero, so a malformed stored vector is not
filtered by this function. Ties are deterministic only relative to an
unordered SQL result, not by Node ID.

Because `list_all` has no suppression predicate, ranking includes suppressed
nodes; suppression is a keyword-search concern in this implementation (finding
0052). No embedding call, query, or target test was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0175a | Implemented cosine and rank | `crates/oag-embeddings/src/similarity.rs:1-30` |
| B-0175b | Implemented embedding storage | `crates/oag-storage/src/repo/node_embeddings.rs:1-81` |
| B-0175c | Implemented caller | `crates/oag-graph/src/semantic_search.rs:94-117` |
| B-0175d | Test inspection, not executed | `crates/oag-embeddings/src/similarity.rs:32-83` |
| B-0175e | Unchanged since explained commit | `git diff 87f9e8c1..fb54e431 -- crates/oag-embeddings/src/similarity.rs crates/oag-storage/src/repo/node_embeddings.rs` (no output) |

Verification: source and test inspection via `git show origin/main:<path>` and a
scoped diff. No target test was executed.

## Change since the previously explained commit

The embedding rank and storage code is unchanged between
`87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe` and
`fb54e431332a030a566099c76fb2558084765422`. Finding 0052's suppression caveat
and finding 0174's response contract still hold at the newer commit; this
finding explains the scoring primitive beneath them.

## Next investigation

Re-fetch on the next invocation, then trace `oag_graph::authority::recompute_authority`
to document the batch ranking inputs, stored output, and what a rebuild does
with it.
