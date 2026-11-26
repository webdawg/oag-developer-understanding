# 0174 — Semantic search is unpaged and has a separate response contract

Claim `B-0174`: at core `fb54e431332a030a566099c76fb2558084765422`, setting
`semantic=true` on REST or MCP bypasses `search_page` entirely. The response is
`{"results": [...]}` with no `next_cursor`; `offset` and `cursor` are ignored.
Ranking is a brute-force cosine scan of stored embeddings, not the keyword FTS
path.

## Order of behavior

1. REST and MCP both branch on `semantic.unwrap_or(false)`. The keyword branch
   calls `search_page` and returns `results` plus `next_cursor`; the semantic
   branch calls `semantic_search(provider, query, limit.unwrap_or(20))` and
   returns only `results`.
2. `semantic_search` starts its timer, embeds the query with the supplied
   provider, opens a connection, and loads every row from `node_embeddings`.
   There is no cursor, offset, SQL `LIMIT`, or suppression filter in this path.
3. `oag_embeddings::rank` computes cosine similarity against those stored
   vectors and keeps at most `limit.clamp(0, 1000)` results. The service then
   loads each ranked node by ID and drops IDs that no longer resolve.
4. The latency observation includes the provider call and the ranking loop; it
   is recorded only after all lookups succeed. A disabled provider returns
   `GraphError::Embedding(Disabled)`, which REST maps to HTTP 400; provider
   errors map to 502.
5. Embeddings are generated only by a separate `recompute_embeddings` call,
   which clears and rebuilds `node_embeddings` from name/description/identifier.
   Semantic search does not embed nodes on the fly.

## What is durable, rejected, and left behind

Durable: the stored embeddings and their provider/model names; semantic search
itself stores nothing. Rejected: a missing provider configuration yields a
typed disabled error; other provider failures are HTTP 502. A limit above 1000
is clamped, and a negative limit becomes zero. A stale embedding row whose node
no longer exists is silently skipped.

Because this path lists all stored embeddings, it still does not apply the
keyword search suppression table (finding 0052 described the same gap at the
earlier commit; this source confirms it at the new one). Cursor/offset
parameters remain accepted syntactically but have no semantic-branch meaning,
so a client cannot page a semantic result set. No embedding provider or search
request was executed.

## Evidence

| ID | Basis | Location |
| --- | --- | --- |
| B-0174a | Implemented REST and MCP branches | `crates/oag-api/src/handlers.rs:15-33`; `crates/oag-mcp/src/server.rs:135-165` |
| B-0174b | Implemented semantic path | `crates/oag-graph/src/semantic_search.rs:22-28`, `48-117` |
| B-0174c | Implemented error mapping | `crates/oag-api/src/error.rs:29-35` |
| B-0174d | Implemented embedding rebuild | `crates/oag-graph/src/semantic_search.rs:49-86` |
| B-0174e | Compared response-shape change | `git diff 87f9e8c1..fb54e431 -- crates/oag-api/src/handlers.rs crates/oag-mcp/src/server.rs` |

Verification: source inspection via `git show origin/main:<path>` and a scoped
diff. No provider, embedding, or target test was executed.

## Change since the previously explained commit

At `87f9e8c1...`, REST and MCP returned direct arrays from both search modes.
At `fb54e431...`, keyword search returns `{results, next_cursor}` while
semantic search still returns the wrapped ranked array with no cursor; finding
0173 documents the keyword side. Finding 0052's suppression caveat still holds
at the newer commit.

## Next investigation

Trace `oag_embeddings::rank` and `oag_embeddings::similarity` to document the
exact cosine formula, invalid-vector handling, and result ordering.
